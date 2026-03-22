import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/utils/tutorial_helper.dart';
import 'package:stress_pilot/features/shared/presentation/widgets/app_topbar.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/project/project_dialog.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/project/project_topbar.dart';
import 'package:stress_pilot/features/projects/domain/models/project.dart';
import '../provider/project_provider.dart';
import '../widgets/project/project_table.dart';
import '../widgets/project/project_empty_states.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/runs_list_widget.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';

class ProjectsPage extends StatefulWidget {
  final int? initialFlowId;

  const ProjectsPage({super.key, this.initialFlowId});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _topBarKey = GlobalKey();
  final GlobalKey _analyticsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectProvider>().loadProjects();
      _showTutorial();
    });
  }

  void _showTutorial() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      TutorialHelper.showTutorialIfFirstTime(
        context: context,
        prefKey: 'tutorial_projects',
        targets: [
          TargetFocus(
            identify: "ProjectTopBar",
            keyTarget: _topBarKey,
            shape: ShapeLightFocus.RRect,
            alignSkip: Alignment.topRight,
            contents: [
              TargetContent(
                align: ContentAlign.bottom,
                builder: (context, controller) {
                  return const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Manage Projects",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Here you can create, import, export, and search your projects.",
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          TargetFocus(
            identify: "AnalyticsPanel",
            keyTarget: _analyticsKey,
            shape: ShapeLightFocus.RRect,
            alignSkip: Alignment.topRight,
            contents: [
              TargetContent(
                align: ContentAlign.top,
                builder: (context, controller) {
                  return const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Analytics Dashboard",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "View realtime charts and KPIs of your stress tests here.",
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          AppTopBar(
            searchController: _searchController,
            onSearchSubmitted: _handleSearch,
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
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
              child: ClipRRect(
                borderRadius: AppRadius.br16,
                child: Column(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          ProjectTopBar(
                            key: _topBarKey,
                            searchController: _searchController,
                            onRefresh: _handleRefresh,
                            onAdd: _handleCreate,
                            onImport: _handleImport,
                            onExport: _handleExport,
                            onSearchSubmitted: _handleSearch,
                            onSearchChanged: () => setState(() {}),
                          ),
                          Expanded(child: _buildMainContent()),
                        ],
                      ),
                    ),
                    Container(
                      key: _analyticsKey,
                      height: MediaQuery.of(context).size.height * 0.4,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: border.withValues(alpha: 0.3))),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkElevated : Colors.white,
                                border: Border.all(color: border.withValues(alpha: 0.3)),
                                borderRadius: AppRadius.br12,
                              ),
                              child: ClipRRect(
                                borderRadius: AppRadius.br12,
                                child: RunsListWidget(flowId: widget.initialFlowId),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkElevated : Colors.white,
                                border: Border.all(color: border.withValues(alpha: 0.3)),
                                borderRadius: AppRadius.br12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Analytics', style: AppTypography.heading),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        'Charts and KPIs will appear here (mock)',
                                        style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                                      ),
                                    ),
                                  ),
                                ],
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

  Widget _buildMainContent() {
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return ProjectErrorState(
            error: provider.error!,
            onRetry: () => provider.loadProjects(),
          );
        }

        if (provider.projects.isEmpty) {
          return const ProjectEmptyState();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ProjectTable(
            projects: provider.projects,
            onProjectTap: _handleProjectTap,
            onEdit: _handleEdit,
            onDelete: _handleDelete,
          ),
        );
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

  void _handleCreate() {
    ProjectDialogs.showCreateDialog(
      context,
      onCreate: (name, description) async {
        await context.read<ProjectProvider>().createProject(
          name: name,
          description: description,
        );
      },
    );
  }

  void _handleEdit(Project project) {
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

  void _handleDelete(Project project) {
    ProjectDialogs.showDeleteDialog(
      context,
      project: project,
      onDelete: (id) async {
        await context.read<ProjectProvider>().deleteProject(id);
      },
    );
  }

  Future<void> _handleProjectTap(Project project) async {
    await context.read<ProjectProvider>().selectProject(project);
    AppNavigator.pushReplacementNamed(AppRouter.workspaceRoute);
  }

  Future<void> _handleImport() async {
    try {
      await context.read<ProjectProvider>().importProject();
      AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Project imported successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Failed to import project: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleExport() async {
    final provider = context.read<ProjectProvider>();

    if (provider.projects.isEmpty) {
      AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('No projects available to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedProject = await showDialog<Project>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Project to Export'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: provider.projects.length,
            itemBuilder: (context, index) {
              final project = provider.projects[index];
              return ListTile(
                title: Text(project.name),
                subtitle: Text(project.description),
                onTap: () => Navigator.of(context).pop(project),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedProject == null) return;

    try {
      await provider.exportProject(selectedProject.id, selectedProject.name);
      AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Project exported successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Failed to export project: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
