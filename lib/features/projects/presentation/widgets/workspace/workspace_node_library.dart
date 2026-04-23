import 'package:flutter/material.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/projects/domain/models/canvas.dart';
import 'package:stress_pilot/features/projects/domain/models/flow.dart' as flow_domain;
import 'workspace_endpoints_list.dart';
import 'package:stress_pilot/features/shared/presentation/widgets/sidebar_section_header.dart';

class WorkspaceNodeLibrary extends StatefulWidget {
  final int projectId;
  final flow_domain.Flow? selectedFlow;

  const WorkspaceNodeLibrary({
    super.key,
    required this.projectId,
    required this.selectedFlow,
  });

  @override
  State<WorkspaceNodeLibrary> createState() => _WorkspaceNodeLibraryState();
}

class _WorkspaceNodeLibraryState extends State<WorkspaceNodeLibrary> {
  @override
  Widget build(BuildContext context) {
    final bg = AppColors.surface;

    final border = AppColors.border;

    return Container(
      width: 232,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.br16,
        border: Border.all(color: border.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          SidebarSectionHeader(label: 'LOGIC'),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 98,
                  child: _LogicChip(
                    type: FlowNodeType.start,
                    label: 'Start',
                    icon: Icons.play_arrow_rounded,
                    color: AppColors.accent,
                  ),
                ),
                SizedBox(
                  width: 98,
                  child: _LogicChip(
                    type: FlowNodeType.branch,
                    label: 'Branch',
                    icon: Icons.call_split_rounded,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
                SizedBox(
                  width: 98,
                  child: _LogicChip(
                    type: FlowNodeType.subflow,
                    label: 'Subflow',
                    icon: Icons.account_tree_rounded,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 1),

          Expanded(
            child: WorkspaceEndpointsList(
              selectedFlow: widget.selectedFlow,
              projectId: widget.projectId,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogicChip extends StatefulWidget {
  final FlowNodeType type;
  final String label;
  final IconData icon;
  final Color color;

  const _LogicChip({
    required this.type,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  State<_LogicChip> createState() => _LogicChipState();
}

class _LogicChipState extends State<_LogicChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final chipBg = AppColors.elevated;
    final border = AppColors.border;

    final dragData = DragData(
      type: widget.type,
      payload: {'name': widget.label},
    );

    return Draggable<DragData>(
      data: dragData,
      feedback: Material(
        elevation: 0,
        color: Colors.transparent,
        child: _ChipBody(
          label: widget.label,
          icon: widget.icon,
          color: widget.color,
          isDragging: true,
          hovered: false,
          bg: chipBg,
          border: widget.color,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _ChipBody(
          label: widget.label,
          icon: widget.icon,
          color: widget.color,
          isDragging: false,
          hovered: false,
          bg: chipBg,
          border: border,
        ),
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: AppDurations.micro,
          child: _ChipBody(
            label: widget.label,
            icon: widget.icon,
            color: widget.color,
            isDragging: false,
            hovered: _hovered,
            bg: chipBg,
            border: _hovered ? widget.color.withValues(alpha: 0.7) : border,
          ),
        ),
      ),
    );
  }
}

class _ChipBody extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDragging;
  final bool hovered;
  final Color bg;
  final Color border;

  const _ChipBody({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDragging,
    required this.hovered,
    required this.bg,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: hovered ? color.withValues(alpha: 0.08) : bg,
        borderRadius: AppRadius.br8,
        border: Border.all(color: border, width: 1),
        boxShadow: isDragging
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 5),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: hovered ? color : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
