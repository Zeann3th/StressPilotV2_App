import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:stress_pilot/core/config/app_config.dart';
import 'package:stress_pilot/core/system/logger.dart';

class ProcessManager {
  static const _logName = 'ProcessManager';
  Process? _process;
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
        _process!.stdout
            .transform(SystemEncoding().decoder)
            .listen(
              (data) => AppLogger.info(data.trim(), name: '$_logName.stdout'),
            );

        _process!.stderr
            .transform(SystemEncoding().decoder)
            .listen(
              (data) => AppLogger.error(data.trim(), name: '$_logName.stderr'),
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

  Future<void> stopBackend() async {
    if (_process == null) {
      AppLogger.debug('No backend process running to stop', name: _logName);
      return;
    }

    AppLogger.info('Stopping backend...', name: _logName);

    try {
      AppLogger.info(
        'Attempting graceful shutdown via /actuator/shutdown',
        name: _logName,
      );
      await _dio.post('/actuator/shutdown');
      await Future.delayed(const Duration(milliseconds: 2000));
    } catch (e) {
      AppLogger.warning(
        'Graceful shutdown failed, forcing kill.',
        name: _logName,
      );
    }

    try {
      _process!.kill();
      AppLogger.info('Backend process killed', name: _logName);
    } catch (e) {
      // Ignored
    } finally {
      _process = null;
    }
  }

  Future<void> performColdSwap(Future<void> Function() fileAction) async {
    AppLogger.info('Initiating Cold Swap...', name: _logName);
    await stopBackend();
    try {
      await fileAction();
    } catch (e, st) {
      AppLogger.critical(
        'Swap action failed.',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
    await startBackend();
  }
}
