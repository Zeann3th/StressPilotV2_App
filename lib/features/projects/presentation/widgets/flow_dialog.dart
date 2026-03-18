import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/domain/entities/flow.dart' as flow_domain;
import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/features/common/data/utility_service.dart';

class FlowDialog {
  static void showCreateDialog(
    BuildContext context, {
    required Future<void> Function(
      String name,
      String? description,
      String type,
      int projectId,
    )
    onCreate,
  }) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String? selectedType;
    final projectProvider = context.read<ProjectProvider>();
    final projectId = projectProvider.selectedProject?.id;

    if (projectId == null) {
      AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('No project selected')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Create Flow'),
            content: SizedBox(
              width: 600,
              child: FutureBuilder(
                future: getIt<UtilityService>().getCapabilities(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final capabilities = snapshot.data;
                  final flowTypes = capabilities?.flowExecutors ?? ['DEFAULT'];
                  
                  if (selectedType == null && flowTypes.isNotEmpty) {
                    selectedType = flowTypes.first;
                  }

                  return Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            hintText: 'Enter flow name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Name is required';
                            }
                            return null;
                          },
                          autofocus: true,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(),
                          ),
                          items: flowTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => selectedType = value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description (optional)',
                            hintText: 'Enter flow description',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(dialogContext).pop();

                    try {
                      await onCreate(
                        nameController.text.trim(),
                        descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                        selectedType ?? 'DEFAULT',
                        projectId,
                      );

                      AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
                        const SnackBar(
                          content: Text('Flow created successfully'),
                        ),
                      );
                    } catch (e) {
                      AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  }
                },
                child: const Text('Create'),
              ),
            ],
          );
        }
      ),
    );
  }

  static void showEditDialog(
    BuildContext context, {
    required flow_domain.Flow flow,
    required Future<void> Function(int id, String name, String? description)
    onUpdate,
  }) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: flow.name);
    final descriptionController = TextEditingController(
      text: flow.description ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Flow'),
        content: SizedBox(
          width: 600,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Enter flow name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Enter flow description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.of(dialogContext).pop();

                try {
                  await onUpdate(
                    flow.id,
                    nameController.text.trim(),
                    descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                  );

                  AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
                    const SnackBar(
                      content: Text('Flow updated successfully'),
                    ),
                  );
                } catch (e) {
                  AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  static void showDeleteDialog(
    BuildContext context, {
    required flow_domain.Flow flow,
    required Future<void> Function(int id) onDelete,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Flow'),
        content: Text(
          'Are you sure you want to delete "${flow.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();

              try {
                await onDelete(flow.id);

                AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
                  const SnackBar(content: Text('Flow deleted successfully')),
                );
              } catch (e) {
                AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
