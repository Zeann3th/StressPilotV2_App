import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stress_pilot/core/system/logger.dart';
import 'package:stress_pilot/core/system/process_manager.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';

class ShutdownHandler with WindowListener, TrayListener {
  static const _logName = 'ShutdownHandler';
  final ProcessManager _processManager;
  bool _trayInitialized = false;

  ShutdownHandler(this._processManager);

  void setup() {
    windowManager.addListener(this);
    windowManager.setPreventClose(true);
    _setupSignalHandlers();
  }

  void _setupSignalHandlers() {
    ProcessSignal.sigint.watch().listen((_) async => await _handleSignal('SIGINT'));

    if (!Platform.isWindows) {
      ProcessSignal.sigterm.watch().listen((_) async => await _handleSignal('SIGTERM'));
    }
  }

  Future<void> _handleSignal(String signal) async {
    AppLogger.info('Received $signal, cleaning up...', name: _logName);
    await _processManager.forceKill();
    exit(0);
  }

  @override
  Future<void> onWindowClose() async {
    AppLogger.info('Window close requested', name: _logName);

    final context = AppNavigator.navigatorKey.currentContext;
    if (context == null) {
      await _exitEntirely();
      return;
    }

    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Exit Stress Pilot'),
        description: const Text('Would you like to minimize to the system tray or exit?'),
        actions: [
          ShadButton.outline(
            child: const Text('System Tray'),
            onPressed: () {
              Navigator.of(context).pop();
              _minimizeToTray();
            },
          ),
          ShadButton.destructive(
            child: const Text('Exit'),
            onPressed: () {
              Navigator.of(context).pop();
              _exitEntirely();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _minimizeToTray() async {
    if (!_trayInitialized) {
      await _initTray();
    }
    await windowManager.hide();
  }

  Future<void> _initTray() async {
    try {
      await trayManager.setIcon(
        Platform.isWindows ? 'assets/images/logo.png' : 'assets/images/logo.png',
      );
      final Menu menu = Menu(
        items: [
          MenuItem(
            key: 'open_window',
            label: 'Open Stress Pilot',
          ),
          MenuItem.separator(),
          MenuItem(
            key: 'exit',
            label: 'Exit',
          ),
        ],
      );
      await trayManager.setContextMenu(menu);
      trayManager.addListener(this);
      _trayInitialized = true;
    } catch (e) {
      AppLogger.error('Failed to initialize tray: $e', name: _logName);
    }
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
    windowManager.focus();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'open_window') {
      windowManager.show();
      windowManager.focus();
    } else if (menuItem.key == 'exit') {
      _exitEntirely();
    }
  }

  Future<void> _exitEntirely() async {
    AppLogger.info('Exiting and cleaning up processes...', name: _logName);
    try {
      await _processManager.forceKill().timeout(const Duration(seconds: 5));
    } catch (e) {
      AppLogger.error('Forced cleanup timed out: $e', name: _logName);
    }
    exit(0);
  }
}
