import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/environment_provider.dart';
import 'package:stress_pilot/features/common/presentation/widgets/environment_table.dart';

class EnvironmentManagerDialog extends StatefulWidget {
  final int environmentId;
  final String projectName;

  const EnvironmentManagerDialog({
    super.key,
    required this.environmentId,
    required this.projectName,
  });

  static Future<void> show(
    BuildContext context,
    int environmentId,
    String projectName,
  ) {
    final provider = Provider.of<EnvironmentProvider>(context, listen: false);

    return showDialog(
      context: context,
      builder: (context) => ChangeNotifierProvider.value(
        value: provider,
        child: Dialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(48), // Large dialog
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: EnvironmentManagerDialog(
            environmentId: environmentId,
            projectName: projectName,
          ),
        ),
      ),
    );
  }

  @override
  State<EnvironmentManagerDialog> createState() =>
      _EnvironmentManagerDialogState();
}

class _EnvironmentManagerDialogState extends State<EnvironmentManagerDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EnvironmentProvider>().loadVariables(widget.environmentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.outlineVariant)),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Environment Variables',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Project: ${widget.projectName}',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _SaveButton(environmentId: widget.environmentId),
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(Icons.close, color: colors.onSurface),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),

        const Expanded(child: EnvironmentTable()),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  final int environmentId;
  const _SaveButton({required this.environmentId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EnvironmentProvider>();
    final hasChanges = provider.hasChanges;
    final colors = Theme.of(context).colorScheme;

    return FilledButton.icon(
      onPressed: hasChanges && !provider.isLoading
          ? () async {
              try {
                await provider.saveChanges(environmentId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Changes saved successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: colors.error,
                    ),
                  );
                }
              }
            }
          : null,
      icon: provider.isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(CupertinoIcons.floppy_disk, size: 18),
      label: const Text('Save Changes'),
      style: FilledButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
      ),
    );
  }
}
