import 'package:flutter/material.dart';
import 'package:stress_pilot/core/themes/components/components.dart';

class EndpointTypeBadge extends StatelessWidget {
  final String type;
  final bool compact;
  final bool inverse;

  const EndpointTypeBadge({
    super.key,
    required this.type,
    this.compact = false,
    this.inverse = false,
  });

  Color _colorForType(BuildContext context, String type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color baseColor;
    switch (type.toUpperCase()) {
      case 'HTTP':
        baseColor = const Color(0xFF3B82F6);
        break;
      case 'GRPC':
        baseColor = const Color(0xFF06B6D4);
        break;
      case 'WSS':
      case 'WS':
      case 'WEBSOCKET':
        baseColor = const Color(0xFFF59E0B);
        break;
      case 'GRAPHQL':
        baseColor = const Color(0xFFEC4899);
        break;
      case 'JDBC':
      case 'SQL':
        baseColor = const Color(0xFF6366F1);
        break;
      case 'JS':
      case 'JAVASCRIPT':
        baseColor = const Color(0xFFF59E0B);
        break;
      default:
        baseColor = HSLColor.fromAHSL(
          1.0,
          (type.hashCode.abs() % 360).toDouble(),
          0.65,
          0.55,
        ).toColor();
    }

    if (!isDark) {
      // Darken slightly for light mode to maintain contrast
      final hsl = HSLColor.fromColor(baseColor);
      return hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor();
    }
    return baseColor;
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(context, type);
    final label = type.toUpperCase().length > 4 && compact
        ? type.toUpperCase().substring(0, 4)
        : type.toUpperCase();

    return PilotBadge(
      label: label,
      color: inverse ? Colors.white : color,
      compact: compact,
    );
  }
}
