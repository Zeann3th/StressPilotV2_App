import 'package:flutter/material.dart';
import 'tokens.dart';

// ─────────────────────────────────────────────
// PilotButton
// ─────────────────────────────────────────────

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
        } else if (_isHovered) {
          bgColor = AppColors.accentHover;
        } else {
          bgColor = AppColors.accent;
        }
        textColor = Colors.white;
        borderColor = Colors.transparent;
        break;

      case PilotButtonVariant.ghost:
        if (_isPressed) {
          bgColor = AppColors.accent.withValues(alpha: 0.15);
        } else if (_isHovered) {
          bgColor = AppColors.accent.withValues(alpha: 0.08);
        } else {
          bgColor = Colors.transparent;
        }
        textColor = _isHovered
            ? AppColors.accentHover
            : (isDark ? AppColors.textPrimary : AppColors.textLight);
        borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
        break;

      case PilotButtonVariant.danger:
        if (_isPressed) {
          bgColor = AppColors.error.withValues(alpha: 0.25);
        } else if (_isHovered) {
          bgColor = AppColors.error.withValues(alpha: 0.12);
        } else {
          bgColor = Colors.transparent;
        }
        textColor = AppColors.error;
        borderColor = AppColors.error.withValues(alpha: 0.4);
        break;
    }

    final vPad = widget.compact ? 6.0 : 8.0;
    final hPad = widget.compact ? 10.0 : 16.0;

    return MouseRegion(
      cursor: widget.onPressed != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed?.call();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: AppDurations.micro,
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppRadius.br8,
            border: Border.all(color: borderColor, width: 1),
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

// ─────────────────────────────────────────────
// PilotInput
// ─────────────────────────────────────────────

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

    final bgColor = isDark ? AppColors.darkElevated : AppColors.lightElevated;
    final borderColor = widget.borderless
        ? Colors.transparent
        : _isFocused
        ? AppColors.accent
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    return AnimatedContainer(
      duration: AppDurations.short,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.br8,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        maxLines: widget.maxLines,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        style: (widget.style ?? AppTypography.body).copyWith(
          color: isDark ? AppColors.textPrimary : AppColors.textLight,
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
    );
  }
}

// ─────────────────────────────────────────────
// PilotBadge
// ─────────────────────────────────────────────

class PilotBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool compact;

  const PilotBadge({
    super.key,
    required this.label,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 7,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.br4,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: AppTypography.label.copyWith(
          color: color,
          fontSize: compact ? 10 : 11,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PilotDialog
// ─────────────────────────────────────────────

class PilotDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;
  final double maxWidth;

  const PilotDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.maxWidth = 480,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    required List<Widget> actions,
    double maxWidth = 480,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: AppDurations.medium,
      pageBuilder: (ctx, animation, _) {
        return PilotDialog(
          title: title,
          content: content,
          actions: actions,
          maxWidth: maxWidth,
        );
      },
      transitionBuilder: (ctx, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.textLight;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: AppRadius.br16,
              border: Border.all(color: border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Text(
                    title,
                    style: AppTypography.heading.copyWith(color: textPrimary),
                  ),
                ),
                Divider(height: 1, color: border),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: content,
                ),
                Divider(height: 1, color: border),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      for (int i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        actions[i],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PilotToast
// ─────────────────────────────────────────────

class PilotToast {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (ctx) => _PilotToastWidget(
        message: message,
        isError: isError,
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), entry.remove);
  }
}

class _PilotToastWidget extends StatefulWidget {
  final String message;
  final bool isError;

  const _PilotToastWidget({required this.message, required this.isError});

  @override
  State<_PilotToastWidget> createState() => _PilotToastWidgetState();
}

class _PilotToastWidgetState extends State<_PilotToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppDurations.short,
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) _ctrl.reverse();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isError ? AppColors.error : AppColors.accent;
    return Positioned(
      bottom: 32,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _opacity,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.darkElevated,
              borderRadius: AppRadius.br8,
              border: Border.all(color: color.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Text(
              widget.message,
              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
