import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stress_pilot/features/projects/presentation/pages/projects_page.dart';
import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/environments/presentation/widgets/environment_dialog.dart';

class WorkspaceCommandBar extends StatelessWidget {
  const WorkspaceCommandBar({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = AppColors.textPrimary;

    final project = context.watch<ProjectProvider>().selectedProject;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.transparent,
      child: Row(
        children: [

          _BackButton(
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ProjectsPage()),
              );
              context.read<ProjectProvider>().clearProject();
            },
          ),
          const SizedBox(width: 4),

          Text(
            '/',
            style: AppTypography.body.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(width: 8),

          Text(
            project?.name ?? 'Workspace',
            style: AppTypography.bodyLg.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),

          const Spacer(),

          Tooltip(
            message: 'Endpoints',
            child: PilotButton.ghost(
              icon: LucideIcons.network,
              compact: true,
              onPressed: () {
                if (project != null) {
                  AppNavigator.pushNamed(AppRouter.workspaceRoute);
                }
              },
            ),
          ),
          const SizedBox(width: 6),

          Tooltip(
            message: 'Environment',
            child: PilotButton.ghost(
              icon: LucideIcons.settings2,
              compact: true,
              onPressed: () {
                if (project != null) {
                  EnvironmentManagerDialog.show(
                    context,
                    project.environmentId,
                    project.name,
                  );
                }
              },
            ),
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
