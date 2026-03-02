import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'package:stress_pilot/core/design/tokens.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/themes/theme_manager.dart';
import 'package:stress_pilot/core/system/logger.dart';
import 'package:stress_pilot/core/system/process_manager.dart';
import 'package:stress_pilot/core/system/session_manager.dart';

import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/settings/presentation/provider/setting_provider.dart';
import 'package:stress_pilot/core/input/keymap_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/core/input/global_shortcut_listener.dart';
import 'package:stress_pilot/features/common/presentation/provider/endpoint_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/canvas_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/environment_provider.dart';
import 'package:stress_pilot/features/results/presentation/provider/results_provider.dart';
import 'package:stress_pilot/features/splash/presentation/pages/splash_screen.dart';

TextTheme _buildTextTheme(Color primary, Color secondary) {
  const family = 'JetBrains Mono';
  return TextTheme(
    displayLarge: TextStyle(fontFamily: family, color: primary),
    displayMedium: TextStyle(fontFamily: family, color: primary),
    displaySmall: TextStyle(fontFamily: family, color: primary),
    headlineLarge: TextStyle(fontFamily: family, color: primary, fontWeight: FontWeight.w700),
    headlineMedium: TextStyle(fontFamily: family, color: primary, fontWeight: FontWeight.w600),
    headlineSmall: TextStyle(fontFamily: family, color: primary, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(fontFamily: family, color: primary, fontWeight: FontWeight.w600, fontSize: 20),
    titleMedium: TextStyle(fontFamily: family, color: primary, fontWeight: FontWeight.w600, fontSize: 16),
    titleSmall: TextStyle(fontFamily: family, color: primary, fontWeight: FontWeight.w500, fontSize: 14),
    bodyLarge: TextStyle(fontFamily: family, color: primary, fontSize: 14),
    bodyMedium: TextStyle(fontFamily: family, color: primary, fontSize: 13),
    bodySmall: TextStyle(fontFamily: family, color: secondary, fontSize: 12),
    labelLarge: TextStyle(fontFamily: family, color: primary, fontWeight: FontWeight.w600, fontSize: 13),
    labelMedium: TextStyle(fontFamily: family, color: secondary, fontWeight: FontWeight.w500, fontSize: 12),
    labelSmall: TextStyle(fontFamily: family, color: secondary, fontWeight: FontWeight.w500, fontSize: 11),
  );
}

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
            scaffoldBackgroundColor: AppColors.lightBackground,
            fontFamily: 'JetBrains Mono',
            textTheme: _buildTextTheme(AppColors.textLight, AppColors.textSecondary),
            colorScheme: ColorScheme(
              brightness: Brightness.light,
              primary: AppColors.accentLight,
              onPrimary: Colors.white,
              secondary: AppColors.accentLight,
              onSecondary: Colors.white,
              error: AppColors.error,
              onError: Colors.white,
              surface: AppColors.lightSurface,
              onSurface: AppColors.textLight,
              surfaceContainer: AppColors.lightElevated,
              surfaceContainerLow: AppColors.lightBackground,
              surfaceContainerHighest: AppColors.lightElevated,
              outline: AppColors.lightBorder,
              outlineVariant: AppColors.lightBorder,
              onSurfaceVariant: AppColors.textSecondary,
              primaryContainer: AppColors.accentLight.withValues(alpha: 0.12),
              onPrimaryContainer: AppColors.accentLight,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.lightSurface,
              foregroundColor: AppColors.textLight,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              iconTheme: IconThemeData(color: AppColors.textSecondary),
            ),
            iconTheme: const IconThemeData(color: AppColors.textSecondary),
            cardTheme: CardThemeData(
              color: AppColors.lightSurface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.lightBorder),
              ),
            ),
            dividerTheme: const DividerThemeData(
              color: AppColors.lightBorder,
              thickness: 1,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppColors.lightElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.lightBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.lightBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.accentLight, width: 1.5),
              ),
            ),
          ),

          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppColors.darkBackground,
            fontFamily: 'JetBrains Mono',
            textTheme: _buildTextTheme(AppColors.textPrimary, AppColors.textSecondary),
            colorScheme: ColorScheme(
              brightness: Brightness.dark,
              primary: AppColors.accent,
              onPrimary: Colors.white,
              secondary: AppColors.accent,
              onSecondary: Colors.white,
              error: AppColors.error,
              onError: Colors.white,
              surface: AppColors.darkSurface,
              onSurface: AppColors.textPrimary,
              surfaceContainer: AppColors.darkElevated,
              surfaceContainerLow: AppColors.darkBackground,
              surfaceContainerHighest: AppColors.darkElevated,
              outline: AppColors.darkBorder,
              outlineVariant: AppColors.darkBorder,
              onSurfaceVariant: AppColors.textSecondary,
              primaryContainer: AppColors.accent.withValues(alpha: 0.12),
              onPrimaryContainer: AppColors.accent,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.darkSurface,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              iconTheme: IconThemeData(color: AppColors.textSecondary),
            ),
            iconTheme: const IconThemeData(color: AppColors.textSecondary),
            cardTheme: CardThemeData(
              color: AppColors.darkSurface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.darkBorder),
              ),
            ),
            dividerTheme: const DividerThemeData(
              color: AppColors.darkBorder,
              thickness: 1,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppColors.darkElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.darkBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.darkBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
              ),
            ),
          ),

          themeMode: themeManager.themeMode,
          themeAnimationDuration: Duration.zero,
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
        child: AppTheme(),
      ),
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
      await getIt<KeymapProvider>().initialize();

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
