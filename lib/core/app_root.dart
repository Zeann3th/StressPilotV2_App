import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/themes/theme_manager.dart';
import 'package:stress_pilot/core/system/logger.dart';
import 'package:stress_pilot/core/system/process_manager.dart';
import 'package:stress_pilot/core/system/session_manager.dart';
import 'package:stress_pilot/features/marketplace/domain/repositories/plugin_capability_repository.dart';

import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/settings/presentation/provider/setting_provider.dart';
import 'package:stress_pilot/core/input/keymap_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/core/input/global_shortcut_listener.dart';
import 'package:stress_pilot/features/endpoints/presentation/provider/endpoint_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/canvas_provider.dart';
import 'package:stress_pilot/features/environments/presentation/provider/environment_provider.dart';
import 'package:stress_pilot/features/results/presentation/provider/results_provider.dart';
import 'package:stress_pilot/features/shared/presentation/provider/run_provider.dart';
import 'package:stress_pilot/features/shared/presentation/widgets/layout.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _initialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      AppLogger.info('Starting application initialization', name: 'AppRoot');

      try {
        await getIt<ProcessManager>().startBackend(attachLogs: kDebugMode);
      } catch (e) {
        AppLogger.error('Backend startup failed/timed out, continuing in offline mode', name: 'AppRoot', error: e);
      }

      try {
        await getIt<SessionManager>().initializeSession();
      } catch (e) {
        AppLogger.error('Session initialization failed, continuing in offline mode', name: 'AppRoot', error: e);
      }

      await getIt<ThemeManager>().initialize();
      await getIt<ProjectProvider>().initialize();
      await getIt<KeymapProvider>().initialize();
      await getIt<PluginCapabilityRepository>().initialize();

      if (mounted) {
        setState(() {
          _initialized = true;
          _hasError = false;
        });
      }

      AppLogger.info('Application initialized (Offline Mode compatible)', name: 'AppRoot');
    } catch (e, st) {

      AppLogger.critical(
        'Critical application initialization failed',
        name: 'AppRoot',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProjectProvider>.value(
          value: getIt<ProjectProvider>(),
        ),
        ChangeNotifierProvider<SettingProvider>.value(
          value: getIt<SettingProvider>(),
        ),
        ChangeNotifierProvider<KeymapProvider>.value(
          value: getIt<KeymapProvider>(),
        ),
        ChangeNotifierProvider<FlowProvider>.value(
          value: getIt<FlowProvider>(),
        ),
        ChangeNotifierProvider<EndpointProvider>.value(
          value: getIt<EndpointProvider>(),
        ),
        ChangeNotifierProvider<CanvasProvider>.value(
          value: getIt<CanvasProvider>(),
        ),
        ChangeNotifierProvider<EnvironmentProvider>.value(
          value: getIt<EnvironmentProvider>(),
        ),
        ChangeNotifierProvider<ResultsProvider>(
          create: (_) => getIt<ResultsProvider>(),
        ),
        ChangeNotifierProvider<RunProvider>.value(
          value: getIt<RunProvider>(),
        ),
        ChangeNotifierProvider<ThemeManager>.value(
          value: getIt<ThemeManager>(),
        ),
      ],
      child: _initialized && !_hasError
          ? const GlobalShortcutListener(
              child: _AppTheme(),
            )
          : const _AppLoadingTheme(),
    );
  }

  @override
  void dispose() {
    getIt<ProcessManager>().forceKill().then((_) {});
    try {
      getIt<SessionManager>().dispose();
    } catch (_) {}
    super.dispose();
  }
}

class _AppLoadingTheme extends StatelessWidget {
  const _AppLoadingTheme();

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      title: 'Stress Pilot',
      debugShowCheckedModeBanner: false,
      home: const AppSkeleton(),
    );
  }
}

class _AppTheme extends StatelessWidget {
  const _AppTheme();

  @override
  Widget build(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();
    final isDark = themeManager.themeMode == ThemeMode.dark;

    final defaultShadTheme = isDark
        ? ShadThemeData(
            brightness: Brightness.dark,
            colorScheme: const ShadZincColorScheme.dark(),
          )
        : ShadThemeData(
            brightness: Brightness.light,
            colorScheme: const ShadZincColorScheme.light(),
          );

    return ShadApp(
      title: 'Stress Pilot',
      debugShowCheckedModeBanner: false,
      navigatorKey: AppNavigator.navigatorKey,
      themeMode: themeManager.themeMode,
      theme: themeManager.currentShadTheme ?? defaultShadTheme,
      darkTheme: themeManager.currentShadTheme ?? defaultShadTheme,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: AppRouter.projectsRoute,
      builder: (context, child) {
        return ScaffoldMessenger(
          key: AppNavigator.scaffoldMessengerKey,
          child: child!,
        );
      },
    );
  }
}
