import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/projects/domain/models/flow.dart' as flow_domain;
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/flow_dialog.dart';

class WorkspaceFlowTabs extends StatelessWidget {
  final flow_domain.Flow? selectedFlow;
  final ValueChanged<flow_domain.Flow?> onFlowSelected;

  const WorkspaceFlowTabs({
    super.key,
    required this.selectedFlow,
    required this.onFlowSelected,
  });

  @override
  Widget build(BuildContext context) {
    final border = AppColors.border;

    final flowProvider = context.watch<FlowProvider>();
    final flows = flowProvider.flows;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(vertical: 2),
      color: Colors.transparent,
      child: Row(
        children: [

          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 8),
              itemCount: flows.length,
              itemBuilder: (context, i) => _FlowTab(
                flow: flows[i],
                isActive: selectedFlow?.id == flows[i].id,
                onSelect: () {
                  onFlowSelected(flows[i]);
                  flowProvider.selectFlow(flows[i]);
                },
                onEdit: () => FlowDialog.showEditDialog(
                  context,
                  flow: flows[i],
                  onUpdate: (id, name, desc) =>
                      flowProvider.updateFlow(flowId: id, name: name, description: desc),
                ),
                onDelete: () => FlowDialog.showDeleteDialog(
                  context,
                  flow: flows[i],
                  onDelete: (id) => flowProvider.deleteFlow(id),
                ),
              ),
            ),
          ),

          _NewFlowButton(
            onPressed: () {
              final projectId =
                  context.read<ProjectProvider>().selectedProject?.id;
              if (projectId == null) return;
              final flowProv = context.read<FlowProvider>();
              FlowDialog.showCreateDialog(
                context,
                onCreate: (name, desc, type, pid) async {
                  await flowProv.createFlow(
                    flow_domain.CreateFlowRequest(
                      projectId: pid,
                      name: name,
                      description: desc,
                      type: type,
                    ),
                  );
                },
              );
            },
            border: border,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _FlowTab extends StatefulWidget {
  final flow_domain.Flow flow;
  final bool isActive;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FlowTab({
    required this.flow,
    required this.isActive,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_FlowTab> createState() => _FlowTabState();
}

class _FlowTabState extends State<_FlowTab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppColors.textPrimary;

    final labelColor = widget.isActive
        ? AppColors.accent
        : _hovered
            ? textColor
            : AppColors.textSecondary;

    final bgColor = widget.isActive
        ? AppColors.accent.withValues(alpha: 0.08)
        : _hovered
            ? (isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.03))
            : Colors.transparent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedContainer(
          duration: AppDurations.micro,
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppRadius.br8,
            border: widget.isActive
                ? Border.all(
                    color: AppColors.accent.withValues(alpha: 0.35),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [

              if (widget.isActive) ...[
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.6),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 7),
              ],

              Text(
                widget.flow.name,
                style: AppTypography.body.copyWith(
                  color: labelColor,
                  fontWeight:
                      widget.isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),

              if (_hovered || widget.isActive) ...[
                const SizedBox(width: 4),
                _TabMenu(onEdit: widget.onEdit, onDelete: widget.onDelete),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TabMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TabMenu({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Icon(
        Icons.more_horiz_rounded,
        size: 14,
        color: AppColors.textMuted,
      ),
      tooltip: '',
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(children: [
            const Icon(Icons.edit_outlined, size: 14),
            const SizedBox(width: 8),
            const Text('Rename'),
          ]),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete_outline_rounded, size: 14, color: AppColors.error),
            const SizedBox(width: 8),
            Text('Delete', style: TextStyle(color: AppColors.error)),
          ]),
        ),
      ],
      onSelected: (v) {
        if (v == 'edit') onEdit();
        if (v == 'delete') onDelete();
      },
    );
  }
}

class _NewFlowButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Color border;
  const _NewFlowButton({required this.onPressed, required this.border});

  @override
  State<_NewFlowButton> createState() => _NewFlowButtonState();
}

class _NewFlowButtonState extends State<_NewFlowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AppDurations.micro,
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: AppRadius.br8,
            border: Border.all(
              color: _hovered
                  ? AppColors.accent.withValues(alpha: 0.5)
                  : widget.border,
              width: 1,
            ),
            color: _hovered
                ? AppColors.accent.withValues(alpha: 0.06)
                : Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                size: 13,
                color: _hovered ? AppColors.accent : AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                'New Flow',
                style: AppTypography.caption.copyWith(
                  color: _hovered ? AppColors.accent : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
