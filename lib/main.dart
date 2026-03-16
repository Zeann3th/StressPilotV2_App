import 'package:flutter/material.dart';
import 'package:stress_pilot/core/app_root.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/system/process_manager.dart';
import 'package:stress_pilot/core/system/shutdown_handler.dart';
import 'package:window_manager/window_manager.dart';
import 'package:local_notifier/local_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await localNotifier.setup(appName: 'Stress Pilot', shortcutPolicy: ShortcutPolicy.requireCreate);

  const windowOptions = WindowOptions(
    minimumSize: Size(1280, 720),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setResizable(true);
    await windowManager.maximize();
    await windowManager.show();
    await windowManager.focus();
  });

  setupDependencies();

  // Setup shutdown handler
  final shutdownHandler = ShutdownHandler(getIt<ProcessManager>());
  shutdownHandler.setup();

  runApp(const AppRoot());
}
