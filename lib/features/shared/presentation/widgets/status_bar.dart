import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';

class StatusBar extends StatelessWidget {
  final String? projectName;

  const StatusBar({
    super.key,
    this.projectName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      color: AppColors.sidebarBackground,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          if (projectName != null)
            Text(
              projectName!,
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),
          const Spacer(),
          _StatusIconButton(
            icon: LucideIcons.history,
            tooltip: 'Recent Runs',
            onTap: () => AppNavigator.pushNamed(AppRouter.recentRunsRoute),
          ),
        ],
      ),
    );
  }
}

class _StatusIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _StatusIconButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  State<_StatusIconButton> createState() => _StatusIconButtonState();
}

class _StatusIconButtonState extends State<_StatusIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: _isHovered ? AppColors.hoverItem : Colors.transparent,
              borderRadius: AppRadius.br4,
            ),
            child: Icon(widget.icon, size: 12, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}
