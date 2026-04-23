import 'package:flutter/material.dart';
import 'package:stress_pilot/core/app_root.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/system/process_manager.dart';
import 'package:stress_pilot/core/system/shutdown_handler.dart';
import 'package:stress_pilot/core/system/app_error_boundary.dart';
import 'package:stress_pilot/core/window/window_manager.dart';
import 'package:window_manager/window_manager.dart' as wm;
import 'package:local_notifier/local_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!WindowSetup.isSupported) {
    await wm.windowManager.ensureInitialized();
    const windowOptions = wm.WindowOptions(
      minimumSize: Size(1280, 720),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: wm.TitleBarStyle.normal,
    );

    await wm.windowManager.waitUntilReadyToShow(windowOptions, () async {
      await wm.windowManager.setResizable(true);
      await wm.windowManager.maximize();
      await wm.windowManager.show();
      await wm.windowManager.focus();
    });
  } else {
    WindowSetup.initialize();
  }

  await localNotifier.setup(appName: 'Stress Pilot', shortcutPolicy: ShortcutPolicy.requireCreate);

  setupDependencies();

  final shutdownHandler = ShutdownHandler(getIt<ProcessManager>());
  shutdownHandler.setup();

  runApp(
    const AppErrorBoundary(child: AppRoot()),
  );
}
