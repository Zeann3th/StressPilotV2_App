import 'package:flutter/material.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';

class PilotPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const PilotPanel({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadius.br12;
    return Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.sidebarBackground,
        borderRadius: radius,
        border: Border.all(color: AppColors.divider),
        boxShadow: AppShadows.panel,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: child,
      ),
    );
  }
}
