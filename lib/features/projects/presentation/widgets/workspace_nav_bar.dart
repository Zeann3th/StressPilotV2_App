import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/shared/presentation/provider/project_provider.dart';

class WorkspaceNavBar extends StatelessWidget {
  const WorkspaceNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final project = context.watch<ProjectProvider>().selectedProject;

    return Container(
      height: AppSpacing.navBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.baseBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        children: [
          // Left: Project Name (clickable project picker)
          _ProjectNameButton(projectName: project?.name ?? 'No Project'),
          
          const Spacer(),
          
          // Right: Marketplace · Settings · Agent
          _NavButton(
            label: 'Marketplace',
            onPressed: () => AppNavigator.pushNamed(AppRouter.marketplaceRoute),
          ),
          _NavDivider(),
          _NavButton(
            label: 'Settings',
            onPressed: () => AppNavigator.pushNamed(AppRouter.settingsRoute),
          ),
          _NavDivider(),
          _NavButton(
            label: 'Agent',
            onPressed: () => AppNavigator.pushNamed(AppRouter.agentRoute),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const _NavButton({required this.label, required this.onPressed});

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            widget.label,
            style: AppTypography.body.copyWith(
              color: _isHovered ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      '·',
      style: AppTypography.body.copyWith(color: AppColors.textDisabled),
    );
  }
}

class _ProjectNameButton extends StatefulWidget {
  final String projectName;
  const _ProjectNameButton({required this.projectName});

  @override
  State<_ProjectNameButton> createState() => _ProjectNameButtonState();
}

class _ProjectNameButtonState extends State<_ProjectNameButton> {
  bool _isHovered = false;

  Future<void> _showProjectPicker(BuildContext context) async {
    final provider = context.read<ProjectProvider>();
    await provider.loadProjects();

    if (!context.mounted) return;

    final projects = provider.projects;
    if (projects.isEmpty) return;

    final RenderBox? button = context.findRenderObject() as RenderBox?;
    final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (button == null || overlay == null) return;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<int>(
      context: context,
      position: position,
      color: AppColors.elevatedSurface,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.br6,
        side: BorderSide(color: AppColors.border),
      ),
      items: projects.map((p) => PopupMenuItem<int>(
        value: p.id,
        height: 36,
        child: Text(
          p.name,
          style: AppTypography.body.copyWith(
            color: provider.selectedProject?.id == p.id
                ? AppColors.accent
                : AppColors.textPrimary,
          ),
        ),
      )).toList(),
    );

    if (selected != null && context.mounted) {
      final project = projects.firstWhere((p) => p.id == selected);
      await context.read<ProjectProvider>().selectProject(project);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => _showProjectPicker(context),
        child: AnimatedContainer(
          duration: AppDurations.micro,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.hoverItem : Colors.transparent,
            borderRadius: AppRadius.br4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.projectName,
                style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(width: 4),
              Icon(LucideIcons.chevronsUpDown, size: 12, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
