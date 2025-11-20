import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/endpoint_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/features/projects/presentation/pages/projects_page.dart';

class WorkspaceTopBar extends StatelessWidget {
  const WorkspaceTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final provider = context.watch<ProjectProvider>();
    final project = provider.selectedProject;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Left: Project Selector Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 48),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: colors.outline.withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder_outlined,
                      color: colors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      project?.name ?? 'No Project',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      color: colors.onSurface,
                      size: 20,
                    ),
                  ],
                ),
              ),
              itemBuilder: (context) {
                final items = <PopupMenuEntry<String>>[];

                // Add "View All Projects" option first
                items.add(
                  PopupMenuItem<String>(
                    value: 'view_all',
                    child: Row(
                      children: [
                        Icon(Icons.apps, size: 18, color: colors.primary),
                        const SizedBox(width: 12),
                        const Text('View All Projects'),
                      ],
                    ),
                  ),
                );

                // Add divider if there are projects
                if (provider.projects.isNotEmpty) {
                  items.add(const PopupMenuDivider());
                }

                // Add all projects
                for (final proj in provider.projects) {
                  final isSelected = proj.id == project?.id;
                  items.add(
                    PopupMenuItem<String>(
                      value: 'project_${proj.id}',
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.folder_outlined,
                            size: 18,
                            color: isSelected
                                ? colors.primary
                                : colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              proj.name,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected ? colors.primary : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return items;
              },
              onSelected: (value) {
                if (value == 'view_all') {
                  _handleViewAllProjects(context);
                } else if (value.startsWith('project_')) {
                  _handleProjectSelection(context, value, provider);
                }
              },
            ),
          ),

          const Spacer(),

          // Right: Environment Button
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Navigate to environment page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Environment page coming soon')),
                );
              },
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: const Text('Environment'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleViewAllProjects(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ProjectsPage()),
    );

    final provider = context.read<ProjectProvider>();
    provider.clearProject();
  }


  void _handleProjectSelection(
    BuildContext context,
    String value,
    ProjectProvider provider,
  ) {
    final projectId = int.parse(value.substring(8));
    final selectedProj = provider.projects.firstWhere((p) => p.id == projectId);
    provider.selectProject(selectedProj);

    // Refetch flows and endpoints
    final flowProvider = context.read<FlowProvider>();
    final endpointProvider = context.read<EndpointProvider>();

    flowProvider.loadFlows(projectId: projectId);
    endpointProvider.loadEndpoints(projectId: projectId);
  }
}
