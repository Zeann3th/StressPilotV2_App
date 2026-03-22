import 'package:flutter/material.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';

class PilotInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? placeholder;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;
  final int maxLines;
  final bool borderless;
  final IconData? prefixIcon;
  final TextStyle? style;
  final VoidCallback? onFocusLost;

  const PilotInput({
    super.key,
    this.controller,
    this.placeholder,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
    this.maxLines = 1,
    this.borderless = false,
    this.prefixIcon,
    this.style,
    this.onFocusLost,
  });

  @override
  State<PilotInput> createState() => _PilotInputState();
}

class _PilotInputState extends State<PilotInput> {
  bool _isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
    if (!_focusNode.hasFocus) {
      widget.onFocusLost?.call();
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.removeListener(_onFocusChange);
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = AppColors.elevated;
    final borderColor = widget.borderless
        ? Colors.transparent
        : _isFocused
        ? AppColors.accent
        : AppColors.border;

    return AnimatedContainer(
      key: ValueKey(isDark),
      duration: AppDurations.short,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.br8,
        border: Border.all(
          color: borderColor,
          width: _isFocused && !widget.borderless ? 2 : 1,
        ),
        boxShadow: _isFocused && !widget.borderless
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Padding(
        padding: EdgeInsets.all(_isFocused && !widget.borderless ? 0.0 : 1.0),
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          maxLines: widget.maxLines,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          style: (widget.style ?? AppTypography.body).copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.placeholder,
            hintStyle: AppTypography.body.copyWith(color: AppColors.textMuted),
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, size: 16, color: AppColors.textMuted)
                : null,
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: widget.prefixIcon != null ? 4 : 12,
              vertical: 10,
            ),
          ),
          cursorColor: AppColors.accent,
        ),
      ),
    );
  }
}
