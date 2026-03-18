import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/input/keymap_provider.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/themes/theme_manager.dart';
import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';

class GlobalShortcutListener extends StatefulWidget {
  final Widget child;

  const GlobalShortcutListener({super.key, required this.child});

  @override
  State<GlobalShortcutListener> createState() => _GlobalShortcutListenerState();
}

class _GlobalShortcutListenerState extends State<GlobalShortcutListener> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final provider = getIt<KeymapProvider>();

    for (final entry in provider.cachedActivators) {
      if (entry.key.accepts(event, HardwareKeyboard.instance)) {
        return _performAction(entry.value);
      }
    }

    return false;
  }

  bool _performAction(String actionId) {
    switch (actionId) {
      case 'sidebar.toggle':
        getIt<ProjectProvider>().toggleSidebar();
        return true;
      case 'app.settings':
        AppNavigator.pushNamed(AppRouter.settingsRoute);
        return true;
      case 'nav.runs':

        AppNavigator.pushNamed(AppRouter.projectsRoute);
        return true;
      case 'theme.toggle':
        getIt<ThemeManager>().toggleTheme();
        return true;
      case 'project.view_all':
        getIt<ProjectProvider>().clearProject();
        AppNavigator.navigatorKey.currentState?.pushReplacementNamed(AppRouter.projectsRoute);
        return true;
      case 'project.environment':
        final project = getIt<ProjectProvider>().selectedProject;
        if (project != null) {
          AppNavigator.pushNamed(
            AppRouter.projectEnvironmentRoute,
            arguments: {
              'environmentId': project.environmentId,
              'projectName': project.name,
            },
          );
        }
        return true;
      case 'project.endpoints':
        final project = getIt<ProjectProvider>().selectedProject;
        if (project != null) {
          AppNavigator.pushNamed(
             AppRouter.projectEndpointsRoute,
             arguments: {'project': project},
          );
        }
        return true;

      case 'flow.save':

        return true;

      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
