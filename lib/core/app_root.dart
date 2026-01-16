import 'package:stress_pilot/features/browser_spy/presentation/manager/browser_spy_provider.dart';
import 'package:flutter/foundation.dart';
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
            scaffoldBackgroundColor: const Color(
              0xFFF2F2F7,
            ), // System Gray 6 (Light)
            colorScheme: const ColorScheme(
              brightness: Brightness.light,
              primary: Color(0xFF007AFF), // System Blue
              onPrimary: Colors.white,
              secondary: Color(0xFF5856D6), // System Indigo
              onSecondary: Colors.white,
              error: Color(0xFFFF3B30), // System Red
              onError: Colors.white,
              surface: Color(0xFFFFFFFF), // White Surface
              onSurface: Color(0xFF000000), // Black Text
              surfaceContainer: Color(0xFFFFFFFF), // High
              surfaceContainerLow: Color(0xFFF2F2F7), // Base
              outline: Color(0xFFE5E5EA), // System Gray 3 (Light)
              outlineVariant: Color(0xFFC7C7CC), // System Gray 4 (Light)
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF9F9F9), // Translucent-ish
              foregroundColor: Colors.black,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
              iconTheme: IconThemeData(color: Color(0xFF007AFF)),
            ),
            iconTheme: const IconThemeData(color: Color(0xFF007AFF)),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE5E5EA)),
              ),
            ),
            dividerTheme: const DividerThemeData(
              color: Color(0xFFE5E5EA),
              thickness: 1,
            ),
          ),

          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF000000), // Pure Black
            colorScheme: const ColorScheme(
              brightness: Brightness.dark,
              primary: Color(0xFF0A84FF), // System Blue Dark
              onPrimary: Colors.white,
              secondary: Color(0xFF5E5CE6), // System Indigo Dark
              onSecondary: Colors.white,
              error: Color(0xFFFF453A), // System Red Dark
              onError: Colors.white,
              surface: Color(0xFF1C1C1E), // System Gray 6 (Dark)
              onSurface: Colors.white,
              surfaceContainer: Color(0xFF2C2C2E), // System Gray 5 (Dark)
              surfaceContainerLow: Color(0xFF1C1C1E),
              outline: Color(0xFF38383A), // Dark Gray Border
              outlineVariant: Color(0xFF48484A),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1C1C1E),
              foregroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
              iconTheme: IconThemeData(color: Color(0xFF0A84FF)),
            ),
            iconTheme: const IconThemeData(color: Color(0xFF0A84FF)),
            cardTheme: CardThemeData(
              color: const Color(0xFF1C1C1E),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF38383A)),
              ),
            ),
            dividerTheme: const DividerThemeData(
              color: Color(0xFF38383A),
              thickness: 1,
            ),
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
        ChangeNotifierProvider<ThemeManager>.value(
          value: getIt<ThemeManager>(),
        ),
        ChangeNotifierProvider<BrowserSpyProvider>.value(
          value: getIt<BrowserSpyProvider>(),
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

      await getIt<ProcessManager>().startBackend(attachLogs: kDebugMode);

      // ProcessManager handles health checks
      AppLogger.info('Backend initialization complete.', name: 'AppRoot');

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
    getIt<ProcessManager>().stopBackend();
    try {
      getIt<SessionManager>().dispose();
    } catch (_) {}
    super.dispose();
  }
}
