import 'package:flutter/material.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';

class SidebarSectionHeader extends StatelessWidget {
  final String label;
  final Widget? trailing;
  final VoidCallback? onToggle;
  final bool isExpanded;

  const SidebarSectionHeader({
    super.key,
    required this.label,
    this.trailing,
    this.onToggle,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        height: AppSpacing.sidebarRowHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: AppTypography.label,
              ),
            ),
            trailing ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
