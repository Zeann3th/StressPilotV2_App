import 'package:flutter/material.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';

class PilotToast {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (ctx) => _PilotToastWidget(message: message, isError: isError),
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
    _ctrl = AnimationController(vsync: this, duration: AppDurations.short);
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
              color: AppColors.elevated,
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
