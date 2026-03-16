import 'dart:io';
import 'package:window_manager/window_manager.dart';
import 'package:stress_pilot/core/system/logger.dart';
import 'package:stress_pilot/core/system/process_manager.dart';

class ShutdownHandler with WindowListener {
  static const _logName = 'ShutdownHandler';
  final ProcessManager _processManager;

  ShutdownHandler(this._processManager);

  void setup() {
    windowManager.addListener(this);
    windowManager.setPreventClose(true);
    _setupSignalHandlers();
  }

  void _setupSignalHandlers() {
    ProcessSignal.sigint.watch().listen((_) => _handleSignal('SIGINT'));

    if (!Platform.isWindows) {
      ProcessSignal.sigterm.watch().listen((_) => _handleSignal('SIGTERM'));
    }
  }

  Future<void> _handleSignal(String signal) async {
    AppLogger.info('Received $signal', name: _logName);
    await _processManager.forceKill();
    exit(0);
  }

  @override
  Future<void> onWindowClose() async {
    AppLogger.info('Window close requested', name: _logName);
    await _processManager.forceKill();
    await windowManager.destroy();
    exit(0);
  }
}
