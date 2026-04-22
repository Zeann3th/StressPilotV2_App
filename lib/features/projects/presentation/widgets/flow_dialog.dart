import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/features/projects/domain/models/flow.dart' as flow_domain;
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/shared/domain/repositories/utility_repository.dart';
import 'package:stress_pilot/features/shared/presentation/provider/project_provider.dart';

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
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String? selectedType;
    final projectProvider = context.read<ProjectProvider>();
    final projectId = projectProvider.selectedProject?.id;

    if (projectId == null) {
      PilotToast.show(context, 'No project selected', isError: true);
      return;
    }

    PilotDialog.show(
      context: context,
      title: 'New Flow',
      content: StatefulBuilder(
        builder: (context, setState) {
          return FutureBuilder(
            future: getIt<UtilityRepository>().getCapabilities(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final capabilities = snapshot.data;
              final flowTypes = capabilities?.flowExecutors ?? ['DEFAULT'];

              if (selectedType == null && flowTypes.isNotEmpty) {
                selectedType = flowTypes.first;
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel('Flow Name'),
                  const SizedBox(height: 6),
                  PilotInput(
                    controller: nameController,
                    placeholder: 'e.g. Checkout Flow',
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  const _FieldLabel('Type'),
                  const SizedBox(height: 6),
                  _buildDropdown(
                    context: context,
                    value: selectedType ?? 'DEFAULT',
                    items: flowTypes,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const _FieldLabel('Description'),
                  const SizedBox(height: 6),
                  PilotInput(
                    controller: descriptionController,
                    placeholder: 'Optional description...',
                    maxLines: 3,
                  ),
                ],
              );
            },
          );
        },
      ),
      actions: [
        PilotButton.ghost(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        PilotButton.primary(
          label: 'Create',
          onPressed: () async {
            if (nameController.text.trim().isEmpty) {
              PilotToast.show(context, 'Name is required', isError: true);
              return;
            }
            try {
              await onCreate(
                nameController.text.trim(),
                descriptionController.text.trim().isEmpty
                    ? null
                    : descriptionController.text.trim(),
                selectedType ?? 'DEFAULT',
                projectId,
              );
              if (context.mounted) {
                Navigator.of(context).pop();
                PilotToast.show(context, 'Flow created');
              }
            } catch (e) {
              if (context.mounted) {
                PilotToast.show(context, 'Error: $e', isError: true);
              }
            }
          },
        ),
      ],
    );
  }

  static void showEditDialog(
    BuildContext context, {
    required flow_domain.Flow flow,
    required Future<void> Function(int id, String name, String? description)
    onUpdate,
  }) {
    final nameController = TextEditingController(text: flow.name);
    final descriptionController = TextEditingController(
      text: flow.description ?? '',
    );

    PilotDialog.show(
      context: context,
      title: 'Edit Flow',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldLabel('Flow Name'),
          const SizedBox(height: 6),
          PilotInput(
            controller: nameController,
            placeholder: 'e.g. Checkout Flow',
            autofocus: true,
          ),
          const SizedBox(height: 16),
          const _FieldLabel('Description'),
          const SizedBox(height: 6),
          PilotInput(
            controller: descriptionController,
            placeholder: 'Optional description...',
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        PilotButton.ghost(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        PilotButton.primary(
          label: 'Save',
          onPressed: () async {
            if (nameController.text.trim().isEmpty) {
              PilotToast.show(context, 'Name is required', isError: true);
              return;
            }
            try {
              await onUpdate(
                flow.id,
                nameController.text.trim(),
                descriptionController.text.trim().isEmpty
                    ? null
                    : descriptionController.text.trim(),
              );
              if (context.mounted) {
                Navigator.of(context).pop();
                PilotToast.show(context, 'Flow updated');
              }
            } catch (e) {
              if (context.mounted) {
                PilotToast.show(context, 'Error: $e', isError: true);
              }
            }
          },
        ),
      ],
    );
  }

  static void showDeleteDialog(
    BuildContext context, {
    required flow_domain.Flow flow,
    required Future<void> Function(int id) onDelete,
  }) {
    PilotDialog.show(
      context: context,
      title: 'Delete Flow',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to delete "${flow.name}"?',
            style: AppTypography.body,
          ),
          const SizedBox(height: 8),
          Text(
            'This action cannot be undone.',
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
      actions: [
        PilotButton.ghost(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        PilotButton.danger(
          label: 'Delete',
          onPressed: () async {
            try {
              await onDelete(flow.id);
              if (context.mounted) {
                Navigator.of(context).pop();
                PilotToast.show(context, 'Flow deleted');
              }
            } catch (e) {
              if (context.mounted) {
                PilotToast.show(context, 'Error: $e', isError: true);
              }
            }
          },
        ),
      ],
    );
  }

  static Widget _buildDropdown({
    required BuildContext context,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: AppRadius.br8,
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: onChanged,
          dropdownColor: AppColors.surface,
          style: AppTypography.body.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.label.copyWith(color: AppColors.textSecondary),
    );
  }
}
