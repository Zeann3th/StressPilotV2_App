import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/features/environments/presentation/provider/environment_provider.dart';
import 'package:stress_pilot/features/environments/presentation/widgets/environment_table.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/shared/presentation/widgets/fleet_page_bar.dart';

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
          const FleetPageBar(
            title: 'Environment Settings',
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
