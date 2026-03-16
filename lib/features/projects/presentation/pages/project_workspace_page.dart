import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:stress_pilot/core/design/tokens.dart';
import 'package:stress_pilot/features/common/presentation/app_topbar.dart';
import 'package:stress_pilot/features/projects/domain/flow.dart' as flow_domain;
import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/features/common/presentation/provider/endpoint_provider.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/workspace/workspace_command_bar.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/workspace/workspace_flow_tabs.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/workspace/workspace_node_library.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/workspace/workspace_canvas.dart';

class ProjectWorkspacePage extends StatefulWidget {
  const ProjectWorkspacePage({super.key});

  @override
  State<ProjectWorkspacePage> createState() => _ProjectWorkspacePageState();
}

class _ProjectWorkspacePageState extends State<ProjectWorkspacePage> {
  flow_domain.Flow? _selectedFlow;
  int? _lastLoadedProjectId;
  bool _libraryCollapsed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProjectProvider>().loadProjects();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final project = context.watch<ProjectProvider>().selectedProject;

    if (project != null && project.id != _lastLoadedProjectId) {
      _lastLoadedProjectId = project.id;
      _selectedFlow = null;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<FlowProvider>().loadFlows(projectId: project.id);
        context.read<EndpointProvider>().loadEndpoints(projectId: project.id);
      });
    }
  }

  // Auto-select the first flow when the list loads and nothing is selected
  void _maybeAutoSelect(List<flow_domain.Flow> flows) {
    if (_selectedFlow == null && flows.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedFlow = flows.first);
        context.read<FlowProvider>().selectFlow(flows.first);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final project = context.watch<ProjectProvider>().selectedProject;

    // Trigger auto-select whenever flows change
    final flows = context.watch<FlowProvider>().flows;
    _maybeAutoSelect(flows);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // Topbar
          const AppTopBar(),

          // Main workspace column
          Expanded(
            child: Column(
              children: [
                // Breadcrumb command bar
                const WorkspaceCommandBar(),

                // Flow tab strip
                WorkspaceFlowTabs(
                  selectedFlow: _selectedFlow,
                  onFlowSelected: (f) => setState(() => _selectedFlow = f),
                ),

                // Canvas + node library row
                Expanded(
                  child: Row(
                    children: [
                      // Node library (collapsible)
                      AnimatedSize(
                        duration: AppDurations.short,
                        curve: Curves.easeInOut,
                        child: _libraryCollapsed
                            ? const SizedBox.shrink()
                            : WorkspaceNodeLibrary(
                                projectId: project?.id ?? 0,
                                selectedFlow: _selectedFlow,
                              ),
                      ),

                      // Collapse toggle handle
                      _LibraryHandle(
                        collapsed: _libraryCollapsed,
                        onToggle: () => setState(
                          () => _libraryCollapsed = !_libraryCollapsed,
                        ),
                        border: border,
                      ),

                      // Canvas fills the rest
                      Expanded(
                        child: WorkspaceCanvas(selectedFlow: _selectedFlow),
                      ),
                    ],
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOutCubic),
          ),
        ],
      ),
    );
  }
}

// ─── Slim collapse handle between library and canvas ─────────────────────────

class _LibraryHandle extends StatefulWidget {
  final bool collapsed;
  final VoidCallback onToggle;
  final Color border;

  const _LibraryHandle({
    required this.collapsed,
    required this.onToggle,
    required this.border,
  });

  @override
  State<_LibraryHandle> createState() => _LibraryHandleState();
}

class _LibraryHandleState extends State<_LibraryHandle> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onToggle,
        child: AnimatedContainer(
          duration: AppDurations.micro,
          width: 16,
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.accent.withValues(alpha: 0.06)
                : Colors.transparent,
            border: Border(left: BorderSide(color: widget.border, width: 1)),
          ),
          child: Center(
            child: AnimatedRotation(
              turns: widget.collapsed ? 0.0 : 0.5,
              duration: AppDurations.short,
              child: Icon(
                LucideIcons.chevronRight,
                size: 14,
                color: _hovered
                    ? AppColors.accent
                    : (isDark ? AppColors.textMuted : AppColors.textSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
