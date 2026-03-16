import 'package:flutter/material.dart';

/// A skeleton loading screen that mimics the main app layout.
/// Shows a shimmer effect over placeholder shapes matching the sidebar + content area.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({super.key});

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1F22) : const Color(0xFFF5F5F7);
    final surface = isDark ? const Color(0xFF2B2D30) : Colors.white;
    final shimmerBase = isDark ? const Color(0xFF303236) : const Color(0xFFE8E8ED);
    final shimmerHighlight = isDark ? const Color(0xFF3C3F44) : const Color(0xFFF5F5F7);

    return Scaffold(
      backgroundColor: bg,
      body: Row(
        children: [
          // ── Sidebar skeleton ──
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: surface,
              border: Border(
                right: BorderSide(color: shimmerBase),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back + title
                  Row(
                    children: [
                      _ShimmerBox(ctrl: _shimmerCtrl, w: 32, h: 32, r: 8, base: shimmerBase, highlight: shimmerHighlight),
                      const SizedBox(width: 12),
                      _ShimmerBox(ctrl: _shimmerCtrl, w: 140, h: 18, r: 6, base: shimmerBase, highlight: shimmerHighlight),
                      const Spacer(),
                      _ShimmerBox(ctrl: _shimmerCtrl, w: 32, h: 32, r: 8, base: shimmerBase, highlight: shimmerHighlight),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Search bar
                  _ShimmerBox(ctrl: _shimmerCtrl, w: double.infinity, h: 40, r: 10, base: shimmerBase, highlight: shimmerHighlight),
                  const SizedBox(height: 24),
                  // Section label
                  _ShimmerBox(ctrl: _shimmerCtrl, w: 80, h: 12, r: 4, base: shimmerBase, highlight: shimmerHighlight),
                  const SizedBox(height: 16),
                  // List items
                  for (int i = 0; i < 8; i++) ...[
                    _ShimmerBox(ctrl: _shimmerCtrl, w: double.infinity, h: 40, r: 10, base: shimmerBase, highlight: shimmerHighlight),
                    const SizedBox(height: 6),
                  ],
                ],
              ),
            ),
          ),
          // ── Content skeleton ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      _ShimmerBox(ctrl: _shimmerCtrl, w: 240, h: 28, r: 8, base: shimmerBase, highlight: shimmerHighlight),
                      const Spacer(),
                      _ShimmerBox(ctrl: _shimmerCtrl, w: 90, h: 36, r: 10, base: shimmerBase, highlight: shimmerHighlight),
                      const SizedBox(width: 8),
                      _ShimmerBox(ctrl: _shimmerCtrl, w: 40, h: 36, r: 10, base: shimmerBase, highlight: shimmerHighlight),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // URL bar
                  Container(
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: shimmerBase),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ShimmerBox(ctrl: _shimmerCtrl, w: double.infinity, h: 44, r: 12, base: shimmerBase, highlight: shimmerHighlight),
                        const SizedBox(height: 16),
                        // Tab bar
                        _ShimmerBox(ctrl: _shimmerCtrl, w: 320, h: 32, r: 8, base: shimmerBase, highlight: shimmerHighlight),
                        const SizedBox(height: 16),
                        // Content lines
                        for (int i = 0; i < 4; i++) ...[
                          _ShimmerBox(ctrl: _shimmerCtrl, w: double.infinity, h: 14, r: 4, base: shimmerBase, highlight: shimmerHighlight),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Response panel
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: shimmerBase),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ShimmerBox(ctrl: _shimmerCtrl, w: 100, h: 16, r: 4, base: shimmerBase, highlight: shimmerHighlight),
                          const SizedBox(height: 20),
                          _ShimmerBox(ctrl: _shimmerCtrl, w: double.infinity, h: 14, r: 4, base: shimmerBase, highlight: shimmerHighlight),
                          const SizedBox(height: 10),
                          _ShimmerBox(ctrl: _shimmerCtrl, w: 220, h: 14, r: 4, base: shimmerBase, highlight: shimmerHighlight),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final AnimationController ctrl;
  final double w;
  final double h;
  final double r;
  final Color base;
  final Color highlight;

  const _ShimmerBox({
    required this.ctrl,
    required this.w,
    required this.h,
    required this.r,
    required this.base,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, _) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(r),
          gradient: LinearGradient(
            begin: Alignment(-1.0 + 2.0 * ctrl.value, 0),
            end: Alignment(-1.0 + 2.0 * ctrl.value + 1.0, 0),
            colors: [base, highlight, base],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}
