import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/design/tokens.dart';
import 'package:stress_pilot/core/design/components.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stress_pilot/features/projects/presentation/pages/projects_page.dart';
import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';

class WorkspaceCommandBar extends StatelessWidget {
  const WorkspaceCommandBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.textPrimary : AppColors.textLight;

    final project = context.watch<ProjectProvider>().selectedProject;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border, width: 1)),
      ),
      child: Row(
        children: [
          // Back chevron
          _BackButton(
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ProjectsPage()),
              );
              context.read<ProjectProvider>().clearProject();
            },
          ),
          const SizedBox(width: 4),

          // Separator
          Text(
            '/',
            style: AppTypography.body.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(width: 8),

          // Project name
          Text(
            project?.name ?? 'Workspace',
            style: AppTypography.bodyLg.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),

          const Spacer(),

          // Endpoints button
          PilotButton.ghost(
            icon: LucideIcons.network,
            label: 'Endpoints',
            compact: true,
            onPressed: () {
              if (project != null) {
                AppNavigator.pushNamed(
                  AppRouter.projectEndpointsRoute,
                  arguments: {'project': project},
                );
              }
            },
          ),
          const SizedBox(width: 6),

          // Environment button
          PilotButton.ghost(
            icon: LucideIcons.settings2,
            label: 'Environment',
            compact: true,
            onPressed: () {
              if (project != null) {
                AppNavigator.pushNamed(
                  AppRouter.projectEnvironmentRoute,
                  arguments: {
                    'environmentId': project.environmentId,
                    'projectName': project.name,
                  },
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.micro,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.accent.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: AppRadius.br4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.chevronLeft,
                size: 16,
                color: _hovered ? AppColors.accent : AppColors.textSecondary,
              ),
              const SizedBox(width: 2),
              Text(
                'Projects',
                style: AppTypography.body.copyWith(
                  color: _hovered ? AppColors.accent : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
