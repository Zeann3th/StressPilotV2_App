import 'package:flutter/material.dart';

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

  Color _getTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'HTTP':
        return Colors.blue;
      case 'GRPC':
        return Colors.teal;
      case 'WSS':
      case 'WS':
      case 'WEBSOCKET':
        return Colors.orange;
      case 'GRAPHQL':
        return Colors.pink;
      case 'JDBC':
      case 'SQL':
        return Colors.indigo;
      case 'JS':
      case 'JAVASCRIPT':
        return Colors.amber.shade700;
      default:
        final int hash = type.hashCode;
        return HSLColor.fromAHSL(
          1.0,
          (hash % 360).toDouble(),
          0.7,
          0.5,
        ).toColor();
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getTypeColor(type);

    final textColor = inverse ? Colors.white : color;
    final bgColor = inverse
        ? Colors.white.withOpacity(0.25)
        : color.withOpacity(0.1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type.toUpperCase().substring(0, compact && type.length > 4 ? 4 : null),
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
