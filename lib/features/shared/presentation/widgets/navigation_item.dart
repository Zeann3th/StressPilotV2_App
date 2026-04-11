import 'package:flutter/material.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/themes/components/feedback/pilot_badge.dart';

class NavigationItem extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? badge;
  final IconData icon;
  final VoidCallback onTap;
  final bool compact;

  const NavigationItem({
    super.key,
    required this.title,
    this.subtitle,
    this.badge,
    required this.icon,
    required this.onTap,
    this.compact = false,
  });

  @override
  State<NavigationItem> createState() => _NavigationItemState();
}

class _NavigationItemState extends State<NavigationItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.micro,
          color: _hovered
              ? AppColors.accent.withValues(alpha: 0.08)
              : Colors.transparent,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 10 : 14,
            vertical: widget.compact ? 6 : 8,
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: widget.compact ? 13 : 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        widget.subtitle!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                          fontSize: widget.compact ? 11 : 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.badge != null) ...[
                const SizedBox(width: 8),
                PilotBadge(
                  label: widget.badge!.toUpperCase(),
                  color: _getBadgeColor(widget.badge!),
                  compact: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getBadgeColor(String type) {
    switch (type.toUpperCase()) {
      case 'HTTP':
        return const Color(0xFF3B82F6);
      case 'GRPC':
        return const Color(0xFF06B6D4);
      case 'WS':
      case 'WSS':
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
}
