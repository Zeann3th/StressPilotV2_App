import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stress_pilot/core/app_root.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/system/process_manager.dart';
import 'package:stress_pilot/core/system/shutdown_handler.dart';
import 'package:stress_pilot/core/utils/app_error_boundary.dart';
import 'package:stress_pilot/core/system/logger.dart';
import 'package:window_manager/window_manager.dart';
import 'package:local_notifier/local_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await localNotifier.setup(appName: 'Stress Pilot', shortcutPolicy: ShortcutPolicy.requireCreate);

  FlutterError.onError = (details) {
    AppLogger.critical(
      'Flutter error: ${details.exceptionAsString()}',
      name: 'FlutterError',
      stackTrace: details.stack,
    );
    AppErrorBoundary.saveCrashLog(details.exception, details.stack);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.critical(
      'Platform error: $error',
      name: 'PlatformDispatcher',
      stackTrace: stack,
    );
    AppErrorBoundary.saveCrashLog(error, stack);
    return true;
  };

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

  final shutdownHandler = ShutdownHandler(getIt<ProcessManager>());
  shutdownHandler.setup();

  runApp(
    const AppErrorBoundary(child: AppRoot()),
  );
}
