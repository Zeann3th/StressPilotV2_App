import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/features/environments/presentation/provider/environment_provider.dart';
import 'package:stress_pilot/features/environments/presentation/widgets/environment_table.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';

import 'package:stress_pilot/features/common/presentation/app_topbar.dart';

class EnvironmentPage extends StatefulWidget {
  final int environmentId;
  final String projectName;

  const EnvironmentPage({
    super.key,
    required this.environmentId,
    required this.projectName,
  });

  @override
  State<EnvironmentPage> createState() => _EnvironmentPageState();
}

class _EnvironmentPageState extends State<EnvironmentPage> {
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
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textCol = isDark ? AppColors.textPrimary : AppColors.textLight;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          const AppTopBar(),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: AppRadius.br16,
                border: Border.all(color: border.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: AppRadius.br16,
                child: Column(
                  children: [

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: surface,
                        border: Border(bottom: BorderSide(color: border.withValues(alpha: 0.3))),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: textCol),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Environment: ${widget.projectName}",
                            style: AppTypography.heading.copyWith(color: textCol),
                          ),
                          const Spacer(),
                          _SaveButton(environmentId: widget.environmentId),
                        ],
                      ),
                    ),
                    const Expanded(child: EnvironmentTable()),
                  ],
                ),
              ),
            ),
          ),
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

    return FilledButton.icon(
      onPressed: hasChanges && !provider.isLoading
          ? () async {
              try {
                await provider.saveChanges(environmentId);
                AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
                  const SnackBar(content: Text('Changes saved successfully')),
                );
              } catch (e) {
                AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
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
          : const Icon(Icons.save, size: 18),
      label: const Text('Save Changes'),
    );
  }
}
