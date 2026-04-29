import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/endpoints/domain/models/endpoint.dart';
import 'package:stress_pilot/features/shared/domain/repositories/utility_repository.dart';
import 'package:stress_pilot/features/shared/presentation/provider/endpoint_provider.dart';
import 'package:stress_pilot/features/shared/presentation/widgets/create_endpoint_dialog.dart';
import 'package:stress_pilot/features/projects/domain/models/flow.dart' as flow_domain;
import 'package:stress_pilot/features/projects/domain/models/canvas.dart';
import 'package:stress_pilot/features/shared/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/features/shared/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/workspace_tab_provider.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/flow_dialog.dart';

import 'package:stress_pilot/features/shared/presentation/widgets/sidebar_section_header.dart';

class WorkspaceSidebar extends StatefulWidget {
  final double width;
  final VoidCallback onCollapse;

  const WorkspaceSidebar({
    super.key,
    this.width = 260,
    required this.onCollapse,
  });

  @override
  State<WorkspaceSidebar> createState() => _WorkspaceSidebarState();
}

class _WorkspaceSidebarState extends State<WorkspaceSidebar> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        color: AppColors.sidebarBackground,
        border: Border(right: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        children: [
          // Sidebar Toolbar (Search)
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: AppTypography.body.copyWith(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle: AppTypography.body.copyWith(
                        color: AppColors.textDisabled,
                        fontSize: 12,
                      ),
                      prefixIcon: const Icon(LucideIcons.search, size: 14),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  ),
                ),
                _IconButton(
                  icon: LucideIcons.panelLeftClose,
                  onTap: widget.onCollapse,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _SidebarSection(
                  title: 'ENDPOINTS',
                  type: _SectionType.endpoints,
                  searchQuery: _searchQuery,
                ),
                const SizedBox(height: 8),
                _SidebarSection(
                  title: 'FLOWS',
                  type: _SectionType.flows,
                  searchQuery: _searchQuery,
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
  final String searchQuery;

  const _SidebarSection({
    required this.title, 
    required this.type,
    required this.searchQuery,
  });

  @override
  State<_SidebarSection> createState() => _SidebarSectionState();
}

class _SidebarSectionState extends State<_SidebarSection> {
  bool _isExpanded = true;

  void _handleAdd(BuildContext context) {
    switch (widget.type) {
      case _SectionType.endpoints:
        final projectId = context.read<ProjectProvider>().selectedProject?.id;
        if (projectId == null) return;
        showDialog<void>(
          context: context,
          builder: (_) => CreateEndpointDialog(projectId: projectId),
        );
        break;
      case _SectionType.flows:
        FlowDialog.showCreateDialog(
          context,
          onCreate: (name, description, type, projectId) async {
            await context.read<FlowProvider>().createFlow(
              flow_domain.CreateFlowRequest(
                name: name,
                description: description,
                type: type,
                projectId: projectId,
              ),
            );
          },
        );
        break;
    }
  }

  Future<void> _handleUpload(BuildContext context) async {
    try {
      final capabilities = await getIt<UtilityRepository>().getCapabilities();
      final formats = capabilities.parsers
          .expand((p) => p.formats)
          .map((e) => e.toLowerCase().replaceAll('.', ''))
          .toSet()
          .toList();

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: formats.isEmpty ? ['json', 'yaml', 'yml', 'proto'] : formats,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;
      final filePath = result.files.first.path;
      if (filePath == null) return;

      if (!context.mounted) return;
      
      final selectedProject = context.read<ProjectProvider>().selectedProject;
      if (selectedProject == null) return;
      
      PilotToast.show(context, 'Uploading endpoints...');
      
      final provider = context.read<EndpointProvider>();
      await provider.uploadEndpointsFile(
        filePath: filePath,
        projectId: selectedProject.id,
      );
      
      if (context.mounted) {
        PilotToast.show(context, 'Endpoints uploaded successfully');
      }
    } catch (e) {
      if (context.mounted) {
        PilotToast.show(context, 'Upload failed: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: SidebarSectionHeader(
            label: widget.title,
            isExpanded: _isExpanded,
            onToggle: () => setState(() => _isExpanded = !_isExpanded),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.type == _SectionType.endpoints)
                  _IconButton(
                    icon: LucideIcons.upload,
                    onTap: () => _handleUpload(context),
                  ),
                _IconButton(
                  icon: LucideIcons.plus,
                  onTap: () => _handleAdd(context),
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded) ...[
          if (widget.type == _SectionType.endpoints)
            _EndpointList(searchQuery: widget.searchQuery)
          else
            _FlowList(searchQuery: widget.searchQuery),
        ],
      ],
    );
  }
}

class _EndpointList extends StatelessWidget {
  final String searchQuery;
  const _EndpointList({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final endpointProvider = context.watch<EndpointProvider>();
    final endpoints = endpointProvider.endpoints.where((e) =>
        e.name.toLowerCase().contains(searchQuery)).toList();
    final selectedEndpoint = endpointProvider.selectedEndpoint;
    final projectId =
        context.read<ProjectProvider>().selectedProject?.id ?? 0;

    void openTab(Endpoint e) {
      endpointProvider.selectEndpoint(e);
      context.read<WorkspaceTabProvider>().openTab(
        WorkspaceTab(
          id: 'endpoint_${e.id}',
          name: e.name,
          type: WorkspaceTabType.endpoint,
          data: e,
        ),
      );
    }

    return Column(
      children: endpoints.map((e) => _EndpointRow(
        endpoint: e,
        isSelected: selectedEndpoint?.id == e.id,
        onTap: () => openTab(e),
        onEdit: () {
          // Show rename dialog
          final ctrl = TextEditingController(text: e.name);
          PilotDialog.show(
            context: context,
            title: 'Rename Endpoint',
            content: PilotInput(controller: ctrl, autofocus: true),
            actions: [
              PilotButton.ghost(label: 'Cancel', onPressed: () => Navigator.pop(context)),
              PilotButton.primary(
                label: 'Rename',
                onPressed: () {
                  if (ctrl.text.trim().isNotEmpty) {
                    endpointProvider.updateEndpoint(e.id, {'name': ctrl.text.trim()});
                    context.read<WorkspaceTabProvider>().renameTab(
                      'endpoint_${e.id}', WorkspaceTabType.endpoint, ctrl.text.trim());
                  }
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
        onDelete: () {
          PilotDialog.show(
            context: context,
            title: 'Delete Endpoint',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to delete "${e.name}"?',
                  style: AppTypography.body,
                ),
                const SizedBox(height: 8),
                Text(
                  'This action cannot be undone.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            actions: [
              PilotButton.ghost(
                label: 'Cancel',
                onPressed: () => Navigator.of(context).pop(),
              ),
              PilotButton.danger(
                label: 'Delete',
                onPressed: () async {
                  try {
                    await endpointProvider.deleteEndpoint(e.id, projectId);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      PilotToast.show(context, 'Endpoint deleted');
                    }
                  } catch (err) {
                    if (context.mounted) {
                      PilotToast.show(context, 'Error: $err', isError: true);
                    }
                  }
                },
              ),
            ],
          );
        },
      )).toList(),
    );
  }
}

class _FlowList extends StatelessWidget {
  final String searchQuery;
  const _FlowList({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final flowProvider = context.watch<FlowProvider>();
    final flows = flowProvider.flows.where((f) =>
        f.name.toLowerCase().contains(searchQuery)).toList();
    final selectedFlow = flowProvider.selectedFlow;

    void openTab(flow_domain.Flow f) {
      flowProvider.selectFlow(f);
      context.read<WorkspaceTabProvider>().openTab(
        WorkspaceTab(
          id: 'flow_${f.id}',
          name: f.name,
          type: WorkspaceTabType.flow,
          data: f,
        ),
      );
    }

    return Column(
      children: flows.map((f) => _FlowRow(
        flow: f,
        isSelected: selectedFlow?.id == f.id,
        onTap: () => openTab(f),
        onEdit: () {
          FlowDialog.showEditDialog(
            context,
            flow: f,
            onUpdate: (id, name, description) async {
              await flowProvider.updateFlow(
                flowId: id,
                name: name,
                description: description,
              );
              if (context.mounted) {
                context.read<WorkspaceTabProvider>().renameTab(
                  'flow_$id', WorkspaceTabType.flow, name);
              }
            },
          );
        },
        onDelete: () {
          FlowDialog.showDeleteDialog(
            context,
            flow: f,
            onDelete: (id) async {
              await flowProvider.deleteFlow(id);
              if (context.mounted) {
                context.read<WorkspaceTabProvider>().closeTab(
                  WorkspaceTab(id: 'flow_$id', name: '', type: WorkspaceTabType.flow));
              }
            },
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EndpointRow({
    required this.endpoint,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_EndpointRow> createState() => _EndpointRowState();
}

class _EndpointRowState extends State<_EndpointRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final type = widget.endpoint.type.toUpperCase();
    final typeColor = _getTypeColor(type);

    final row = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Container(
            height: AppSpacing.sidebarRowHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm - AppSpacing.xs),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.activeItem
                  : (_isHovered ? AppColors.hoverItem : Colors.transparent),
              borderRadius: AppRadius.br4,
            ),
            child: Row(
              children: [
                _TypeBadge(type: type, color: typeColor),
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
                if (_isHovered) ...[
                  _IconButton(icon: LucideIcons.pencil, onTap: widget.onEdit),
                  _IconButton(icon: LucideIcons.trash2, onTap: widget.onDelete),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return Draggable<DragData>(
      data: DragData(
        type: FlowNodeType.endpoint,
        payload: {
          'id': widget.endpoint.id,
          'name': widget.endpoint.name,
          'method': widget.endpoint.httpMethod,
          'url': widget.endpoint.url,
          'type': widget.endpoint.type,
        },
      ),
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 240,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.elevatedSurface,
            borderRadius: AppRadius.br12,
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.5), width: 2),
            boxShadow: AppShadows.panel,
          ),
          child: Row(
            children: [
              _TypeBadge(type: type, color: typeColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.endpoint.name,
                  style: AppTypography.code.copyWith(color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      dragAnchorStrategy: (draggable, context, position) => const Offset(120, 24),
      childWhenDragging: Opacity(opacity: 0.4, child: row),
      child: row,
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'HTTP': return AppColors.methodGet;
      case 'GRPC': return AppColors.methodPost;
      case 'JDBC': return AppColors.methodPut;
      case 'JS': return AppColors.methodPatch;
      case 'TCP': return AppColors.methodDelete;
      default: return AppColors.textSecondary;
    }
  }
}

class _FlowRow extends StatefulWidget {
  final flow_domain.Flow flow;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FlowRow({
    required this.flow,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_FlowRow> createState() => _FlowRowState();
}

class _FlowRowState extends State<_FlowRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final row = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Container(
            height: AppSpacing.sidebarRowHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm - AppSpacing.xs),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.activeItem
                  : (_isHovered ? AppColors.hoverItem : Colors.transparent),
              borderRadius: AppRadius.br4,
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
                if (_isHovered) ...[
                  _IconButton(icon: LucideIcons.pencil, onTap: widget.onEdit),
                  _IconButton(icon: LucideIcons.trash2, onTap: widget.onDelete),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return Draggable<DragData>(
      data: DragData(
        type: FlowNodeType.subflow,
        payload: {
          'subflowId': widget.flow.id.toString(),
          'flowName': widget.flow.name,
        },
      ),
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 240,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.elevatedSurface,
            borderRadius: AppRadius.br12,
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.5), width: 2),
            boxShadow: AppShadows.panel,
          ),
          child: Row(
            children: [
              Icon(LucideIcons.gitFork, size: 14, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.flow.name,
                  style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      dragAnchorStrategy: (draggable, context, position) => const Offset(120, 24),
      childWhenDragging: Opacity(opacity: 0.4, child: row),
      child: row,
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  final Color color;

  const _TypeBadge({required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          type,
          style: AppTypography.codeSm.copyWith(
            fontSize: 9,
            color: color,
            fontWeight: FontWeight.w600,
          ),
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
