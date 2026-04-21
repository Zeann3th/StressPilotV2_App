import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/endpoints/domain/models/endpoint.dart';
import 'package:stress_pilot/features/endpoints/presentation/provider/endpoint_provider.dart';
import 'package:stress_pilot/features/projects/domain/models/flow.dart' as flow_domain;
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/workspace_tab_provider.dart';

class WorkspaceSidebar extends StatelessWidget {
  const WorkspaceSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: AppColors.sidebarBackground,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: const [
                _SidebarSection(
                  title: 'Endpoints',
                  type: _SectionType.endpoints,
                ),
                SizedBox(height: AppSpacing.md),
                _SidebarSection(
                  title: 'Flows',
                  type: _SectionType.flows,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _SectionType { endpoints, flows }

class _SidebarSection extends StatefulWidget {
  final String title;
  final _SectionType type;

  const _SidebarSection({required this.title, required this.type});

  @override
  State<_SidebarSection> createState() => _SidebarSectionState();
}

class _SidebarSectionState extends State<_SidebarSection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: widget.title,
          isExpanded: _isExpanded,
          onToggle: () => setState(() => _isExpanded = !_isExpanded),
          onAdd: () {
            // TODO: Implement add logic
          },
        ),
        if (_isExpanded) ...[
          if (widget.type == _SectionType.endpoints)
            const _EndpointList()
          else
            const _FlowList(),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onAdd;

  const _SectionHeader({
    required this.title,
    required this.isExpanded,
    required this.onToggle,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Row(
          children: [
            Icon(
              isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: AppTypography.label.copyWith(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            _IconButton(
              icon: LucideIcons.plus,
              onTap: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}

class _EndpointList extends StatelessWidget {
  const _EndpointList();

  @override
  Widget build(BuildContext context) {
    final endpointProvider = context.watch<EndpointProvider>();
    final endpoints = endpointProvider.endpoints;
    final selectedEndpoint = endpointProvider.selectedEndpoint;

    return Column(
      children: endpoints.map((e) => _EndpointRow(
        endpoint: e,
        isSelected: selectedEndpoint?.id == e.id,
        onTap: () {
          endpointProvider.selectEndpoint(e);
          context.read<WorkspaceTabProvider>().openTab(
            WorkspaceTab(
              id: 'endpoint_${e.id}',
              name: e.name,
              type: WorkspaceTabType.endpoint,
              data: e,
            ),
          );
        },
      )).toList(),
    );
  }
}

class _FlowList extends StatelessWidget {
  const _FlowList();

  @override
  Widget build(BuildContext context) {
    final flowProvider = context.watch<FlowProvider>();
    final flows = flowProvider.flows;
    final selectedFlow = flowProvider.selectedFlow;

    return Column(
      children: flows.map((f) => _FlowRow(
        flow: f,
        isSelected: selectedFlow?.id == f.id,
        onTap: () {
          flowProvider.selectFlow(f);
          context.read<WorkspaceTabProvider>().openTab(
            WorkspaceTab(
              id: 'flow_${f.id}',
              name: f.name,
              type: WorkspaceTabType.flow,
              data: f,
            ),
          );
        },
      )).toList(),
    );
  }
}

class _EndpointRow extends StatefulWidget {
  final Endpoint endpoint;
  final bool isSelected;
  final VoidCallback onTap;

  const _EndpointRow({
    required this.endpoint,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_EndpointRow> createState() => _EndpointRowState();
}

class _EndpointRowState extends State<_EndpointRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final method = widget.endpoint.httpMethod ?? 'GET';
    final methodColor = _getMethodColor(method);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: AppSpacing.sidebarRowHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: widget.isSelected 
                ? AppColors.activeItem 
                : (_isHovered ? AppColors.hoverItem : Colors.transparent),
            border: widget.isSelected 
                ? Border(left: BorderSide(color: AppColors.accent, width: 2))
                : null,
          ),
          child: Row(
            children: [
              _MethodBadge(method: method, color: methodColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.endpoint.name,
                  style: AppTypography.code.copyWith(
                    color: widget.isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET': return AppColors.methodGet;
      case 'POST': return AppColors.methodPost;
      case 'PUT': return AppColors.methodPut;
      case 'DELETE': return AppColors.methodDelete;
      case 'PATCH': return AppColors.methodPatch;
      default: return AppColors.textSecondary;
    }
  }
}

class _FlowRow extends StatefulWidget {
  final flow_domain.Flow flow;
  final bool isSelected;
  final VoidCallback onTap;

  const _FlowRow({
    required this.flow,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_FlowRow> createState() => _FlowRowState();
}

class _FlowRowState extends State<_FlowRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: AppSpacing.sidebarRowHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: widget.isSelected 
                ? AppColors.activeItem 
                : (_isHovered ? AppColors.hoverItem : Colors.transparent),
            border: widget.isSelected 
                ? Border(left: BorderSide(color: AppColors.accent, width: 2))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.gitFork,
                size: 14,
                color: widget.isSelected ? AppColors.accent : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.flow.name,
                  style: AppTypography.body.copyWith(
                    color: widget.isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MethodBadge extends StatelessWidget {
  final String method;
  final Color color;

  const _MethodBadge({required this.method, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        method.toUpperCase(),
        style: AppTypography.codeSm.copyWith(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _IconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  State<_IconButton> createState() => _IconButtonState();
}

class _IconButtonState extends State<_IconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.hoverItem : Colors.transparent,
            borderRadius: AppRadius.br4,
          ),
          child: Icon(
            widget.icon,
            size: 14,
            color: _isHovered ? AppColors.accent : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
