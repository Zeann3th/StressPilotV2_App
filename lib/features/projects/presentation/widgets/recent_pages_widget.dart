import 'package:flutter/material.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/navigation/navigation_tracker.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/shared/presentation/widgets/navigation_item.dart';

class RecentPagesWidget extends StatefulWidget {
  const RecentPagesWidget({super.key});

  @override
  State<RecentPagesWidget> createState() => _RecentPagesWidgetState();
}

class _RecentPagesWidgetState extends State<RecentPagesWidget> {
  List<RecentPage> _recentPages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentPages();
  }

  Future<void> _loadRecentPages() async {
    final pages = await NavigationTracker.getRecentPages();
    if (mounted) {
      setState(() {
        _recentPages = pages;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recentPages.isEmpty) {
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
            itemCount: _recentPages.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              thickness: 1,
              color: AppColors.border.withValues(alpha: 0.3),
            ),
            itemBuilder: (context, index) {
              final page = _recentPages[index];
              return NavigationItem(
                title: page.title,
                icon: page.icon,
                compact: true,
                onTap: () {
                  AppNavigator.pushNamed(page.route, arguments: page.arguments);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
