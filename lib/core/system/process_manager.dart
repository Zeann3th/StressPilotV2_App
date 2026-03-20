import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:stress_pilot/core/config/app_config.dart';
import 'package:stress_pilot/core/system/logger.dart';

class ProcessManager {
  static const _logName = 'ProcessManager';
  Process? _process;
  StreamSubscription<String>? _stdoutSub;
  StreamSubscription<String>? _stderrSub;
  final Dio _dio;

  ProcessManager()
      : _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  String _getExecutableDir() {
    return kDebugMode
        ? Directory.current.path
        : File(Platform.resolvedExecutable).parent.path;
  }

  String _getJavaExecutable() {
    if (kDebugMode) return 'java';

    final executableDir = _getExecutableDir();

    if (Platform.isWindows) {
      return path.join(executableDir, 'jdk', 'bin', 'java.exe');
    } else {
      // macOS and Linux
      return path.join(executableDir, 'jdk', 'bin', 'java');
    }
  }

  String _getJarPath() {
    if (kDebugMode) {
      return path.join(Directory.current.path, 'assets', 'core', 'app.jar');
    } else {
      final String executableDir = File(
        Platform.resolvedExecutable,
      ).parent.path;
      return path.join(
        executableDir,
        'data',
        'flutter_assets',
        'assets',
        'core',
        'app.jar',
      );
    }
  }

  Future<void> startBackend({bool attachLogs = true}) async {
    if (_process != null) {
      AppLogger.warning('Backend already running', name: _logName);
      return;
    }

    final jarPath = _getJarPath();
    final javaPath = _getJavaExecutable();
    final workingDir = _getExecutableDir();

    AppLogger.info('Java executable: $javaPath', name: _logName);
    AppLogger.info('Starting backend JAR at: $jarPath', name: _logName);
    AppLogger.info('Working directory: $workingDir', name: _logName);

    if (!await File(jarPath).exists()) {
      AppLogger.critical('JAR file not found at $jarPath', name: _logName);
      return;
    }

    if (!kDebugMode && !await File(javaPath).exists()) {
      AppLogger.critical(
        'Bundled JDK not found at $javaPath. Package may be corrupted.',
        name: _logName,
      );
      return;
    }

    try {
      final profile = kDebugMode ? 'dev' : 'prod';

      _process = await Process.start(
        javaPath,
        ['-jar', jarPath, '--spring.profiles.active=$profile'],
        workingDirectory: workingDir,
        mode: ProcessStartMode.normal,
      );

      if (attachLogs) {
        _stdoutSub = _process!.stdout
            .transform(SystemEncoding().decoder)
            .listen(
              (data) => AppLogger.info(data.trim(), name: '$_logName.stdout'),
        );

        _stderrSub = _process!.stderr
            .transform(SystemEncoding().decoder)
            .listen(
              (data) =>
              AppLogger.error(data.trim(), name: '$_logName.stderr'),
        );
      } else {
        _process!.stdout.drain();
        _process!.stderr.drain();
      }

      AppLogger.info(
        'Backend process started (pid=${_process!.pid}). Waiting for health...',
        name: _logName,
      );

      await _waitForHealth();
    } catch (e, st) {
      AppLogger.critical(
        'Failed to start backend process. Bundled JDK path: $javaPath',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      _process = null;
      rethrow;
    }
  }

  Future<void> _waitForHealth() async {
    const int maxAttempts = 20;
    Duration currentInterval = const Duration(seconds: 1);
    final Duration maxInterval = const Duration(seconds: 10);

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final sessionResponse = await _dio.get('/api/v1/utilities/session');
        if (sessionResponse.statusCode == 200) {
          AppLogger.info('Backend session ready.', name: _logName);
          return;
        }

        final healthResponse = await _dio.get('/actuator/health');
        if (healthResponse.statusCode == 200 &&
            healthResponse.data['status'] == 'UP') {
          AppLogger.info('Backend actuator UP.', name: _logName);
          return;
        }
      } catch (_) {
        // Ignore errors during healthcheck
      }

      if (attempt < maxAttempts) {
        AppLogger.debug(
          'Backend not ready yet, waiting ${currentInterval.inSeconds}s...',
          name: _logName,
        );
        await Future.delayed(currentInterval);
        // Exponential backoff
        currentInterval = currentInterval * 1.5;
        if (currentInterval > maxInterval) {
          currentInterval = maxInterval;
        }
      }
    }

    AppLogger.error(
      'Backend failed to become healthy after $maxAttempts attempts',
      name: _logName,
    );
  }

  Future<void> forceKill() async {
    AppLogger.info('Attempting to force kill backend...', name: _logName);

    if (_process != null) {
      final int pid = _process!.pid;
      AppLogger.info('Attempting to kill backend pid=$pid', name: _logName);

      try {
        await _stdoutSub?.cancel();
      } catch (_) {}
      try {
        await _stderrSub?.cancel();
      } catch (_) {}
      _stdoutSub = null;
      _stderrSub = null;

      try {
        _process!.kill();
      } catch (e) {
        AppLogger.warning('Failed to kill _process: $e', name: _logName);
      } finally {
        _process = null;
      }
    }

    try {
      if (Platform.isWindows) {
        final result = await Process.run(
          'cmd',
          ['/c', 'netstat -ano | findstr :52000'],
        );
        final lines = result.stdout.toString().split('\n');
        for (var line in lines) {
          if (line.contains('LISTENING')) {
            final parts = line.trim().split(RegExp(r'\s+'));
            if (parts.isNotEmpty) {
              final pid = parts.last;
              await Process.run('taskkill', ['/F', '/PID', pid, '/T']);
              AppLogger.info(
                'taskkill invoked for port 52000 pid $pid',
                name: _logName,
              );
            }
          }
        }
      } else {
        final result = await Process.run(
          'sh',
          ['-c', 'lsof -t -i:52000'],
        );
        final pids = result.stdout.toString().trim().split('\n');
        for (var pid in pids) {
          if (pid.isNotEmpty) {
            await Process.run('kill', ['-9', pid]);
            AppLogger.info(
              'kill -9 invoked for port 52000 pid $pid',
              name: _logName,
            );
          }
        }
      }
    } catch (e) {
      AppLogger.warning('Failed to kill backend by port: $e', name: _logName);
    }
  }
}