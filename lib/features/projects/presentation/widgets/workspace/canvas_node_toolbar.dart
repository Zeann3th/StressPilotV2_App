import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/projects/domain/models/canvas.dart';
import 'dart:ui';

class CanvasNodeToolbar extends StatelessWidget {
  const CanvasNodeToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: AppRadius.br12,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.br12,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToolbarNodeItem(
                type: FlowNodeType.start,
                icon: LucideIcons.play,
                label: 'Start',
                color: Colors.green,
              ),
              const _Divider(),
              _ToolbarNodeItem(
                type: FlowNodeType.branch,
                icon: LucideIcons.gitBranch,
                label: 'Branch',
                color: AppColors.accent,
              ),
              const _Divider(),
              _ToolbarNodeItem(
                type: FlowNodeType.subflow,
                icon: LucideIcons.network,
                label: 'Subflow',
                color: Colors.teal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarNodeItem extends StatefulWidget {
  final FlowNodeType type;
  final IconData icon;
  final String label;
  final Color color;

  const _ToolbarNodeItem({
    required this.type,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  State<_ToolbarNodeItem> createState() => _ToolbarNodeItemState();
}

class _ToolbarNodeItemState extends State<_ToolbarNodeItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final dragData = DragData(
      type: widget.type,
      payload: {'name': widget.label},
    );

    return Draggable<DragData>(
      data: dragData,
      feedback: Material(
        color: Colors.transparent,
        child: _IconBody(
          icon: widget.icon,
          color: widget.color,
          isDragging: true,
          hovered: false,
        ),
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Tooltip(
          message: widget.label,
          child: _IconBody(
            icon: widget.icon,
            color: widget.color,
            isDragging: false,
            hovered: _hovered,
          ),
        ),
      ),
    );
  }
}

class _IconBody extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isDragging;
  final bool hovered;

  const _IconBody({
    required this.icon,
    required this.color,
    required this.isDragging,
    required this.hovered,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: hovered ? color.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: AppRadius.br8,
        border: Border.all(
          color: isDragging ? color : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Icon(
        icon,
        size: 18,
        color: hovered || isDragging ? color : AppColors.textSecondary,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: AppColors.divider,
    );
  }
}
