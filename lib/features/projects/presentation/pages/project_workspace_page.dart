import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';
import 'projects_page.dart';

class ProjectWorkspacePage extends StatelessWidget {
  const ProjectWorkspacePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final project = provider.selectedProject;

    if (project == null) {
      return const ProjectsPage();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Workspace - ${project.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Close Project',
            onPressed: () async {
              await provider.clearProject();

              if (!context.mounted) return;

              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const ProjectsPage()),
                );
              } else {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const ProjectsPage()),
                  (_) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Project workspace for "${project.name}"',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
