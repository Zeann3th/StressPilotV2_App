import 'dart:io';
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

  Future<void> startBackend({bool attachLogs = true}) async {
    if (_process != null) {
      AppLogger.warning('Backend already running', name: _logName);
      return;
    }

    final jarPath = path.join(
      Directory.current.path,
      'assets',
      'core',
      'app.jar',
    );

    AppLogger.info('Starting backend JAR at: $jarPath', name: _logName);

    try {
      _process = await Process.start(
        'java',
        ['-jar', jarPath],
        workingDirectory: Directory.current.path,
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

      // Verify health
      await _waitForHealth();
    } catch (e, st) {
      AppLogger.critical(
        'Failed to start backend process',
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
    // We don't kill it automatically, letting the user see logs, but we warn.
  }

  /// Stops the backend gracefully via Actuator, falls back to Process.kill.
  Future<void> stopBackend() async {
    if (_process == null) {
      AppLogger.debug('No backend process running to stop', name: _logName);
      return;
    }

    AppLogger.info('Stopping backend...', name: _logName);

    // 1. Try Graceful Shutdown via Actuator
    try {
      AppLogger.info(
        'Attempting graceful shutdown via /actuator/shutdown',
        name: _logName,
      );
      await _dio.post('/actuator/shutdown');

      // Wait a bit for the process to exit naturally
      int waitMs = 0;
      while (waitMs < 5000) {
        // Check if process is still valid (OS dependent, strictly speaking we rely on the object state or exit code)
        // Dart's Process object doesn't have an 'isAlive' property easily, but we can wait on exitCode future if we stored it.
        // For simplicity, we just wait a fixed time.
        await Future.delayed(const Duration(milliseconds: 500));
        waitMs += 500;
      }
    } catch (e) {
      AppLogger.warning(
        'Graceful shutdown failed/timed out, forcing kill. Error: $e',
        name: _logName,
      );
    }

    // 2. Force Kill if still running (or just to be sure)
    // Dart Process object doesn't strictly know if it exited unless we listened to exitCode.
    // Calling kill on a dead process usually ignores or returns false.
    try {
      _process!.kill();
      AppLogger.info(
        'Backend process killed (fallback/cleanup)',
        name: _logName,
      );
    } catch (e) {
      // Ignored
    } finally {
      _process = null;
    }
  }

  /// Performs a "Cold Swap" of the backend logic.
  ///
  /// 1. Stops the backend.
  /// 2. Executes [fileAction] (e.g., replace .jar).
  /// 3. Restarts the backend.
  Future<void> performColdSwap(Future<void> Function() fileAction) async {
    AppLogger.info('Initiating Cold Swap...', name: _logName);

    // Stop
    await stopBackend();

    // Perform Action
    try {
      AppLogger.info('Executing swap action...', name: _logName);
      await fileAction();
    } catch (e, st) {
      AppLogger.critical(
        'Swap action failed during Cold Swap. Backend is STOPPED.',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }

    // Restart
    AppLogger.info(
      'Swap action complete. Restarting backend...',
      name: _logName,
    );
    await startBackend();

    AppLogger.info('Cold Swap completed successfully.', name: _logName);
  }
}
