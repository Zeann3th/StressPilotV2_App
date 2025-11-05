import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/features/common/presentation/app_sidebar.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/project_dialog.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/project_topbar.dart';
import '../../domain/project.dart';
import '../provider/project_provider.dart';
import '../widgets/project_table.dart';
import '../widgets/project_empty_states.dart';
import 'project_workspace_page.dart';

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
      context.read<ProjectProvider>().loadProjects();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Row(
        children: [
          const AppSidebar(),
          Expanded(
            child: Column(
              children: [
                ProjectTopBar(
                  searchController: _searchController,
                  onRefresh: _handleRefresh,
                  onAdd: _handleCreate,
                  onSearchSubmitted: _handleSearch,
                  onSearchChanged: () => setState(() {}),
                ),
                Expanded(child: _buildMainContent()),
              ],
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
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProjectWorkspacePage()),
      );
    }
  }
}
