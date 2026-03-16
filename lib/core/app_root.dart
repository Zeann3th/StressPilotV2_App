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
import 'package:stress_pilot/features/marketplace/data/plugin_capability_service.dart';

import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/settings/presentation/provider/setting_provider.dart';
import 'package:stress_pilot/core/input/keymap_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/core/input/global_shortcut_listener.dart';
import 'package:stress_pilot/features/common/presentation/provider/endpoint_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/canvas_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/environment_provider.dart';
import 'package:stress_pilot/features/results/presentation/provider/results_provider.dart';
import 'package:stress_pilot/features/common/presentation/layout.dart';

class AppProviders extends StatelessWidget {
  const AppProviders({super.key});

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
        ChangeNotifierProvider<ThemeManager>.value(
          value: getIt<ThemeManager>(),
        ),
      ],
      child: const GlobalShortcutListener(
        child: _AppTheme(),
      ),
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
    );
  }
}

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

      await getIt<ProcessManager>().startBackend(attachLogs: kDebugMode);

      AppLogger.info('Backend initialization complete.', name: 'AppRoot');

      await getIt<SessionManager>().initializeSession();
      await getIt<ThemeManager>().initialize();
      await getIt<ProjectProvider>().initialize();
      await getIt<KeymapProvider>().initialize();
      await getIt<PluginCapabilityService>().initialize();

      setState(() {
        _initialized = true;
      });

      AppLogger.info('Application initialized successfully', name: 'AppRoot');
    } catch (e, st) {
      _hasError = true;
      AppLogger.critical(
        'Application initialization failed',
        name: 'AppRoot',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initialized && !_hasError) {
      return const AppProviders();
    }

    return ShadApp(
      title: 'Stress Pilot',
      debugShowCheckedModeBanner: false,
      home: const AppSkeleton(),
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
