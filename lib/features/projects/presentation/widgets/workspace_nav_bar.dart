import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:stress_pilot/features/endpoints/domain/models/endpoint.dart';
import 'package:stress_pilot/features/projects/domain/models/flow.dart' as flow_domain;
import 'package:stress_pilot/features/projects/presentation/provider/workspace_tab_provider.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/run_flow_dialog.dart';
import 'package:stress_pilot/features/shared/presentation/provider/endpoint_provider.dart';
import 'package:stress_pilot/features/shared/presentation/provider/project_provider.dart';

class WorkspaceNavBar extends StatelessWidget {
  final VoidCallback onToggleSidebar;
  final bool isSidebarOpen;

  const WorkspaceNavBar({
    super.key,
    required this.onToggleSidebar,
    required this.isSidebarOpen,
  });

  @override
  Widget build(BuildContext context) {
    final project = context.watch<ProjectProvider>().selectedProject;
    final activeTab = context.watch<WorkspaceTabProvider>().activeTab;

    return Container(
      height: AppSpacing.navBarHeight,
      decoration: BoxDecoration(
        color: AppColors.baseBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: MoveWindow()),
          // Left: Sidebar toggle
          Positioned(
            left: AppSpacing.md,
            top: 0,
            bottom: 0,
            child: Center(
              child: _NavIconButton(
                icon: isSidebarOpen ? LucideIcons.panelLeftClose : LucideIcons.panelLeftOpen,
                tooltip: isSidebarOpen ? 'Hide Sidebar' : 'Show Sidebar',
                onPressed: onToggleSidebar,
                isActive: isSidebarOpen,
              ),
            ),
          ),

          // Center: Project name picker (mathematically centered)
          Positioned.fill(
            child: Center(
              child: _ProjectNameButton(projectName: project?.name ?? 'No Project'),
            ),
          ),

          // Right: Controls
          Positioned(
            right: AppSpacing.md,
            top: 0,
            bottom: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PlayStopButton(project: project, activeTab: activeTab),
                if (project != null && project.environmentId != 0) ...[
                  const SizedBox(width: 4),
                  _EnvIconButton(
                    environmentId: project.environmentId,
                    projectName: project.name,
                  ),
                ],
                const SizedBox(width: 12),
                _NavIconButton(
                  icon: LucideIcons.shoppingBag,
                  tooltip: 'Marketplace',
                  onPressed: () => AppNavigator.pushNamed(AppRouter.marketplaceRoute),
                ),
                const SizedBox(width: 4),
                _NavIconButton(
                  icon: LucideIcons.settings,
                  tooltip: 'Settings',
                  onPressed: () => AppNavigator.pushNamed(AppRouter.settingsRoute),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isActive;

  const _NavIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  State<_NavIconButton> createState() => _NavIconButtonState();
}

class _NavIconButtonState extends State<_NavIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: AppDurations.micro,
            width: 32,
            height: 28,
            decoration: BoxDecoration(
              color: widget.isActive 
                ? AppColors.activeItem 
                : (_isHovered ? AppColors.hoverItem : Colors.transparent),
              borderRadius: AppRadius.br4,
            ),
            child: Icon(
              widget.icon,
              size: 16,
              color: (widget.isActive || _isHovered) ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
        ),
      ),
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

    if (!mounted) return;

    final projects = provider.projects;
    if (projects.isEmpty) return;

    final RenderBox? button = this.context.findRenderObject() as RenderBox?;
    final RenderBox? overlay = Overlay.of(this.context).context.findRenderObject() as RenderBox?;
    if (button == null || overlay == null) return;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<int>(
      context: this.context,
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

    if (selected != null && mounted) {
      final project = projects.firstWhere((p) => p.id == selected);
      await provider.selectProject(project);
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

// Env var icon button — navigates to environment management
class _EnvIconButton extends StatefulWidget {
  final int environmentId;
  final String projectName;
  const _EnvIconButton({required this.environmentId, required this.projectName});

  @override
  State<_EnvIconButton> createState() => _EnvIconButtonState();
}

class _EnvIconButtonState extends State<_EnvIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Environment',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: () => AppNavigator.pushNamed(
            AppRouter.projectEnvironmentRoute,
            arguments: {
              'environmentId': widget.environmentId,
              'projectName': widget.projectName,
            },
          ),
          child: AnimatedContainer(
            duration: AppDurations.micro,
            width: 32,
            height: 28,
            decoration: BoxDecoration(
              color: _isHovered ? AppColors.hoverItem : Colors.transparent,
              borderRadius: AppRadius.br4,
            ),
            child: Icon(
              LucideIcons.settings2,
              size: 16,
              color: _isHovered ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// Play/stop button for the active workspace tab
class _PlayStopButton extends StatefulWidget {
  final dynamic project;
  final WorkspaceTab? activeTab;
  const _PlayStopButton({required this.project, required this.activeTab});

  @override
  State<_PlayStopButton> createState() => _PlayStopButtonState();
}

class _PlayStopButtonState extends State<_PlayStopButton> {
  bool _isHovered = false;

  bool get _isFlow => widget.activeTab?.type == WorkspaceTabType.flow;
  bool get _isEndpoint => widget.activeTab?.type == WorkspaceTabType.endpoint;

  @override
  Widget build(BuildContext context) {
    final endpointProvider = context.watch<EndpointProvider>();

    final endpoint = _isEndpoint ? widget.activeTab!.data as Endpoint : null;
    final isExecuting = endpoint != null && endpointProvider.isEndpointExecuting(endpoint.id);

    final bool canAct = widget.activeTab != null && widget.project != null;
    final IconData icon = isExecuting ? LucideIcons.squareStop : LucideIcons.play;
    final Color iconColor = canAct
        ? (isExecuting ? AppColors.error : AppColors.methodGet)
        : AppColors.textDisabled;

    final String tooltip = isExecuting
        ? 'Stop'
        : (_isFlow ? 'Run Flow' : (_isEndpoint ? 'Run Endpoint' : 'Run'));

    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: canAct ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: canAct ? () => _handleTap(context, endpointProvider, isExecuting, endpoint) : null,
          child: AnimatedContainer(
            duration: AppDurations.micro,
            width: 32,
            height: 28,
            decoration: BoxDecoration(
              color: _isHovered && canAct ? AppColors.hoverItem : Colors.transparent,
              borderRadius: AppRadius.br4,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
        ),
      ),
    );
  }

  void _handleTap(
    BuildContext context,
    EndpointProvider endpointProvider,
    bool isExecuting,
    Endpoint? endpoint,
  ) {
    if (_isFlow) {
      final flow = widget.activeTab!.data as flow_domain.Flow;
      showDialog(
        context: context,
        builder: (_) => RunFlowDialog(flowId: flow.id),
      );
      return;
    }

    if (_isEndpoint && endpoint != null) {
      if (isExecuting) {
        endpointProvider.cancelExecution(endpoint.id);
      } else {
        final transientState = endpointProvider.getTransientState(endpoint.id) ?? {};
        endpointProvider.executeEndpoint(endpoint.id, transientState);
      }
    }
  }
}
