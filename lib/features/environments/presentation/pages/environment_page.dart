import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/features/environments/presentation/provider/environment_provider.dart';
import 'package:stress_pilot/features/environments/presentation/widgets/environment_table.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/shared/presentation/widgets/app_topbar.dart';
import 'package:stress_pilot/core/themes/components/components.dart';

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
  final GlobalKey _headerKey = GlobalKey();
  final GlobalKey _tableKey = GlobalKey();

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
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const AppTopBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    key: _headerKey,
                    children: [
                      PilotButton.ghost(
                        icon: Icons.arrow_back_rounded,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Environment Variables",
                            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                          ),
                          Text(
                            widget.projectName,
                            style: AppTypography.title.copyWith(color: AppColors.textPrimary, fontSize: 22),
                          ),
                        ],
                      ),
                      const Spacer(),
                      _SaveButton(environmentId: widget.environmentId),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Container(
                      key: _tableKey,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.br16,
                        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            offset: const Offset(0, 4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const ClipRRect(
                        borderRadius: AppRadius.br16,
                        child: EnvironmentTable(),
                      ),
                    ),
                  ),
                ],
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

    return PilotButton.primary(
      onPressed: hasChanges && !provider.isLoading
          ? () async {
              try {
                await provider.saveChanges(environmentId);
                if (context.mounted) {
                  PilotToast.show(context, 'Changes saved successfully');
                }
              } catch (e) {
                if (context.mounted) {
                  PilotToast.show(context, 'Error: $e', isError: true);
                }
              }
            }
          : null,
      icon: provider.isLoading ? null : Icons.check_rounded,
      label: provider.isLoading ? 'Saving...' : 'Save Changes',
    );
  }
}
