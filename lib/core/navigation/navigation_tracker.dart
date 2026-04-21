import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum RecentEntityType { project, flow, endpoint }

class RecentPage {
  final String title;
  final String? subtitle;
  final String? badge;
  final RecentEntityType type;
  final Map<String, dynamic> arguments;
  final int iconCode;
  final String? iconFontFamily;
  final String? iconFontPackage;

  RecentPage({
    required this.title,
    this.subtitle,
    this.badge,
    required this.type,
    required this.arguments,
    required this.iconCode,
    this.iconFontFamily,
    this.iconFontPackage,
  });

  IconData get icon => IconData(
        iconCode,
        fontFamily: iconFontFamily,
        fontPackage: iconFontPackage,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'badge': badge,
        'type': type.index,
        'arguments': arguments,
        'iconCode': iconCode,
        'iconFontFamily': iconFontFamily,
        'iconFontPackage': iconFontPackage,
      };

  factory RecentPage.fromJson(Map<String, dynamic> json) => RecentPage(
        title: json['title'] as String,
        subtitle: json['subtitle'] as String?,
        badge: json['badge'] as String?,
        type: RecentEntityType.values[json['type'] as int],
        arguments: json['arguments'] as Map<String, dynamic>,
        iconCode: json['iconCode'] as int,
        iconFontFamily: json['iconFontFamily'] as String?,
        iconFontPackage: json['iconFontPackage'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecentPage &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          title == other.title;

  @override
  int get hashCode => title.hashCode ^ type.hashCode;
}

class NavigationTracker {
  static const String _key = 'recent_entities';
  static const int _maxEntries = 5;

  static Future<void> trackProject(String name, String? description, Map<String, dynamic> args) async {
    await _track(RecentPage(
      title: name,
      subtitle: description,
      type: RecentEntityType.project,
      arguments: args,
      iconCode: LucideIcons.folder.codePoint,
      iconFontFamily: LucideIcons.folder.fontFamily,
      iconFontPackage: LucideIcons.folder.fontPackage,
    ));
  }

  static Future<void> trackFlow(String name, String? description, Map<String, dynamic> args) async {
    await _track(RecentPage(
      title: name,
      subtitle: description,
      type: RecentEntityType.flow,
      arguments: args,
      iconCode: LucideIcons.gitBranch.codePoint,
      iconFontFamily: LucideIcons.gitBranch.fontFamily,
      iconFontPackage: LucideIcons.gitBranch.fontPackage,
    ));
  }

  static Future<void> trackEndpoint(String name, String? url, String? type, Map<String, dynamic> args) async {
    await _track(RecentPage(
      title: name,
      subtitle: url,
      badge: type,
      type: RecentEntityType.endpoint,
      arguments: args,
      iconCode: LucideIcons.zap.codePoint,
      iconFontFamily: LucideIcons.zap.fontFamily,
      iconFontPackage: LucideIcons.zap.fontPackage,
    ));
  }

  static Future<void> _track(RecentPage page) async {
    final prefs = await SharedPreferences.getInstance();
    final recentJson = prefs.getStringList(_key) ?? [];

    final recentItems = recentJson
        .map((e) => RecentPage.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();

    recentItems.removeWhere((p) => p == page);

    recentItems.insert(0, page);

    if (recentItems.length > _maxEntries) {
      recentItems.removeRange(_maxEntries, recentItems.length);
    }

    await prefs.setStringList(
      _key,
      recentItems.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  static Future<List<RecentPage>> getRecentItems() async {
    final prefs = await SharedPreferences.getInstance();
    final recentJson = prefs.getStringList(_key) ?? [];
    return recentJson
        .map((e) => RecentPage.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> trackPage(String route, {Map<String, dynamic>? arguments}) async {

  }
}
