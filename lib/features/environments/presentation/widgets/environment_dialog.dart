import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/features/environments/presentation/provider/environment_provider.dart';
import 'package:stress_pilot/features/environments/presentation/widgets/environment_table.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/themes/components/components.dart';

import 'package:stress_pilot/core/navigation/app_router.dart';

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
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(48),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.br12,
            side: BorderSide(color: AppColors.border),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: AppRadius.br12,
              border: Border.all(color: AppColors.border),
            ),
            child: EnvironmentManagerDialog(
              environmentId: environmentId,
              projectName: projectName,
            ),
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Environment Variables',
                      style: AppTypography.heading.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Project: ${widget.projectName}',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _SaveButton(environmentId: widget.environmentId),
                const SizedBox(width: 16),
                PilotButton.ghost(
                  icon: LucideIcons.x,
                  onPressed: () => Navigator.of(context).pop(),
                  compact: true,
                ),
              ],
            ),
          ),

          Expanded(child: EnvironmentTable()),
        ],
      ),
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

    return PilotButton.primary(
      icon: LucideIcons.save,
      label: provider.isLoading ? 'Saving...' : 'Save Changes',
      onPressed: hasChanges && !provider.isLoading
          ? () async {
              try {
                await provider.saveChanges(environmentId);
                AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
                  SnackBar(
                    content: const Text('Changes saved successfully'),
                    backgroundColor: AppColors.accent,
                  ),
                );
              } catch (e) {
                AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          : null,
    );
  }
}
