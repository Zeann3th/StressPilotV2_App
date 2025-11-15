import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/features/common/presentation/app_sidebar.dart';
import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/features/projects/domain/flow.dart' as flow;
import 'package:stress_pilot/features/projects/presentation/widgets/workspace_topbar.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/workspace_sidebar.dart';
import 'projects_page.dart';

class ProjectWorkspacePage extends StatefulWidget {
  const ProjectWorkspacePage({super.key});

  @override
  State<ProjectWorkspacePage> createState() => _ProjectWorkspacePageState();
}

class _ProjectWorkspacePageState extends State<ProjectWorkspacePage> {
  flow.Flow? _selectedFlow;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final projectProvider = context.read<ProjectProvider>();
      final flowProvider = context.read<FlowProvider>();

      // Load projects
      projectProvider.loadProjects();

      // Load flows if a project is already selected
      if (projectProvider.selectedProject != null) {
        flowProvider.loadFlows(projectId: projectProvider.selectedProject!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final projectProvider = context.watch<ProjectProvider>();
    final project = projectProvider.selectedProject;
    final colors = Theme.of(context).colorScheme;

    // If no project selected, navigate to ProjectsPage
    if (project == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProjectsPage()),
        );
      });
      // Return placeholder while navigating
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: colors.surface,
      body: Row(
        children: [
          const AppSidebar(),
          Expanded(
            child: Column(
              children: [
                const WorkspaceTopBar(),
                Expanded(
                  child: Row(
                    children: [
                      WorkspaceSidebar(
                        onFlowSelected: (flow) {
                          setState(() {
                            _selectedFlow = flow;
                          });
                          context.read<FlowProvider>().selectFlow(flow);
                        },
                      ),
                      Expanded(child: _buildCanvas()),
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

  Widget _buildCanvas() {
    final colors = Theme.of(context).colorScheme;

    if (_selectedFlow == null) {
      return Container(
        color: colors.surface,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.layers_outlined,
                size: 64,
                color: colors.onSurfaceVariant.withAlpha(128),
              ),
              const SizedBox(height: 16),
              Text(
                'Select a flow to get started',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Or create a new flow from the sidebar',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant.withAlpha(180),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: colors.surface,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Flow header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedFlow!.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (_selectedFlow!.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _selectedFlow!.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Configure coming soon')),
                  );
                },
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: const Text('Configure'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Run coming soon')),
                  );
                },
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Run'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Canvas area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.outlineVariant, width: 1),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.construction_outlined,
                      size: 64,
                      color: colors.onSurfaceVariant.withAlpha(128),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Flow canvas coming soon',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This is where you\'ll configure and visualize your flow',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant.withAlpha(180),
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
}
