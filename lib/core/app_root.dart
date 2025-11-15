import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/system/logger.dart';
import 'package:stress_pilot/core/system/process_manager.dart';
import 'package:stress_pilot/core/system/session_manager.dart';
import 'package:stress_pilot/core/themes/theme_manager.dart';
import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/projects/presentation/pages/projects_page.dart';
import 'package:stress_pilot/features/projects/presentation/pages/project_workspace_page.dart';
import 'package:stress_pilot/features/settings/presentation/provider/setting_provider.dart';

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
          _error = 'Backend failed to start within timeout.\n\n'
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
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Initialization Error',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
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
                Text(
                  _status,
                  style: const TextStyle(fontSize: 16),
                ),
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
    final provider = context.watch<ProjectProvider>();

    final home = provider.hasSelectedProject
        ? const ProjectWorkspacePage()
        : const ProjectsPage();

    return AnimatedBuilder(
      animation: themeManager,
      builder: (context, _) {
        return MaterialApp(
          title: 'Stress Pilot',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
          ),
          themeMode: themeManager.themeMode,
          home: home,
        );
      },
    );
  }
}