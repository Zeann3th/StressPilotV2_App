import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/input/keymap_provider.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/themes/theme_manager.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/shared/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/shared/presentation/widgets/global_search_dropdown.dart';

class GlobalShortcutListener extends StatefulWidget {
  final Widget child;

  const GlobalShortcutListener({super.key, required this.child});

  @override
  State<GlobalShortcutListener> createState() => _GlobalShortcutListenerState();
}

class _GlobalShortcutListenerState extends State<GlobalShortcutListener> {
  DateTime? _lastShiftPressTime;
  final _shiftDoubleTapThreshold = const Duration(milliseconds: 400);

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

    // Double-Shift -> global search
    if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
        event.logicalKey == LogicalKeyboardKey.shiftRight) {
      final now = DateTime.now();
      if (_lastShiftPressTime != null &&
          now.difference(_lastShiftPressTime!) < _shiftDoubleTapThreshold) {
        _lastShiftPressTime = null;
        _performAction('search.anywhere');
        return true;
      }
      _lastShiftPressTime = now;
      return false;
    }

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
        AppNavigator.pushNamed(AppRouter.recentRunsRoute);
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
          AppNavigator.pushNamed(AppRouter.workspaceRoute);
        }
        return true;
      case 'search.anywhere':
        _showGlobalSearch();
        return true;

      case 'flow.save':

        return true;

      default:
        return false;
    }
  }

  void _showGlobalSearch() {
    final ctx = AppNavigator.navigatorKey.currentContext;
    if (ctx == null) return;
    showDialog<void>(
      context: ctx,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      builder: (_) => const _GlobalSearchDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _GlobalSearchDialog extends StatelessWidget {
  const _GlobalSearchDialog();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -0.4),
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 560,
          constraints: const BoxConstraints(maxHeight: 480),
          decoration: BoxDecoration(
            color: AppColors.elevatedSurface,
            borderRadius: AppRadius.br8,
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: const GlobalSearchDropdown(),
        ),
      ),
    );
  }
}
