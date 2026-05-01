import 'package:flutter/material.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/projects/domain/models/canvas.dart';

class CanvasNodeWidget extends StatefulWidget {
  final CanvasNode node;
  final bool isSelected;
  final bool isTarget;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final Function(Offset) onDragUpdate;
  final Function(Offset) onDragEnd;

  const CanvasNodeWidget({
    super.key,
    required this.node,
    required this.isSelected,
    required this.isTarget,
    required this.onTap,
    required this.onDoubleTap,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  State<CanvasNodeWidget> createState() => _CanvasNodeWidgetState();
}

class _CanvasNodeWidgetState extends State<CanvasNodeWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final color = _getNodeColor(node.type);

    return Positioned(
      left: node.position.dx,
      top: node.position.dy,
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        onPanUpdate: (d) => widget.onDragUpdate(d.delta),
        onPanEnd: (d) => widget.onDragEnd(Offset.zero), // Actual offset not needed for end
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: AppDurations.micro,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.br8,
              border: Border.all(
                color: widget.isSelected
                    ? AppColors.accent
                    : widget.isTarget
                        ? Colors.orange
                        : _isHovered
                            ? AppColors.border
                            : AppColors.divider,
                width: widget.isSelected || widget.isTarget ? 2 : 1,
              ),
              boxShadow: widget.isSelected
                  ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.2), blurRadius: 8)]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getNodeIcon(node.type), size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  node.data['name'] ?? node.type.name.toUpperCase(),
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getNodeColor(FlowNodeType type) {
    switch (type) {
      case FlowNodeType.start: return Colors.green;
      case FlowNodeType.endpoint: return AppColors.accent;
      case FlowNodeType.branch: return Colors.orange;
      case FlowNodeType.subflow: return Colors.teal;
    }
  }

  IconData _getNodeIcon(FlowNodeType type) {
    switch (type) {
      case FlowNodeType.start: return Icons.play_arrow_rounded;
      case FlowNodeType.endpoint: return Icons.api_rounded;
      case FlowNodeType.branch: return Icons.call_split_rounded;
      case FlowNodeType.subflow: return Icons.account_tree_rounded;
    }
  }
}
