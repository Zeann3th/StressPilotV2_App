import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/common/presentation/provider/endpoint_provider.dart';
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
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Flat Project Selector
          PopupMenuButton<String>(
            offset: const Offset(0, 48),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_open, color: colors.onSurface, size: 20),
                const SizedBox(width: 8),
                Text(
                  project?.name ?? 'Select Project',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: colors.onSurfaceVariant,
                  size: 18,
                ),
              ],
            ),
            itemBuilder: (context) {
              final items = <PopupMenuEntry<String>>[];
              items.add(
                PopupMenuItem<String>(
                  value: 'view_all',
                  child: const Text('All Projects'),
                ),
              );
              if (provider.projects.isNotEmpty) {
                items.add(const PopupMenuDivider());
              }
              for (final proj in provider.projects) {
                items.add(
                  PopupMenuItem<String>(
                    value: 'project_${proj.id}',
                    child: Text(
                      proj.name,
                      style: TextStyle(
                        fontWeight: proj.id == project?.id
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
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

          const Spacer(),

          // Minimalist Action Buttons
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Environment settings coming soon'),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colors.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            child: Text(
              "Environment",
              style: TextStyle(color: colors.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  void _handleViewAllProjects(BuildContext context) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const ProjectsPage()));
    context.read<ProjectProvider>().clearProject();
  }

  void _handleProjectSelection(
    BuildContext context,
    String value,
    ProjectProvider provider,
  ) {
    final projectId = int.parse(value.substring(8));
    final selectedProj = provider.projects.firstWhere((p) => p.id == projectId);
    provider.selectProject(selectedProj);

    context.read<FlowProvider>().loadFlows(projectId: projectId);
    context.read<EndpointProvider>().loadEndpoints(projectId: projectId);
  }
}
