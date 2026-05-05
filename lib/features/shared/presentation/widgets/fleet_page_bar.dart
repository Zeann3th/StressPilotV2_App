import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';

class FleetPageBar extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final bool showBack;
  final VoidCallback? onBack;

  const FleetPageBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.showBack = true,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.navBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.baseBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          if (showBack) ...[
            _BackButton(onTap: onBack ?? () => Navigator.of(context).pop()),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '/',
              style: AppTypography.body.copyWith(color: AppColors.textDisabled),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            title,
            style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary),
          ),
          const Spacer(),
          ...actions,
        ],
      ),
    );
  }
}

class _BackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.micro,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.accent.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: AppRadius.br4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.chevronLeft,
                size: 16,
                color: _hovered ? AppColors.accent : AppColors.textSecondary,
              ),
              const SizedBox(width: 2),
              Text(
                'Back',
                style: AppTypography.body.copyWith(
                  color: _hovered ? AppColors.accent : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
