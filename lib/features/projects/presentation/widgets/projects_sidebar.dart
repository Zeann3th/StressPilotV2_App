import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/projects/domain/models/project.dart';
import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/project_dialog.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/features/shared/presentation/widgets/sidebar_section_header.dart';

class ProjectsSidebar extends StatefulWidget {
  const ProjectsSidebar({super.key});

  @override
  State<ProjectsSidebar> createState() => _ProjectsSidebarState();
}

class _ProjectsSidebarState extends State<ProjectsSidebar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: const Column(
        children: [
          Expanded(
            child: _ProjectsList(),
          ),
        ],
      ),
    );
  }
}

class _ProjectsList extends StatelessWidget {
  const _ProjectsList();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final projects = provider.projects;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: SidebarSectionHeader(
            label: 'PROJECTS',
            isExpanded: true,
            onToggle: () {}, // Projects list always expanded for now
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SidebarIconButton(
                  icon: LucideIcons.upload,
                  tooltip: 'Import Project',
                  onTap: () => provider.importProject(),
                ),
                const SizedBox(width: 4),
                _SidebarIconButton(
                  icon: LucideIcons.download,
                  tooltip: 'Export Selected Project',
                  onTap: provider.selectedProject == null
                      ? null
                      : () => provider.exportProject(
                          provider.selectedProject!.id,
                          provider.selectedProject!.name),
                ),
                const SizedBox(width: 4),
                _SidebarIconButton(
                  icon: LucideIcons.plus,
                  tooltip: 'New Project',
                  onTap: () => _showCreateDialog(context),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 12, right: 4),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final p = projects[index];
              return _ProjectSidebarRow(
                project: p,
                isSelected: provider.selectedProject?.id == p.id,
                onTap: () => provider.selectProject(p),
                onEdit: () => _showEditDialog(context, p),
                onDelete: () => _showDeleteDialog(context, p),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCreateDialog(BuildContext context) {
    ProjectDialogs.showCreateDialog(
      context,
      onCreate: (name, description) async {
        final provider = context.read<ProjectProvider>();
        await provider.createProject(name: name, description: description);
      },
    );
  }

  void _showEditDialog(BuildContext context, Project project) {
    ProjectDialogs.showEditDialog(
      context,
      project: project,
      onUpdate: (id, name, description) async {
        await context.read<ProjectProvider>().updateProject(
          projectId: id,
          name: name,
          description: description,
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, Project project) {
    ProjectDialogs.showDeleteDialog(
      context,
      project: project,
      onDelete: (id) async {
        await context.read<ProjectProvider>().deleteProject(id);
      },
    );
  }
}

class _ProjectSidebarRow extends StatefulWidget {
  final Project project;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProjectSidebarRow({
    required this.project,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_ProjectSidebarRow> createState() => _ProjectSidebarRowState();
}

class _ProjectSidebarRowState extends State<_ProjectSidebarRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onTap();
          });
        },
        onDoubleTap: () {
          widget.onTap();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              AppNavigator.pushReplacementNamed(AppRouter.workspaceRoute);
            }
          });
        },
        child: Container(
          height: AppSpacing.sidebarRowHeight,
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.activeItem
                : (_isHovered ? AppColors.hoverItem : Colors.transparent),
            borderRadius: AppRadius.br4,
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.folder,
                size: 14,
                color: widget.isSelected ? AppColors.accent : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.project.name,
                  style: AppTypography.body.copyWith(
                    color: widget.isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_isHovered) ...[
                _SidebarIconButton(
                  icon: LucideIcons.pencil,
                  onTap: widget.onEdit,
                  size: 20,
                  iconSize: 12,
                ),
                _SidebarIconButton(
                  icon: LucideIcons.trash2,
                  onTap: widget.onDelete,
                  size: 20,
                  iconSize: 12,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;
  final double iconSize;

  const _SidebarIconButton({
    required this.icon,
    this.onTap,
    this.tooltip,
    this.size = 24,
    this.iconSize = 14,
  });

  @override
  State<_SidebarIconButton> createState() => _SidebarIconButtonState();
}

class _SidebarIconButtonState extends State<_SidebarIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Widget child = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.hoverItem : Colors.transparent,
            borderRadius: AppRadius.br4,
          ),
          child: Icon(
            widget.icon,
            size: widget.iconSize,
            color: _isHovered ? AppColors.accent : AppColors.textSecondary,
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: child);
    }
    return child;
  }
}
