import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/features/common/presentation/app_topbar.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/project/project_dialog.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/project/project_topbar.dart';
import '../../domain/project.dart';
import '../provider/project_provider.dart';
import '../widgets/project/project_table.dart';
import '../widgets/project/project_empty_states.dart';
import 'package:stress_pilot/features/results/data/run_service.dart';
import 'package:stress_pilot/features/results/domain/models/run.dart' as run_model;
import 'package:intl/intl.dart';
import 'package:stress_pilot/core/design/tokens.dart';
import 'package:stress_pilot/core/di/locator.dart';

class ProjectsPage extends StatefulWidget {
  final int? initialFlowId;

  const ProjectsPage({super.key, this.initialFlowId});

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
      body: Column(
        children: [
          // Top global topbar
          AppTopBar(
            searchController: _searchController,
            onSearchSubmitted: _handleSearch,
          ),

          // Split screen: upper half projects, lower half split into left (runs list) and right (analytics)
          Expanded(
            child: Column(
              children: [
                // Upper half: projects area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkSurface
                            : AppColors.lightSurface,
                        border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkBorder.withValues(alpha: 0.3)
                                : AppColors.lightBorder),
                        borderRadius: AppRadius.br16,
                      ),
                      child: ClipRRect(
                        borderRadius: AppRadius.br16,
                        child: Column(
                          children: [
                            // Project topbar controls (import/export/add/refresh)
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
                    ),
                  ),
                ),

                // Lower half: left=recent runs / project details, right=analytics mock
                Container(
                  height: MediaQuery.of(context).size.height * 0.4,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Left: Runs / project details (half width)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkSurface
                                : AppColors.lightSurface,
                            border: Border.all(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkBorder.withValues(alpha: 0.3)
                                    : AppColors.lightBorder),
                            borderRadius: AppRadius.br16,
                          ),
                          child: _RunsPanel(initialFlowId: widget.initialFlowId),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Right: Analytics / charts (mocked)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkSurface
                                : AppColors.lightSurface,
                            border: Border.all(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkBorder.withValues(alpha: 0.3)
                                    : AppColors.lightBorder),
                            borderRadius: AppRadius.br16,
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
                                    style: AppTypography.body.copyWith(
                                        color: AppColors.textSecondary),
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
      builder: (context) =>
          AlertDialog(
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

class _RunsPanel extends StatefulWidget {
  final int? initialFlowId;

  const _RunsPanel({this.initialFlowId});

  @override
  State<_RunsPanel> createState() => _RunsPanelState();
}

class _RunsPanelState extends State<_RunsPanel>
    with SingleTickerProviderStateMixin {
  final _runService = getIt<RunService>();
  List<run_model.Run>? _runs;
  bool _isLoading = false;
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _loadRuns();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadRuns() async {
    setState(() => _isLoading = true);
    try {
      final runs = await _runService.getRuns();
      runs.sort((a, b) => b.id.compareTo(a.id));
      final int? filterFlowId = widget.initialFlowId;
      final List<run_model.Run> filtered = filterFlowId == null
          ? runs
          : runs.where((r) => r.flowId == filterFlowId).toList();
      if (mounted) setState(() => _runs = filtered);
      _ctrl.forward();
    } catch (e) {
      AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Failed to load runs: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleRunTap(run_model.Run run) {
    final status = run.status.toUpperCase();
    if (status == 'RUNNING') {
      AppNavigator.pushNamed(
          AppRouter.resultsRoute, arguments: {'runId': run.id});
    } else if (status == 'COMPLETED') {
      _exportRun(run);
    }
  }

  Future<void> _exportRun(run_model.Run run) async {
    try {
      final file = await _runService.exportRun(run);
      if (file == null) {
        AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(const SnackBar(
            content: Text('Export returned empty'),
            backgroundColor: Colors.orange));
      } else {
        AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
            content: Text('Exported to ${file.path}'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
        content: Text('Export failed: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Opacity(
          opacity: _ctrl.value,
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: AppRadius.br12,
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.06), blurRadius: 12),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Recent Runs',
                    style: AppTypography.heading.copyWith(fontSize: 16)),
                const Spacer(),
                IconButton(
                  onPressed: _loadRuns,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : (_runs == null || _runs!.isEmpty)
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_disabled_rounded, size: 28,
                        color: AppColors.textMuted),
                    const SizedBox(height: 8),
                    Text('No runs yet', style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary)),
                  ],
                ),
              )
                  : ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _runs!.length,
                separatorBuilder: (context, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final r = _runs![index];
                  final status = r.status.toUpperCase();
                  final (statusColor, statusIcon) = _statusAppearance(status);
                  return GestureDetector(
                    onTap: () => _handleRunTap(r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 300,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkElevated : Colors.white,
                        borderRadius: AppRadius.br8,
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(statusIcon, color: statusColor),
                              const SizedBox(width: 8),
                              Text('Run #${r.id}',
                                  style: AppTypography.bodyLg.copyWith(
                                      fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Text(status,
                                  style: AppTypography.caption.copyWith(
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Flow ${r.flowId}',
                              style: AppTypography.caption.copyWith(
                                  color: AppColors.textMuted)),
                          const Spacer(),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  DateFormat('yyyy-MM-dd HH:mm').format(
                                      r.startedAt.toLocal()),
                                  style: AppTypography.caption.copyWith(
                                      color: AppColors.textMuted),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (status == 'COMPLETED')
                                IconButton(
                                  onPressed: () => _exportRun(r),
                                  icon: const Icon(
                                      Icons.download_rounded, size: 18),
                                ),
                              if (status == 'RUNNING')
                                IconButton(
                                  onPressed: () =>
                                      AppNavigator.pushNamed(
                                      AppRouter.resultsRoute,
                                      arguments: {'runId': r.id}),
                                  icon: const Icon(
                                      Icons.chevron_right_rounded, size: 18),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  (Color, IconData) _statusAppearance(String status) {
    switch (status) {
      case 'RUNNING':
        return (const Color(0xFF3B82F6), Icons.play_circle_outline_rounded);
      case 'COMPLETED':
        return (AppColors.accent, Icons.check_circle_outline_rounded);
      case 'FAILED':
        return (AppColors.error, Icons.error_outline_rounded);
      default:
        return (AppColors.textMuted, Icons.help_outline_rounded);
    }
  }
}

