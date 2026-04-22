import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/features/environments/presentation/provider/environment_provider.dart';
import 'package:stress_pilot/features/environments/presentation/widgets/environment_table.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/shared/presentation/widgets/fleet_page_bar.dart';
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
      backgroundColor: AppColors.baseBackground,
      body: Column(
        children: [
          FleetPageBar(
            title: 'Environment — ${widget.projectName}',
            actions: [_SaveButton(environmentId: widget.environmentId)],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      key: _tableKey,
                      decoration: BoxDecoration(
                        color: AppColors.sidebarBackground,
                        borderRadius: AppRadius.br8,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const ClipRRect(
                        borderRadius: AppRadius.br8,
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
