import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/navigation/navigation_tracker.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/features/projects/domain/models/project.dart';
import 'package:stress_pilot/features/projects/domain/models/flow.dart' as flow_domain;
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/features/shared/presentation/widgets/navigation_item.dart';

class RecentPagesWidget extends StatefulWidget {
  const RecentPagesWidget({super.key});

  @override
  State<RecentPagesWidget> createState() => _RecentPagesWidgetState();
}

class _RecentPagesWidgetState extends State<RecentPagesWidget> {
  List<RecentPage> _recentItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentItems();
  }

  Future<void> _loadRecentItems() async {
    final items = await NavigationTracker.getRecentItems();
    if (mounted) {
      setState(() {
        _recentItems = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _onItemTap(RecentPage item) async {
    final projectProvider = context.read<ProjectProvider>();
    final flowProvider = context.read<FlowProvider>();

    switch (item.type) {
      case RecentEntityType.project:
        final project = Project.fromJson(item.arguments);
        await projectProvider.selectProject(project);
        AppNavigator.pushReplacementNamed(AppRouter.workspaceRoute);
        break;
      case RecentEntityType.flow:
        final flow = flow_domain.Flow.fromJson(item.arguments);
        await flowProvider.selectFlow(flow);
        AppNavigator.pushReplacementNamed(AppRouter.workspaceRoute);
        break;
      case RecentEntityType.endpoint:
        final project = Project.fromJson(item.arguments['project'] as Map<String, dynamic>);
        await projectProvider.selectProject(project);
        AppNavigator.pushReplacementNamed(AppRouter.workspaceRoute);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PilotSkeleton(width: 16, height: 16),
              const SizedBox(width: 8),
              const PilotSkeleton(width: 120, height: 20),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: 5,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => const PilotSkeleton(height: 48),
            ),
          ),
        ],
      );
    }

    if (_recentItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 32, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'No recent activity',
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history_rounded, size: 16, color: AppColors.textPrimary),
            const SizedBox(width: 8),
            Text('Recent Activity', style: AppTypography.heading),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: _recentItems.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              color: AppColors.border.withValues(alpha: 0.15),
            ),
            itemBuilder: (context, index) {
              final item = _recentItems[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: NavigationItem(
                  title: item.title,
                  subtitle: item.subtitle,
                  badge: item.badge,
                  icon: item.icon,
                  compact: false,
                  onTap: () => _onItemTap(item),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
