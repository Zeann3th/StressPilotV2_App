import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/shared/presentation/provider/project_provider.dart';

class WorkspaceNavBar extends StatelessWidget {
  const WorkspaceNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final project = context.watch<ProjectProvider>().selectedProject;
    final secondaryText = AppColors.textSecondary;

    return Container(
      height: AppSpacing.navBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.baseBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        children: [
          // Left: Project Name
          Text(
            project?.name ?? 'No Project',
            style: AppTypography.body.copyWith(color: secondaryText),
          ),
          
          const Spacer(),
          
          // Right: Marketplace · Settings · Agent
          _NavButton(
            label: 'Marketplace',
            onPressed: () => AppNavigator.pushNamed(AppRouter.marketplaceRoute),
          ),
          _NavDivider(),
          _NavButton(
            label: 'Settings',
            onPressed: () => AppNavigator.pushNamed(AppRouter.settingsRoute),
          ),
          _NavDivider(),
          _NavButton(
            label: 'Agent',
            onPressed: () => AppNavigator.pushNamed(AppRouter.agentRoute),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const _NavButton({required this.label, required this.onPressed});

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            widget.label,
            style: AppTypography.body.copyWith(
              color: _isHovered ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      '·',
      style: AppTypography.body.copyWith(color: AppColors.textDisabled),
    );
  }
}
