import 'package:flutter/material.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';

class PilotContextMenuItem {
  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;
  final WidgetBuilder? builder;

  const PilotContextMenuItem({
    this.label,
    this.icon,
    this.onTap,
    this.builder,
  });

  static PilotContextMenuItem divider() => PilotContextMenuItem(builder: (context) => const Divider(height: 1));
}

class PilotContextMenu extends StatelessWidget {
  final List<PilotContextMenuItem> items;
  final Widget child;

  const PilotContextMenu({
    super.key,
    required this.items,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: (details) => _showMenu(context, details.globalPosition),
      child: child,
    );
  }

  void _showMenu(BuildContext context, Offset position) async {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final surface = AppColors.surface;
    final border = AppColors.border;
    final textColor = AppColors.textPrimary;

    await showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(position, position),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.br12,
        side: BorderSide(color: border.withValues(alpha: 0.5)),
      ),
      elevation: 8,
      color: surface,
      constraints: const BoxConstraints(minWidth: 180),
      items: items.map<PopupMenuEntry<dynamic>>((item) {
        if (item.builder != null && item.builder!(context) is Divider) {
          return const PopupMenuDivider(height: 1);
        }

        return PopupMenuItem(
          onTap: item.onTap,
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: item.builder?.call(context) ?? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.icon != null) ...[
                Icon(item.icon, size: 16, color: textColor.withValues(alpha: 0.7)),
                const SizedBox(width: 12),
              ],
              Text(
                item.label ?? '',
                style: AppTypography.body.copyWith(
                  fontSize: 13,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
