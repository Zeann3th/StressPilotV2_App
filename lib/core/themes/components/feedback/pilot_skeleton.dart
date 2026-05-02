import 'package:flutter/material.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';

class PilotSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const PilotSkeleton({super.key, this.width, this.height, this.borderRadius});

  @override
  State<PilotSkeleton> createState() => _PilotSkeletonState();
}

class _PilotSkeletonState extends State<PilotSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    
    _opacity = Tween<double>(begin: 0.2, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: widget.borderRadius ?? AppRadius.br4,
        ),
      ),
    );
  }
}
