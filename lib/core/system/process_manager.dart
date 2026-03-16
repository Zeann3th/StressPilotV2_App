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
    final workingDir = kDebugMode
        ? Directory.current.path
        : File(Platform.resolvedExecutable).parent.path;

    AppLogger.info('Starting backend JAR at: $jarPath', name: _logName);
    AppLogger.info('Working directory: $workingDir', name: _logName);

    if (!await File(jarPath).exists()) {
      AppLogger.critical('JAR file not found at $jarPath', name: _logName);
      return;
    }

    try {
      _process = await Process.start(
        'java',
        ['-jar', jarPath],
        workingDirectory: workingDir,
        mode: ProcessStartMode.normal,
      );

      if (attachLogs) {
        _stdoutSub = _process!.stdout
            .transform(SystemEncoding().decoder)
            .listen((data) => AppLogger.info(data.trim(), name: '$_logName.stdout'));

        _stderrSub = _process!.stderr
            .transform(SystemEncoding().decoder)
            .listen((data) => AppLogger.error(data.trim(), name: '$_logName.stderr'));
      } else {
        // Drain streams to avoid backpressure but no logging subscription
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
        'Failed to start backend process. Is Java installed and in PATH?',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      _process = null;
      rethrow;
    }
  }

  Future<void> _waitForHealth() async {
    const int maxRetries = 30;
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        final response = await _dio.get('/actuator/health');
        if (response.statusCode == 200 && response.data['status'] == 'UP') {
          AppLogger.info('Backend is UP and healthy.', name: _logName);
          return;
        }
      } catch (_) {
        // Ignore connection errors while starting
      }

      await Future.delayed(const Duration(seconds: 1));
      attempts++;
    }

    AppLogger.error(
      'Backend failed to become healthy after $maxRetries seconds',
      name: _logName,
    );
  }

  Future<void> forceKill() async {
    if (_process == null) {
      AppLogger.debug('No backend process running to kill', name: _logName);
      return;
    }

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
      final bool sent = _process!.kill();
      AppLogger.debug('Sent kill signal: $sent', name: _logName);

      final exitFuture = _process!.exitCode;
      final exited = await exitFuture.timeout(const Duration(seconds: 2), onTimeout: () => -1);

      if (exited != -1) {
        AppLogger.info('Backend exited with code $exited', name: _logName);
      } else {
        if (Platform.isWindows) {
          try {
            await Process.run('taskkill', ['/PID', pid.toString(), '/F', '/T']);
            AppLogger.info('taskkill invoked for pid $pid', name: _logName);
          } catch (e) {
            AppLogger.warning('taskkill failed: $e', name: _logName);
          }
        } else {
          try {
            _process!.kill(ProcessSignal.sigkill);
            AppLogger.info('Sent SIGKILL to pid $pid', name: _logName);
          } catch (e) {
            AppLogger.warning('SIGKILL failed: $e', name: _logName);
          }
        }
      }
    } catch (e) {
      AppLogger.warning('Failed to kill backend: $e', name: _logName);
    } finally {
      _process = null;
    }
  }
}
