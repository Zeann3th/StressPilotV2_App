import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/features/common/presentation/app_sidebar.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/project/project_dialog.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/project/project_topbar.dart';
import '../../domain/project.dart';
import '../provider/project_provider.dart';
import '../widgets/project/project_table.dart';
import '../widgets/project/project_empty_states.dart';

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
                  onImport: _handleImport,
                  onExport: _handleExport,
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
    AppNavigator.pushReplacementNamed(AppRouter.workspaceRoute);
  }

  Future<void> _handleImport() async {
    try {
      await context.read<ProjectProvider>().importProject();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project imported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import project: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleExport() async {
    final provider = context.read<ProjectProvider>();
    
    if (provider.projects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No projects available to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show dialog to select which project to export
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project exported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export project: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
