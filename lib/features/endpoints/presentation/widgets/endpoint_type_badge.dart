import 'package:flutter/material.dart';
import 'package:stress_pilot/core/design/components.dart';

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

  Color _colorForType(String type) {
    switch (type.toUpperCase()) {
      case 'HTTP':
        return const Color(0xFF3B82F6);
      case 'GRPC':
        return const Color(0xFF06B6D4);
      case 'WSS':
      case 'WS':
      case 'WEBSOCKET':
        return const Color(0xFFF59E0B);
      case 'GRAPHQL':
        return const Color(0xFFEC4899);
      case 'JDBC':
      case 'SQL':
        return const Color(0xFF6366F1);
      case 'JS':
      case 'JAVASCRIPT':
        return const Color(0xFFF59E0B);
      default:
        return HSLColor.fromAHSL(
          1.0,
          (type.hashCode.abs() % 360).toDouble(),
          0.65,
          0.55,
        ).toColor();
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(type);
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
