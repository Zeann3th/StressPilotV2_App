import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/features/projects/presentation/pages/project_workspace_page.dart';
import 'package:stress_pilot/features/projects/presentation/pages/projects_page.dart';
import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/settings/presentation/pages/settings_page.dart';

class AppRouter {
  static const String projectsRoute = '/';
  static const String workspaceRoute = '/workspace';
  static const String settingsRoute = '/settings';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Helper for creating a standard page route.
    MaterialPageRoute<T> buildRoute<T>(Widget widget) {
      return MaterialPageRoute<T>(builder: (_) => widget, settings: settings);
    }

    // Guard for workspace route. If no project is selected, redirect to the project selection page.
    if (settings.name == workspaceRoute) {
      final projectProvider = Provider.of<ProjectProvider>(
          AppNavigator.navigatorKey.currentContext!,
          listen: false);
      if (projectProvider.selectedProject == null) {
        return buildRoute(const ProjectsPage());
      }
    }

    switch (settings.name) {
      case projectsRoute:
        return buildRoute(const ProjectsPage());
      case workspaceRoute:
        return buildRoute(const ProjectWorkspacePage());
      case settingsRoute:
        return buildRoute(const SettingsPage());
      default:
        return buildRoute(
          Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}

// AppNavigator is now part of this file to consolidate navigation logic.
class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<T?> pushNamed<T extends Object?>(String routeName,
      {Object? arguments}) {
    return navigatorKey.currentState!
        .pushNamed<T>(routeName, arguments: arguments);
  }

  static Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    TO? result,
    Object? arguments,
  }) {
    return navigatorKey.currentState!.pushReplacementNamed<T, TO>(routeName,
        result: result, arguments: arguments);
  }

  static void pop<T extends Object?>([T? result]) {
    navigatorKey.currentState?.pop<T>(result);
  }

  static Future<bool> maybePop<T extends Object?>([T? result]) async {
    return await navigatorKey.currentState?.maybePop<T>(result) ?? false;
  }
}

