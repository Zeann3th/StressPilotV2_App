import 'package:flutter/material.dart';
import 'package:stress_pilot/core/app_root.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const splashWindow = WindowOptions(
    size: Size(720, 480),
    minimumSize: Size(720, 480),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  await windowManager.waitUntilReadyToShow(splashWindow, () async {
    await windowManager.setResizable(false);
    await windowManager.show();
    await windowManager.focus();
  });

  setupDependencies();
  runApp(const AppRoot());
}
