import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/projects/presentation/provider/workspace_tab_provider.dart';

class WorkspaceTabBar extends StatelessWidget {
  const WorkspaceTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    final tabProvider = context.watch<WorkspaceTabProvider>();
    final tabs = tabProvider.tabs;
    final activeTab = tabProvider.activeTab;

    return Container(
      height: AppSpacing.tabBarHeight,
      color: AppColors.sidebarBackground,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          return _WorkspaceTabWidget(
            tab: tab,
            isActive: activeTab == tab,
            onTap: () => tabProvider.selectTab(tab),
            onClose: () => tabProvider.closeTab(tab),
          );
        },
      ),
    );
  }
}

class _WorkspaceTabWidget extends StatefulWidget {
  final WorkspaceTab tab;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _WorkspaceTabWidget({
    required this.tab,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  @override
  State<_WorkspaceTabWidget> createState() => _WorkspaceTabWidgetState();
}

class _WorkspaceTabWidgetState extends State<_WorkspaceTabWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: widget.isActive ? AppColors.activeItem : Colors.transparent,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
            border: Border(
              bottom: BorderSide(
                color: widget.isActive ? AppColors.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.tab.type == WorkspaceTabType.flow ? LucideIcons.gitFork : LucideIcons.link,
                size: 14,
                color: widget.isActive ? AppColors.accent : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                widget.tab.name,
                style: AppTypography.body.copyWith(
                  color: widget.isActive ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              if (_isHovered || widget.isActive)
                GestureDetector(
                  onTap: () {
                    widget.onClose();
                  },
                  child: Icon(
                    LucideIcons.x,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                )
              else
                const SizedBox(width: 14),
            ],
          ),
        ),
      ),
    );
  }
}
