import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:stress_pilot/core/system/logger.dart';

class CoreProcessManager {
  static const _logName = 'CoreProcess';
  Process? _process;

  Future<void> initialize() async {
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

      _process!.stdout
          .transform(SystemEncoding().decoder)
          .listen((data) => AppLogger.info(
        data.trim(),
        name: '$_logName.stdout',
      ));

      _process!.stderr
          .transform(SystemEncoding().decoder)
          .listen((data) => AppLogger.error(
        data.trim(),
        name: '$_logName.stderr',
      ));

      AppLogger.info(
        'Backend started successfully (pid=${_process!.pid})',
        name: _logName,
      );
    } catch (e, st) {
      AppLogger.critical(
        'Failed to start backend process',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<void> stop() async {
    if (_process != null) {
      try {
        AppLogger.info('Stopping backend (pid=${_process!.pid})', name: _logName);
        _process!.kill();
        AppLogger.info('Backend stopped', name: _logName);
      } catch (e, st) {
        AppLogger.error(
          'Error stopping backend',
          name: _logName,
          error: e,
          stackTrace: st,
        );
      } finally {
        _process = null;
      }
    } else {
      AppLogger.debug('No backend process running', name: _logName);
    }
  }
}