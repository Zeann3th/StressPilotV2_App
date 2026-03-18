import 'package:flutter/material.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';

enum PilotButtonVariant { primary, ghost, danger }

class PilotButton extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final PilotButtonVariant variant;
  final bool compact;

  const PilotButton({
    super.key,
    this.label,
    this.icon,
    this.onPressed,
    this.variant = PilotButtonVariant.primary,
    this.compact = false,
  });

  const PilotButton.primary({
    super.key,
    this.label,
    this.icon,
    this.onPressed,
    this.compact = false,
  }) : variant = PilotButtonVariant.primary;

  const PilotButton.ghost({
    super.key,
    this.label,
    this.icon,
    this.onPressed,
    this.compact = false,
  }) : variant = PilotButtonVariant.ghost;

  const PilotButton.danger({
    super.key,
    this.label,
    this.icon,
    this.onPressed,
    this.compact = false,
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
    Color borderColor;

    switch (widget.variant) {
      case PilotButtonVariant.primary:
        if (_isPressed) {
          bgColor = AppColors.accentActive;
        } else if (_isHovered || _isFocused) {
          bgColor = AppColors.accentHover;
        } else {
          bgColor = AppColors.accent;
        }
        textColor = Colors.white;
        borderColor = _isFocused
            ? Colors.white.withValues(alpha: 0.5)
            : Colors.transparent;
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
            ? AppColors.accentHover
            : (isDark ? AppColors.textPrimary : AppColors.textLight);
        borderColor = _isFocused
            ? AppColors.accent
            : (isDark ? AppColors.darkBorder : AppColors.lightBorder);
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
        borderColor = _isFocused
            ? AppColors.error
            : AppColors.error.withValues(alpha: 0.4);
        break;
    }

    final vPad = widget.compact ? 6.0 : 8.0;
    final hPad = widget.compact ? 10.0 : 16.0;

    return FocusableActionDetector(
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
        child: AnimatedContainer(
          key: ValueKey(isDark),
          duration: AppDurations.short,
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppRadius.br8,
            border: Border.all(color: borderColor, width: _isFocused ? 2 : 1),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 15, color: textColor),
                if (widget.label != null) const SizedBox(width: 6),
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
    );
  }
}
