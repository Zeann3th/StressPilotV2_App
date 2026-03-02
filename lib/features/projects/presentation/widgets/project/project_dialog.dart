import 'package:flutter/material.dart';
import 'package:stress_pilot/core/design/components.dart';
import 'package:stress_pilot/core/design/tokens.dart';
import 'package:stress_pilot/features/projects/domain/project.dart';

class ProjectDialogs {
  static void showCreateDialog(
    BuildContext context, {
    required Future<void> Function(String name, String description) onCreate,
  }) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    PilotDialog.show(
      context: context,
      title: 'New Project',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel('Project Name'),
          const SizedBox(height: 6),
          PilotInput(
            controller: nameController,
            placeholder: 'My Load Test',
            autofocus: true,
          ),
          const SizedBox(height: 16),
          _FieldLabel('Description'),
          const SizedBox(height: 6),
          PilotInput(
            controller: descController,
            placeholder: 'Optional description...',
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        PilotButton.ghost(
          label: 'Cancel',
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        PilotButton.primary(
          label: 'Create',
          onPressed: () async {
            if (nameController.text.trim().isEmpty) {
              PilotToast.show(context, 'Please enter a project name', isError: true);
              return;
            }
            try {
              await onCreate(
                nameController.text.trim(),
                descController.text.trim(),
              );
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pop();
                PilotToast.show(context, 'Project created');
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
    required Project project,
    required Future<void> Function(int id, String name, String description) onUpdate,
  }) {
    final nameController = TextEditingController(text: project.name);
    final descController = TextEditingController(text: project.description);

    PilotDialog.show(
      context: context,
      title: 'Edit Project',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel('Project Name'),
          const SizedBox(height: 6),
          PilotInput(
            controller: nameController,
            placeholder: 'My Load Test',
            autofocus: true,
          ),
          const SizedBox(height: 16),
          _FieldLabel('Description'),
          const SizedBox(height: 6),
          PilotInput(
            controller: descController,
            placeholder: 'Optional description...',
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        PilotButton.ghost(
          label: 'Cancel',
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        PilotButton.primary(
          label: 'Save',
          onPressed: () async {
            if (nameController.text.trim().isEmpty) {
              PilotToast.show(context, 'Please enter a project name', isError: true);
              return;
            }
            try {
              await onUpdate(
                project.id,
                nameController.text.trim(),
                descController.text.trim(),
              );
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pop();
                PilotToast.show(context, 'Project updated');
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
    required Project project,
    required Future<void> Function(int id) onDelete,
  }) {
    PilotDialog.show(
      context: context,
      title: 'Delete Project',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to delete',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            '"${project.name}"?',
            style: AppTypography.bodyLg.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
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
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        PilotButton.danger(
          label: 'Delete',
          onPressed: () async {
            try {
              await onDelete(project.id);
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pop();
                PilotToast.show(context, 'Project deleted');
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
