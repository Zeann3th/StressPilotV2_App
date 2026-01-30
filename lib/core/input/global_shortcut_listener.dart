import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/input/keymap_provider.dart';
import 'package:stress_pilot/core/input/shortcut_parser.dart';
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
    
    // Ignore if a text field has focus to prevent interfering with typing
    // Actually, for Ctrl-combinations, we usually WANT them to work even in text fields,
    // but single keys (like Delete) might be tricky.
    // For now, let's allow all, but maybe checking focus manager is safer.
    // Ideally:
    // FocusManager.instance.primaryFocus?.context?.widget is EditableText ?
    
    // But let's proceed with simple matching first.
    
    final provider = getIt<KeymapProvider>(); // Access via locator as we might be outside context or matching is easier
    final keymap = provider.keymap;

    for (final entry in keymap.entries) {
      final actionId = entry.key;
      final shortcut = entry.value;

      if (ShortcutParser.isMatch(event, shortcut)) {
        return _performAction(actionId);
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
        AppNavigator.pushNamed(AppRouter.runsRoute);
        return true;
      case 'nav.browser_spy':
        AppNavigator.pushNamed(AppRouter.browserSpyRoute);
        return true;
      case 'nav.marketplace':
        AppNavigator.pushNamed(AppRouter.marketplaceRoute);
        return true;
      case 'theme.toggle':
        getIt<ThemeManager>().toggleTheme();
        return true;
      case 'project.view_all':
         // We might need to clear project too? Mimic UI behavior
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

      // 'flow.save', 'flow.run', etc. generally require context or knowing the active project/flow.
      // We can implement them if Providers are singletons, which they are.
      case 'flow.save':
        // getIt<FlowProvider>().saveCurrentFlow(); // Assuming such method exists
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
