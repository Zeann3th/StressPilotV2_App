import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/runs_list_widget.dart';

class RecentRunsPage extends StatelessWidget {
  const RecentRunsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.baseBackground,
      appBar: AppBar(
        backgroundColor: AppColors.sidebarBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, size: 16, color: AppColors.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Recent Runs', style: AppTypography.heading),
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.divider),
        ),
      ),
      body: const RunsListWidget(),
    );
  }
}
