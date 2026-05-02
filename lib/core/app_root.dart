import 'dart:async';

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
import 'package:stress_pilot/core/system/app_state_manager.dart';
import 'package:stress_pilot/features/marketplace/domain/repositories/plugin_capability_repository.dart';

import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/endpoints/presentation/provider/endpoint_provider.dart';
import 'package:stress_pilot/features/settings/presentation/provider/setting_provider.dart';
import 'package:stress_pilot/core/input/keymap_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/core/input/global_shortcut_listener.dart';
import 'package:stress_pilot/features/workspace/presentation/provider/workspace_tab_provider.dart';
import 'package:stress_pilot/features/workspace/presentation/provider/canvas_provider.dart';
import 'package:stress_pilot/features/environments/presentation/provider/environment_provider.dart';
import 'package:stress_pilot/features/results/presentation/provider/results_provider.dart';
import 'package:stress_pilot/features/results/presentation/provider/run_provider.dart';
import 'package:stress_pilot/features/settings/presentation/provider/plugin_settings_provider.dart';
import 'package:stress_pilot/features/settings/presentation/provider/function_settings_provider.dart';
import 'package:stress_pilot/features/scheduling/presentation/provider/scheduling_provider.dart';
import 'package:stress_pilot/core/updater/update_dialog.dart';
import 'package:stress_pilot/features/shared/presentation/widgets/app_skeleton.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:stress_pilot/core/window/window_manager.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';

class AppRoot extends StatefulWidget {

  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _initialized = false;
  bool _hasError = false;
  String _initialRoute = AppRouter.projectsRoute;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      AppLogger.info('Starting application initialization (non-blocking)', name: 'AppRoot');

      // Core sync/fast initializations
      await getIt<ThemeManager>().initialize();
      await getIt<ProjectProvider>().initialize();
      await getIt<KeymapProvider>().initialize();
      await getIt<PluginCapabilityRepository>().initialize();

      final appStateManager = getIt<AppStateManager>();

      // Register background tasks
      appStateManager.register('Backend Process', () async {
        await getIt<ProcessManager>().startBackend(
          attachLogs: kDebugMode,
          onExit: (code) {
            appStateManager.markFailed('Backend Process',
                error: 'Process exited with code $code');
          },
        );
      });

      appStateManager.register('Session Manager', () async {
        await getIt<SessionManager>().initializeSession();
      });

      // Launch background processes
      unawaited(appStateManager.recover('Backend Process').catchError((e) {
        AppLogger.error('Backend background startup failed', name: 'AppRoot', error: e);
      }));

      unawaited(appStateManager.recover('Session Manager').catchError((e) {
        AppLogger.error('Session background initialization failed', name: 'AppRoot', error: e);
      }));

      if (mounted) {
        setState(() {
          _initialized = true;
          _hasError = false;
          _initialRoute = getIt<ProjectProvider>().hasSelectedProject
              ? AppRouter.workspaceRoute
              : AppRouter.projectsRoute;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            UpdateDialog.checkAndShow(context);
          }
        });
      }

      AppLogger.info('Application shell initialized', name: 'AppRoot');
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
        ChangeNotifierProvider<WorkspaceTabProvider>.value(
          value: getIt<WorkspaceTabProvider>(),
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
        ChangeNotifierProvider<AppStateManager>.value(
          value: getIt<AppStateManager>(),
        ),
        ChangeNotifierProvider<PluginSettingsProvider>.value(
          value: getIt<PluginSettingsProvider>(),
        ),
        ChangeNotifierProvider<FunctionSettingsProvider>.value(
          value: getIt<FunctionSettingsProvider>(),
        ),
        ChangeNotifierProvider<SchedulingProvider>.value(
          value: getIt<SchedulingProvider>(),
        ),
        ],

      child: _initialized && !_hasError
          ? GlobalShortcutListener(
              child: _AppTheme(initialRoute: _initialRoute),
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
    Widget child = ShadApp(
      title: 'Stress Pilot',
      debugShowCheckedModeBanner: false,
      home: const AppSkeleton(),
    );

    if (WindowSetup.isSupported) {
      child = WindowBorder(color: AppColors.border, width: 1, child: child);
    }
    return child;
  }
}

class _AppTheme extends StatelessWidget {
  final String initialRoute;
  const _AppTheme({required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();

    return ShadApp(
      key: ValueKey(themeManager.currentTheme.id), // FORCE REBUILD ON THEME CHANGE
      title: 'Stress Pilot',
      debugShowCheckedModeBanner: false,
      navigatorKey: AppNavigator.navigatorKey,
      navigatorObservers: [AppNavigator.routeObserver],
      themeMode: themeManager.themeMode,
      theme: themeManager.currentShadTheme ?? themeManager.lightShadTheme,
      darkTheme: themeManager.currentShadTheme ?? themeManager.darkShadTheme,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: initialRoute,
      builder: (context, child) {
        return ScaffoldMessenger(
          key: AppNavigator.scaffoldMessengerKey,
          child: child!,
        );
      },
    );
  }
}
