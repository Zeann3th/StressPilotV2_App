import 'package:flutter/material.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/dashboard_top_bar.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';

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
    final bg = AppColors.background;
    final surface = AppColors.surface;
    final shimmerBase = AppColors.border.withValues(alpha: 0.1);
    final shimmerHighlight = AppColors.surface;

    final border = AppColors.border;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [

          const DashboardTopBar(),

          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: AppRadius.br16,
                border: Border.all(color: border.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: AppRadius.br16,
                child: Column(
                  children: [

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                _ShimmerBox(ctrl: _shimmerCtrl, w: 240, h: 36, r: 8, base: shimmerBase, highlight: shimmerHighlight),
                                const Spacer(),
                                _ShimmerBox(ctrl: _shimmerCtrl, w: 90, h: 36, r: 8, base: shimmerBase, highlight: shimmerHighlight),
                                const SizedBox(width: 8),
                                _ShimmerBox(ctrl: _shimmerCtrl, w: 120, h: 36, r: 8, base: shimmerBase, highlight: shimmerHighlight),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _ShimmerBox(ctrl: _shimmerCtrl, w: double.infinity, h: 24, r: 4, base: shimmerBase, highlight: shimmerHighlight),
                          ),
                          const SizedBox(height: 16),

                          Expanded(
                            child: SingleChildScrollView(
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                children: [
                                  for (int i = 0; i < 4; i++) ...[
                                    _ShimmerBox(ctrl: _shimmerCtrl, w: double.infinity, h: 56, r: 8, base: shimmerBase, highlight: shimmerHighlight),
                                    const SizedBox(height: 12),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      height: MediaQuery.of(context).size.height * 0.4,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: border.withValues(alpha: 0.3))),
                      ),
                      child: Row(
                        children: [

                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.background.withValues(alpha: 0.5),
                                border: Border.all(color: border.withValues(alpha: 0.5)),
                                borderRadius: AppRadius.br12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  _ShimmerBox(ctrl: _shimmerCtrl, w: 140, h: 24, r: 4, base: shimmerBase, highlight: shimmerHighlight),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: 3,
                                      separatorBuilder: (context, index) => const SizedBox(width: 12),
                                      itemBuilder: (context, index) => _ShimmerBox(
                                        ctrl: _shimmerCtrl,
                                        w: 280,
                                        h: double.infinity,
                                        r: 8,
                                        base: shimmerBase,
                                        highlight: shimmerHighlight,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.background.withValues(alpha: 0.5),
                                border: Border.all(color: border.withValues(alpha: 0.5)),
                                borderRadius: AppRadius.br12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  _ShimmerBox(ctrl: _shimmerCtrl, w: 100, h: 24, r: 4, base: shimmerBase, highlight: shimmerHighlight),
                                  const SizedBox(height: 24),

                                  Expanded(
                                    child: _ShimmerBox(
                                      ctrl: _shimmerCtrl,
                                      w: double.infinity,
                                      h: double.infinity,
                                      r: 12,
                                      base: shimmerBase,
                                      highlight: shimmerHighlight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
