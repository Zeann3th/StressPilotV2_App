import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      switch (item.type) {
        case RecentEntityType.project:
          final project = Project.fromJson(item.arguments);
          await projectProvider.selectProject(project);
          if (mounted) AppNavigator.pushReplacementNamed(AppRouter.workspaceRoute);
          break;
        case RecentEntityType.flow:
          final flow = flow_domain.Flow.fromJson(item.arguments);
          await flowProvider.selectFlow(flow);
          if (mounted) AppNavigator.pushReplacementNamed(AppRouter.workspaceRoute);
          break;
        case RecentEntityType.endpoint:
          final project = Project.fromJson(item.arguments['project'] as Map<String, dynamic>);
          await projectProvider.selectProject(project);
          if (mounted) AppNavigator.pushReplacementNamed(AppRouter.workspaceRoute);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PilotSkeleton(width: 48, height: 48),
            const SizedBox(height: 16),
            const PilotSkeleton(width: 200, height: 24),
            const SizedBox(height: 32),
            ...List.generate(3, (index) => const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: PilotSkeleton(height: 40),
            )),
          ],
        ),
      );
    }

    if (_recentItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.rocket, size: 48, color: AppColors.textDisabled),
            const SizedBox(height: 16),
            Text(
              'No recent activity',
              style: AppTypography.heading.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Icon(LucideIcons.rocket, size: 48, color: AppColors.textDisabled),
        const SizedBox(height: 16),
        Text(
          'Recent Projects & Flows',
          style: AppTypography.heading.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: _recentItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final item = _recentItems[index];
              return NavigationItem(
                title: item.title,
                subtitle: item.subtitle,
                badge: item.badge,
                icon: item.icon,
                compact: true,
                onTap: () => _onItemTap(item),
              );
            },
          ),
        ),
      ],
    );
  }
}
