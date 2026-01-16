import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';

class ProjectSelectionDialog extends StatefulWidget {
  const ProjectSelectionDialog({super.key});

  @override
  State<ProjectSelectionDialog> createState() => _ProjectSelectionDialogState();
}

class _ProjectSelectionDialogState extends State<ProjectSelectionDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectProvider>().loadProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Project',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            Expanded(
              child: Consumer<ProjectProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.projects.isEmpty) {
                    return Center(
                      child: Text(
                        'No projects found.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: provider.projects.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final project = provider.projects[index];
                      return ListTile(
                        title: Text(project.name),
                        subtitle: Text(project.description),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(context, project);
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
