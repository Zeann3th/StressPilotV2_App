import 'package:flutter/material.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/themes/components/components.dart';

class ProjectEmptyState extends StatefulWidget {
  const ProjectEmptyState({super.key});

  @override
  State<ProjectEmptyState> createState() => _ProjectEmptyStateState();
}

class _ProjectEmptyStateState extends State<ProjectEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = AppColors.border;
    final textColor = AppColors.textPrimary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              borderRadius: AppRadius.br12,
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: AnimatedBuilder(
              animation: _opacity,
              builder: (context, _) => Opacity(
                opacity: _opacity.value,
                child: Icon(
                  Icons.folder_open_rounded,
                  size: 40,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No projects yet',
            style: AppTypography.heading.copyWith(color: textColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first project to get started',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class ProjectErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const ProjectErrorState({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = AppColors.textPrimary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.10),
              borderRadius: AppRadius.br12,
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 32,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: AppTypography.heading.copyWith(color: textColor),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Text(
              error,
              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          PilotButton.ghost(
            icon: Icons.refresh_rounded,
            label: 'Retry',
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
