import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/shared/presentation/widgets/app_topbar.dart';
import 'package:stress_pilot/features/projects/domain/models/flow.dart' as flow_domain;
import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/features/endpoints/presentation/provider/endpoint_provider.dart';
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
  int? _lastLoadedProjectId;
  bool _libraryCollapsed = false;

  bool _autoSelectPending = false;

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

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<FlowProvider>().clearFlow();
        context.read<FlowProvider>().loadFlows(projectId: project.id);
        context.read<EndpointProvider>().loadEndpoints(projectId: project.id);
      });
    }
  }

  void _maybeAutoSelect(
      List<flow_domain.Flow> flows,
      flow_domain.Flow? selectedFlow,
      ) {
    if (selectedFlow != null) return;
    if (flows.isEmpty) return;
    if (_autoSelectPending) return;

    _autoSelectPending = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSelectPending = false;
      if (!mounted) return;

      final provider = context.read<FlowProvider>();

      if (provider.selectedFlow != null) return;

      final latestFlows = provider.flows;
      if (latestFlows.isNotEmpty) {
        provider.selectFlow(latestFlows.first);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final project = context.watch<ProjectProvider>().selectedProject;

    final flows = context.watch<FlowProvider>().flows;
    final selectedFlow = context.watch<FlowProvider>().selectedFlow;

    _maybeAutoSelect(flows, selectedFlow);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          const AppTopBar(),

          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: AppRadius.br16,
                      border: Border.all(color: border.withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          offset: const Offset(0, 4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const WorkspaceCommandBar(),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: border.withValues(alpha: 0.1),
                          indent: 16,
                          endIndent: 16,
                        ),
                        WorkspaceFlowTabs(
                          selectedFlow: selectedFlow,
                          onFlowSelected: (f) {
                            if (f != null) {
                              context.read<FlowProvider>().selectFlow(f);
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          AnimatedSize(
                            duration: AppDurations.short,
                            curve: Curves.easeInOut,
                            child: _libraryCollapsed
                                ? const SizedBox.shrink()
                                : WorkspaceNodeLibrary(
                              projectId: project?.id ?? 0,
                              selectedFlow: selectedFlow,
                            ),
                          ),

                          _LibraryHandle(
                            collapsed: _libraryCollapsed,
                            onToggle: () => setState(
                                  () => _libraryCollapsed = !_libraryCollapsed,
                            ),
                            border: border,
                          ),

                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                borderRadius: AppRadius.br16,
                                border: Border.all(color: border.withValues(alpha: 0.3)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    offset: const Offset(0, 4),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: AppRadius.br16,
                                child: WorkspaceCanvas(selectedFlow: selectedFlow),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(
              duration: 400.ms,
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }
}

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
          width: 14,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.accent.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: AppRadius.br4,
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
                    : (isDark
                    ? AppColors.textMuted
                    : AppColors.textSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
