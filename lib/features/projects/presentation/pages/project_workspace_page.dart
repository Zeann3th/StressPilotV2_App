import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/agent/presentation/pages/agent_page.dart' show AgentTerminalView;
import 'package:stress_pilot/features/projects/domain/models/flow.dart' as flow_domain;
import 'package:stress_pilot/features/endpoints/domain/models/endpoint.dart';
import 'package:stress_pilot/features/shared/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/shared/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/features/shared/presentation/provider/endpoint_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/workspace_tab_provider.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/workspace_nav_bar.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/workspace_sidebar.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/workspace_tab_bar.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/workspace/workspace_canvas.dart';
import 'package:stress_pilot/features/shared/presentation/widgets/bottom_panel_shell.dart';
import 'package:stress_pilot/features/shared/presentation/widgets/endpoint_editor.dart';
import 'package:stress_pilot/features/shared/presentation/widgets/status_bar.dart';

class ProjectWorkspacePage extends StatefulWidget {
  const ProjectWorkspacePage({super.key});

  @override
  State<ProjectWorkspacePage> createState() => _ProjectWorkspacePageState();
}

class _ProjectWorkspacePageState extends State<ProjectWorkspacePage> {
  int? _lastLoadedProjectId;
  double _sidebarWidth = 260;
  bool _isAgentOpen = false;

  static const double _minSidebarWidth = 180;
  static const double _maxSidebarWidth = 480;

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
        context.read<WorkspaceTabProvider>().clear();
      });
    }
  }

  void _toggleAgent() => setState(() => _isAgentOpen = !_isAgentOpen);

  @override
  Widget build(BuildContext context) {
    final activeTab = context.watch<WorkspaceTabProvider>().activeTab;
    final project = context.watch<ProjectProvider>().selectedProject;

    return Scaffold(
      backgroundColor: AppColors.baseBackground,
      body: Column(
        children: [
          WorkspaceNavBar(onAgentPressed: _toggleAgent),
          Expanded(
            child: BottomPanelShell(
              isOpen: _isAgentOpen,
              panel: const _AgentPanel(),
              body: Row(
                children: [
                  WorkspaceSidebar(width: _sidebarWidth),
                  // Drag handle
                  MouseRegion(
                    cursor: SystemMouseCursors.resizeColumn,
                    child: GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          _sidebarWidth = (_sidebarWidth + details.delta.dx)
                              .clamp(_minSidebarWidth, _maxSidebarWidth);
                        });
                      },
                      child: Container(
                        width: 4,
                        color: Colors.transparent,
                        child: Center(
                          child: Container(width: 1, color: AppColors.divider),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.baseBackground,
                          borderRadius: AppRadius.br6,
                          border: Border.all(color: AppColors.border),
                          boxShadow: AppShadows.subtle,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            const WorkspaceTabBar(),
                            Expanded(child: _buildTabContent(activeTab)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          StatusBar(
            projectName: project?.name,
            isAgentOpen: _isAgentOpen,
            onAgentToggle: _toggleAgent,
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(WorkspaceTab? activeTab) {
    if (activeTab == null) return const _EmptyTabState();

    switch (activeTab.type) {
      case WorkspaceTabType.flow:
        return WorkspaceCanvas(selectedFlow: activeTab.data as flow_domain.Flow);
      case WorkspaceTabType.endpoint:
        return EndpointEditor(endpoint: activeTab.data as Endpoint);
    }
  }
}

// Agent panel embeds the terminal view without Scaffold/AppBar
class _AgentPanel extends StatelessWidget {
  const _AgentPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.sidebarBackground,
      child: Column(
        children: [
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.sidebarBackground,
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.sparkles, size: 14, color: AppColors.accent),
                const SizedBox(width: 6),
                Text('Agent', style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary)),
              ],
            ),
          ),
          const Expanded(child: AgentTerminalView()),
        ],
      ),
    );
  }
}

class _EmptyTabState extends StatelessWidget {
  const _EmptyTabState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.layoutDashboard, size: 48, color: AppColors.textDisabled),
          const SizedBox(height: 16),
          Text(
            'Select an endpoint or open a flow',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
