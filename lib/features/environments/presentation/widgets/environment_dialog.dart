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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog(
      context: context,
      builder: (context) => ChangeNotifierProvider.value(
        value: provider,
        child: Dialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(48), // Large dialog
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.br12,
            side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
              borderRadius: AppRadius.br12,
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Environment Variables',
                      style: AppTypography.heading.copyWith(
                        color: isDark ? AppColors.textPrimary : AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Project: ${widget.projectName}',
                      style: AppTypography.body.copyWith(
                        color: isDark ? AppColors.textSecondary : AppColors.textLightSecondary,
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

          const Expanded(child: EnvironmentTable()),
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
                  const SnackBar(
                    content: Text('Changes saved successfully'),
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
