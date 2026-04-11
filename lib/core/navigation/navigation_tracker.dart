import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';

class RecentPage {
  final String title;
  final String route;
  final IconData icon;
  final Map<String, dynamic>? arguments;

  RecentPage({
    required this.title,
    required this.route,
    required this.icon,
    this.arguments,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'route': route,
        'iconCode': icon.codePoint,
        'iconFontFamily': icon.fontFamily,
        'iconFontPackage': icon.fontPackage,
        'arguments': arguments,
      };

  factory RecentPage.fromJson(Map<String, dynamic> json) => RecentPage(
        title: json['title'] as String,
        route: json['route'] as String,
        icon: IconData(
          json['iconCode'] as int,
          fontFamily: json['iconFontFamily'] as String?,
          fontPackage: json['iconFontPackage'] as String?,
        ),
        arguments: json['arguments'] as Map<String, dynamic>?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecentPage &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          route == other.route;

  @override
  int get hashCode => title.hashCode ^ route.hashCode;
}

class NavigationTracker {
  static const String _key = 'recent_pages';
  static const int _maxEntries = 5;

  static Future<void> trackPage(String route, {Map<String, dynamic>? arguments}) async {
    final page = _getPageInfo(route, arguments);
    if (page == null) return;

    final prefs = await SharedPreferences.getInstance();
    final recentJson = prefs.getStringList(_key) ?? [];
    
    final recentPages = recentJson
        .map((e) => RecentPage.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();

    // Remove if already exists (to move it to top)
    recentPages.removeWhere((p) => p.route == page.route && _mapEquals(p.arguments, page.arguments));
    
    // Add to front (stack/LIFO)
    recentPages.insert(0, page);

    // Keep only top 5
    if (recentPages.length > _maxEntries) {
      recentPages.removeRange(_maxEntries, recentPages.length);
    }

    await prefs.setStringList(
      _key,
      recentPages.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  static Future<List<RecentPage>> getRecentPages() async {
    final prefs = await SharedPreferences.getInstance();
    final recentJson = prefs.getStringList(_key) ?? [];
    return recentJson
        .map((e) => RecentPage.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  static RecentPage? _getPageInfo(String route, Map<String, dynamic>? arguments) {
    switch (route) {
      case AppRouter.projectsRoute:
        return RecentPage(title: 'Projects', route: route, icon: LucideIcons.folder);
      case AppRouter.workspaceRoute:
        return RecentPage(title: 'Workspace', route: route, icon: LucideIcons.monitor);
      case AppRouter.settingsRoute:
        return RecentPage(title: 'Settings', route: route, icon: LucideIcons.settings);
      case AppRouter.marketplaceRoute:
        return RecentPage(title: 'Marketplace', route: route, icon: LucideIcons.shoppingBag);
      case AppRouter.agentRoute:
        return RecentPage(title: 'AI Agent', route: route, icon: LucideIcons.sparkles);
      case AppRouter.resultsRoute:
        final runId = arguments?['runId']?.toString() ?? '';
        return RecentPage(
          title: 'Run: ${runId.substring(runId.length > 8 ? runId.length - 8 : 0)}',
          route: route,
          icon: LucideIcons.activity,
          arguments: arguments,
        );
      default:
        return null;
    }
  }

  static bool _mapEquals(Map<String, dynamic>? m1, Map<String, dynamic>? m2) {
    if (m1 == m2) return true;
    if (m1 == null || m2 == null) return false;
    if (m1.length != m2.length) return false;
    for (final key in m1.keys) {
      if (!m2.containsKey(key) || m1[key] != m2[key]) return false;
    }
    return true;
  }
}
