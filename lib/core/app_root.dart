import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/themes/theme_manager.dart';
import 'package:stress_pilot/core/system/logger.dart';
import 'package:stress_pilot/core/system/process_manager.dart';
import 'package:stress_pilot/core/system/session_manager.dart';

import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/settings/presentation/provider/setting_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/features/common/presentation/provider/endpoint_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/canvas_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/environment_provider.dart';
import 'package:stress_pilot/features/results/presentation/provider/results_provider.dart';
import 'package:stress_pilot/features/splash/presentation/pages/splash_screen.dart';

class AppTheme extends StatelessWidget {
  const AppTheme({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = getIt<ThemeManager>();
    const seedColor = Color(0xFF2563EB);

    return AnimatedBuilder(
      animation: themeManager,
      builder: (context, _) {
        return MaterialApp(
          title: 'Stress Pilot',
          debugShowCheckedModeBanner: false,
          navigatorKey: AppNavigator.navigatorKey,

          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: seedColor,
              brightness: Brightness.light,
              surface: Colors.white,
              surfaceContainer: const Color(0xFFF8FAFC),
              surfaceContainerLow: const Color(0xFFF1F5F9),
              onSurface: const Color(0xFF0F172A),
              onSurfaceVariant: const Color(0xFF64748B),
              outline: const Color(0xFFE2E8F0),
              outlineVariant: const Color(0xFFCBD5E1),
            ),
            scaffoldBackgroundColor: Colors.white,
          ),

          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: seedColor,
              brightness: Brightness.dark,
              surface: const Color(0xFF0F172A),
              surfaceContainer: const Color(0xFF1E293B),
              surfaceContainerLow: const Color(0xFF1E293B),
              onSurface: const Color(0xFFF8FAFC),
              onSurfaceVariant: const Color(0xFF94A3B8),
              outline: const Color(0xFF334155),
              outlineVariant: const Color(0xFF475569),
            ),
            scaffoldBackgroundColor: const Color(0xFF0F172A),
          ),

          themeMode: themeManager.themeMode,
          onGenerateRoute: AppRouter.generateRoute,
          initialRoute: AppRouter.projectsRoute,
        );
      },
    );
  }
}

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
      ],
      child: const AppTheme(),
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

  Future<void> _expandWindow() async {
    await windowManager.setTitleBarStyle(TitleBarStyle.normal);

    await windowManager.setMinimumSize(const Size(1280, 720));
    await windowManager.setSize(const Size(1280, 720));

    await windowManager.center();

    await windowManager.setResizable(true);

    await Future.delayed(const Duration(milliseconds: 120));
  }

  Future<void> _init() async {
    try {
      AppLogger.info('Starting application initialization', name: 'AppRoot');

      await getIt<CoreProcessManager>().initialize();

      final isHealthy = await getIt<SessionManager>().waitForHealthCheck(
        maxAttempts: 24,
        interval: const Duration(seconds: 5),
      );

      if (!isHealthy) {
        _hasError = true;
        return;
      }

      await getIt<SessionManager>().initializeSession();
      await getIt<ProjectProvider>().initialize();

      await _expandWindow();

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),

        child: (_initialized && !_hasError)
            ? const AppProviders(key: ValueKey('app'))
            : const SplashScreen(key: ValueKey('splash')),
      ),
    );
  }

  @override
  void dispose() {
    getIt<CoreProcessManager>().stop();
    try {
      getIt<SessionManager>().dispose();
    } catch (_) {}
    super.dispose();
  }
}
