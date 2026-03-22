import 'package:flutter/material.dart';

class PilotTheme {
  final String id;
  final String name;
  final Brightness brightness;
  final Map<String, Color> colors;

  const PilotTheme({
    required this.id,
    required this.name,
    required this.brightness,
    required this.colors,
  });

  bool get isDark => brightness == Brightness.dark;

  factory PilotTheme.fromJson(String id, Map<String, dynamic> json) {
    final colorsJson = json['colors'] as Map<String, dynamic>? ?? {};
    final Map<String, Color> parsedColors = {};

    colorsJson.forEach((key, value) {
      if (value is String) {
        final color = _parseHexColor(value);
        if (color != null) {
          parsedColors[key] = color;
        }
      }
    });

    return PilotTheme(
      id: id,
      name: json['name'] ?? id,
      brightness: (json['brightness'] as String?)?.toLowerCase() == 'light'
          ? Brightness.light
          : Brightness.dark,
      colors: parsedColors,
    );
  }

  static Color? _parseHexColor(String hex) {
    hex = hex.replaceAll('#', '');
    try {
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
      if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return null;
  }

  Color getColor(String key, Color fallback) {
    return colors[key] ?? fallback;
  }
}
