import 'package:flutter/material.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/runs_list_widget.dart';
import 'package:stress_pilot/features/shared/presentation/widgets/fleet_page_bar.dart';

class RecentRunsPage extends StatelessWidget {
  const RecentRunsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.baseBackground,
      body: Column(
        children: [
          const FleetPageBar(title: 'Recent Runs', showBack: true),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.baseBackground,
                  borderRadius: AppRadius.br12,
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.panel,
                ),
                clipBehavior: Clip.antiAlias,
                child: const RunsListWidget(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
