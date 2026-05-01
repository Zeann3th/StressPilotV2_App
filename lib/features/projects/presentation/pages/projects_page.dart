import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/recent_pages_widget.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/runs_list_widget.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/project/project_dialog.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/project/project_table.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/project/project_topbar.dart';
import 'package:stress_pilot/features/projects/domain/models/project.dart';

import 'package:stress_pilot/features/projects/presentation/widgets/dashboard_top_bar.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProjectProvider>().loadProjects();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onNewProject() {
    ProjectDialogs.showCreateDialog(
      context,
      onCreate: (name, description) async {
        final provider = context.read<ProjectProvider>();
        final project = await provider.createProject(
          name: name,
          description: description,
        );
        await provider.selectProject(project);
        AppNavigator.pushReplacementNamed(AppRouter.workspaceRoute);
      },
    );
  }

  Future<void> _onProjectTap(Project project) async {
    final provider = context.read<ProjectProvider>();
    await provider.selectProject(project);
    AppNavigator.pushReplacementNamed(AppRouter.workspaceRoute);
  }

  void _onEditProject(Project project) {
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

  void _onDeleteProject(Project project) {
    ProjectDialogs.showDeleteDialog(
      context,
      project: project,
      onDelete: (id) async {
        await context.read<ProjectProvider>().deleteProject(id);
      },
    );
  }

  void _handleRefresh() {
    context.read<ProjectProvider>().loadProjects(
      searchName: _searchController.text,
    );
  }

  void _handleSearch(String query) {
    context.read<ProjectProvider>().loadProjects(searchName: query);
  }

  Future<void> _handleImport() async {
    try {
      await context.read<ProjectProvider>().importProject();
      if (mounted) {
        PilotToast.show(context, 'Project imported successfully');
      }
    } catch (e) {
      if (mounted) {
        PilotToast.show(context, 'Failed to import project: $e', isError: true);
      }
    }
  }

  Future<void> _handleExport() async {
    final provider = context.read<ProjectProvider>();

    if (provider.projects.isEmpty) {
      PilotToast.show(context, 'No projects available to export', isError: true);
      return;
    }

    final selectedProject = await PilotDialog.show<Project>(
      context: context,
      title: 'Select Project to Export',
      maxWidth: 400,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 300),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: provider.projects.length,
          itemBuilder: (context, index) {
            final project = provider.projects[index];
            return ListTile(
              title: Text(project.name, style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary)),
              subtitle: Text(
                project.description,
                style: AppTypography.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => Navigator.of(context).pop(project),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.br8),
              hoverColor: AppColors.accent.withValues(alpha: 0.1),
            );
          },
        ),
      ),
      actions: [
        PilotButton.ghost(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );

    if (selectedProject == null) return;

    try {
      await provider.exportProject(selectedProject.id, selectedProject.name);
      if (mounted) {
        PilotToast.show(context, 'Project exported successfully');
      }
    } catch (e) {
      if (mounted) {
        PilotToast.show(context, 'Failed to export project: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final border = AppColors.divider;

    return Scaffold(
      backgroundColor: AppColors.baseBackground,
      body: Column(
        children: [
          const DashboardTopBar(),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                color: AppColors.sidebarBackground,
                borderRadius: AppRadius.br16,
                border: Border.all(color: border),
              ),
              child: ClipRRect(
                borderRadius: AppRadius.br16,
                child: Column(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          ProjectTopBar(
                            searchController: _searchController,
                            onRefresh: _handleRefresh,
                            onAdd: _onNewProject,
                            onImport: _handleImport,
                            onExport: _handleExport,
                            onSearchSubmitted: _handleSearch,
                            onSearchChanged: () => setState(() {}),
                          ),
                          Expanded(
                            child: _buildMainTable(provider),
                          ),
                        ],
                      ),
                    ),
                    
                    // Analytics / Recent Activity Footer
                    Container(
                      height: MediaQuery.of(context).size.height * 0.35,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: border)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _PanelContainer(
                              child: const RunsListWidget(flowId: null),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _PanelContainer(
                              child: const Padding(
                                padding: EdgeInsets.all(16),
                                child: RecentPagesWidget(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTable(ProjectProvider provider) {
    if (provider.isLoading && provider.projects.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: PilotSkeleton(height: double.infinity, width: double.infinity),
      );
    }

    if (provider.projects.isEmpty) {
      return Center(
        child: Text(
          'No projects found. Create one to get started.',
          style: AppTypography.body.copyWith(color: AppColors.textMuted),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ProjectTable(
        projects: provider.projects,
        onProjectTap: _onProjectTap,
        onEdit: _onEditProject,
        onDelete: _onDeleteProject,
      ),
    );
  }
}

class _PanelContainer extends StatelessWidget {
  final Widget child;

  const _PanelContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sidebarBackground,
        borderRadius: AppRadius.br6,
        border: Border.all(color: AppColors.divider),
      ),
      child: child,
    );
  }
}

