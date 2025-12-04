import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/system/logger.dart';
import 'package:stress_pilot/core/system/process_manager.dart';
import 'package:stress_pilot/core/system/session_manager.dart';
import 'package:stress_pilot/core/themes/theme_manager.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/settings/presentation/provider/setting_provider.dart';
import 'package:stress_pilot/features/common/presentation/provider/endpoint_provider.dart';

import '../features/projects/presentation/provider/canvas_provider.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _initialized = false;
  String? _error;
  String _status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      AppLogger.info('Starting application initialization', name: 'AppRoot');

      setState(() => _status = 'Starting backend process...');
      await AppLogger.measure(
        'Backend startup',
        () => getIt<CoreProcessManager>().initialize(),
        name: 'AppRoot',
      );

      await Future.delayed(const Duration(seconds: 2));

      setState(() => _status = 'Waiting for backend to be ready...');
      final isHealthy = await getIt<SessionManager>().waitForHealthCheck(
        maxAttempts: 24,
        interval: const Duration(seconds: 5),
      );

      if (!isHealthy) {
        setState(() {
          _error =
              'Backend failed to start within timeout.\n\n'
              'Check the console logs for backend errors.\n'
              'The backend process may need more time to start.';
          _status = 'Failed';
        });
        AppLogger.error('Backend health check failed', name: 'AppRoot');
        return;
      }

      setState(() => _status = 'Initializing session...');
      await getIt<SessionManager>().initializeSession();

      setState(() => _status = 'Loading projects...');
      await AppLogger.measure(
        'Project provider initialization',
        () => getIt<ProjectProvider>().initialize(),
        name: 'AppRoot',
      );

      setState(() {
        _initialized = true;
        _status = 'Ready';
      });

      AppLogger.info('Application initialized successfully', name: 'AppRoot');
    } catch (e, st) {
      setState(() {
        _error = 'Initialization failed:\n\n$e\n\nCheck console for details.';
        _status = 'Error';
      });
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
    if (_error != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Initialization Error',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _status = 'Initializing...';
                      _initialized = false;
                    });
                    _init();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_initialized) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(_status, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      );
    }

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
      ],
      child: const _AppWithTheme(),
    );
  }

  @override
  void dispose() {
    getIt<CoreProcessManager>().stop();
    super.dispose();
  }
}

class _AppWithTheme extends StatelessWidget {
  const _AppWithTheme();

  @override
  Widget build(BuildContext context) {
    final themeManager = getIt<ThemeManager>();

    // Modern Minimalist Color Palette (Inter Blue)
    const seedColor = Color(0xFF2563EB);

    return AnimatedBuilder(
      animation: themeManager,
      builder: (context, _) {
        return MaterialApp(
          title: 'Stress Pilot',
          debugShowCheckedModeBanner: false,
          navigatorKey: AppNavigator.navigatorKey,

          // --- LIGHT THEME ---
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: seedColor,
              brightness: Brightness.light,
              surface: Colors.white,
              // Pure white surface
              surfaceContainer: const Color(0xFFF8FAFC),
              // Very light grey for containers
              surfaceContainerLow: const Color(0xFFF1F5F9),
              onSurface: const Color(0xFF0F172A),
              // Dark slate text
              onSurfaceVariant: const Color(0xFF64748B),
              // Slate text
              outline: const Color(0xFFE2E8F0),
              // Subtle borders
              outlineVariant: const Color(0xFFCBD5E1),
            ),
            scaffoldBackgroundColor: Colors.white,
            dividerTheme: const DividerThemeData(
              color: Color(0xFFE2E8F0),
              thickness: 1,
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              iconTheme: IconThemeData(color: Color(0xFF0F172A)),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: seedColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: seedColor, width: 1.5),
              ),
            ),
          ),

          // --- DARK THEME ---
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: seedColor,
              brightness: Brightness.dark,
              surface: const Color(0xFF0F172A),
              // Dark Slate
              surfaceContainer: const Color(0xFF1E293B),
              surfaceContainerLow: const Color(0xFF1E293B),
              onSurface: const Color(0xFFF8FAFC),
              onSurfaceVariant: const Color(0xFF94A3B8),
              outline: const Color(0xFF334155),
              outlineVariant: const Color(0xFF475569),
            ),
            scaffoldBackgroundColor: const Color(0xFF0F172A),
            dividerTheme: const DividerThemeData(
              color: Color(0xFF334155),
              thickness: 1,
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF1E293B),
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Color(0xFF334155)),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0F172A),
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: seedColor, width: 1.5),
              ),
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
