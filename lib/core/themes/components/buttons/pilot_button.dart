import 'package:flutter/material.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';

enum PilotButtonVariant { primary, ghost, danger }

class PilotButton extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final PilotButtonVariant variant;
  final bool compact;
  final Color? foregroundOverride;
  final Color? backgroundOverride;
  final String? tooltip;
  final MainAxisAlignment alignment;

  const PilotButton({
    super.key,
    this.label,
    this.icon,
    this.onPressed,
    this.variant = PilotButtonVariant.primary,
    this.compact = false,
    this.foregroundOverride,
    this.backgroundOverride,
    this.tooltip,
    this.alignment = MainAxisAlignment.center,
  });

  const PilotButton.primary({
    super.key,
    this.label,
    this.icon,
    this.onPressed,
    this.compact = false,
    this.foregroundOverride,
    this.backgroundOverride,
    this.tooltip,
    this.alignment = MainAxisAlignment.center,
  }) : variant = PilotButtonVariant.primary;

  const PilotButton.ghost({
    super.key,
    this.label,
    this.icon,
    this.onPressed,
    this.compact = false,
    this.foregroundOverride,
    this.backgroundOverride,
    this.tooltip,
    this.alignment = MainAxisAlignment.center,
  }) : variant = PilotButtonVariant.ghost;

  const PilotButton.danger({
    super.key,
    this.label,
    this.icon,
    this.onPressed,
    this.compact = false,
    this.foregroundOverride,
    this.backgroundOverride,
    this.tooltip,
    this.alignment = MainAxisAlignment.center,
  }) : variant = PilotButtonVariant.danger;

  @override
  State<PilotButton> createState() => _PilotButtonState();
}

class _PilotButtonState extends State<PilotButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor;
    Color textColor;

    switch (widget.variant) {
      case PilotButtonVariant.primary:
        if (_isPressed) {
          bgColor = AppColors.accentActive;
        } else if (_isHovered || _isFocused) {
          bgColor = AppColors.accentHover;
        } else {
          bgColor = AppColors.accent;
        }
        textColor = AppColors.textPrimary;
        break;

      case PilotButtonVariant.ghost:
        if (_isPressed) {
          bgColor = AppColors.accent.withValues(alpha: 0.15);
        } else if (_isHovered || _isFocused) {
          bgColor = AppColors.accent.withValues(alpha: 0.08);
        } else {
          bgColor = Colors.transparent;
        }
        textColor = (_isHovered || _isFocused)
            ? AppColors.accent
            : AppColors.textPrimary;
        break;

      case PilotButtonVariant.danger:
        if (_isPressed) {
          bgColor = AppColors.error.withValues(alpha: 0.25);
        } else if (_isHovered || _isFocused) {
          bgColor = AppColors.error.withValues(alpha: 0.12);
        } else {
          bgColor = Colors.transparent;
        }
        textColor = AppColors.error;
        break;
    }

    if (widget.foregroundOverride != null) {
      textColor = widget.foregroundOverride!;
    }
    if (widget.backgroundOverride != null) {
      bgColor = widget.backgroundOverride!;
    }

    final vPad = widget.compact ? 4.0 : 6.0;
    final hPad = widget.compact ? 8.0 : 12.0;

    Widget child = FocusableActionDetector(
      mouseCursor: widget.onPressed != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      onShowFocusHighlight: (hasFocus) => setState(() => _isFocused = hasFocus),
      onShowHoverHighlight: (hasHover) => setState(() => _isHovered = hasHover),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed?.call();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: TweenAnimationBuilder<double>(
          duration: AppDurations.short,
          tween: Tween(begin: 1.0, end: _isPressed ? 0.98 : 1.0),
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: AnimatedContainer(
            key: ValueKey(isDark),
            duration: AppDurations.short,
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: AppRadius.br4,
              border: _isFocused ? Border.all(color: AppColors.accent, width: 1) : null,
            ),
            child: Row(
              mainAxisSize: widget.alignment == MainAxisAlignment.center ? MainAxisSize.min : MainAxisSize.max,
              mainAxisAlignment: widget.alignment,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 16, color: textColor),
                  if (widget.label != null) const SizedBox(width: 8),
                ],
                if (widget.label != null)
                  Text(
                    widget.label!,
                    style: AppTypography.body.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: child);
    }
    return child;
  }
}
