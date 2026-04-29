import 'package:flutter/material.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/features/environments/presentation/pages/environment_page.dart';
import 'package:stress_pilot/features/projects/presentation/pages/project_workspace_page.dart';
import 'package:stress_pilot/features/projects/presentation/pages/recent_activity_page.dart';
import 'package:stress_pilot/features/shared/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/results/presentation/pages/results_page.dart';
import 'package:stress_pilot/features/settings/presentation/pages/settings_page.dart';
import 'package:stress_pilot/features/marketplace/presentation/pages/marketplace_page.dart';
import 'package:stress_pilot/features/results/presentation/pages/recent_runs_page.dart';

class AppRouter {
  static const String projectsRoute = '/';
  static const String workspaceRoute = '/workspace';
  static const String settingsRoute = '/settings';
  static const String projectEnvironmentRoute = '/project/environment';
  static const String resultsRoute = '/results';
  static const String recentRunsRoute = '/recent-runs';
  static const String marketplaceRoute = '/marketplace';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    MaterialPageRoute<T> buildRoute<T>(Widget widget) {
      return MaterialPageRoute<T>(builder: (_) => widget, settings: settings);
    }

    if (settings.name == workspaceRoute) {
      final projectProvider = getIt<ProjectProvider>();
      if (projectProvider.selectedProject == null) {
        return buildRoute(const RecentActivityPage());
      }
    }

    switch (settings.name) {
      case projectsRoute:
        return buildRoute(const RecentActivityPage());
      case workspaceRoute:
        return buildRoute(const ProjectWorkspacePage());
      case settingsRoute:
        return buildRoute(const SettingsPage());
      case projectEnvironmentRoute:
        final args = settings.arguments as Map<String, dynamic>;
        return buildRoute(
          EnvironmentPage(
            environmentId: args['environmentId'],
            projectName: args['projectName'],
          ),
        );
      case resultsRoute:
        final args = settings.arguments as Map<String, dynamic>;
        return buildRoute(ResultsPage(runId: args['runId'] as String));
      case recentRunsRoute:
        return buildRoute(const RecentRunsPage());
      case marketplaceRoute:
        return buildRoute(const MarketplacePage());

      default:
        return buildRoute(
          Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}

class AppRouteObserver extends NavigatorObserver {
  String? currentRouteName;
  Object? currentArguments;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    currentRouteName = route.settings.name;
    currentArguments = route.settings.arguments;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    currentRouteName = previousRoute?.settings.name;
    currentArguments = previousRoute?.settings.arguments;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    currentRouteName = newRoute?.settings.name;
    currentArguments = newRoute?.settings.arguments;
  }
}

class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static final AppRouteObserver routeObserver = AppRouteObserver();

  static Future<T?> pushNamed<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    if (routeObserver.currentRouteName == routeName &&
        _areArgumentsEqual(routeObserver.currentArguments, arguments)) {
      return Future.value(null);
    }

    return navigatorKey.currentState!.pushNamed<T>(
      routeName,
      arguments: arguments,
    );
  }

  static Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    TO? result,
    Object? arguments,
  }) {
    if (routeObserver.currentRouteName == routeName &&
        _areArgumentsEqual(routeObserver.currentArguments, arguments)) {
      return Future.value(null);
    }

    return navigatorKey.currentState!.pushReplacementNamed<T, TO>(
      routeName,
      result: result,
      arguments: arguments,
    );
  }
  static void pop<T extends Object?>([T? result]) {
    navigatorKey.currentState?.pop<T>(result);
  }

  static Future<bool> maybePop<T extends Object?>([T? result]) async {
    return await navigatorKey.currentState?.maybePop<T>(result) ?? false;
  }

  static bool _areArgumentsEqual(Object? arg1, Object? arg2) {
    if (arg1 == arg2) return true;
    if (arg1 is Map && arg2 is Map) {
      if (arg1.length != arg2.length) return false;
      for (final key in arg1.keys) {
        if (arg1[key] != arg2[key]) return false;
      }
      return true;
    }
    return false;
  }
}
