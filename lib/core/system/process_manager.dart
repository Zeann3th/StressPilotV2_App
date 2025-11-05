import 'dart:io';
import 'dart:developer' as developer;
import 'package:path/path.dart' as path;

class CoreProcessManager {
  Process? _process;

  Future<void> initialize() async {
    if (_process != null) {
      developer.log('Backend already running', name: 'CoreProcess');
      return;
    }

    final jarPath = path.join(
      Directory.current.path,
      'assets',
      'core',
      'app.jar',
    );

    developer.log('Starting backend JAR...', name: 'CoreProcess', error: jarPath);

    try {
      _process = await Process.start(
        'java',
        ['-jar', jarPath],
        workingDirectory: Directory.current.path,
        mode: ProcessStartMode.normal,
      );

      _process!.stdout
          .transform(SystemEncoding().decoder)
          .listen((data) => developer.log(
        data.trim(),
        name: 'CoreProcess.stdout',
      ));

      _process!.stderr
          .transform(SystemEncoding().decoder)
          .listen((data) => developer.log(
        data.trim(),
        name: 'CoreProcess.stderr',
        level: 900,
      ));

      developer.log(
        'Backend started successfully (pid=${_process!.pid})',
        name: 'CoreProcess',
      );
    } catch (e, st) {
      developer.log(
        'Failed to start backend process',
        name: 'CoreProcess',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> stop() async {
    if (_process != null) {
      try {
        developer.log('Stopping backend (pid=${_process!.pid})', name: 'CoreProcess');
        _process!.kill();
        developer.log('Backend stopped', name: 'CoreProcess');
      } catch (e, st) {
        developer.log('Error stopping backend', name: 'CoreProcess', error: e, stackTrace: st);
      } finally {
        _process = null;
      }
    } else {
      developer.log('No backend process running', name: 'CoreProcess');
    }
  }
}