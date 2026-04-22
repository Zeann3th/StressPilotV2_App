import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/projects/domain/models/flow.dart' as flow_domain;
import 'package:stress_pilot/features/endpoints/domain/models/endpoint.dart';
import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/features/endpoints/presentation/provider/endpoint_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/workspace_tab_provider.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/workspace_nav_bar.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/workspace_sidebar.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/workspace_tab_bar.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/workspace/workspace_canvas.dart';
import 'package:stress_pilot/features/endpoints/presentation/widgets/endpoint_editor.dart';

class ProjectWorkspacePage extends StatefulWidget {
  const ProjectWorkspacePage({super.key});

  @override
  State<ProjectWorkspacePage> createState() => _ProjectWorkspacePageState();
}

class _ProjectWorkspacePageState extends State<ProjectWorkspacePage> {
  int? _lastLoadedProjectId;

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

  @override
  Widget build(BuildContext context) {
    final activeTab = context.watch<WorkspaceTabProvider>().activeTab;
    final project = context.watch<ProjectProvider>().selectedProject;

    return Scaffold(
      backgroundColor: AppColors.baseBackground,
      body: Column(
        children: [
          const WorkspaceNavBar(),
          Expanded(
            child: Row(
              children: [
                const WorkspaceSidebar(),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: AppColors.divider)),
                    ),
                    child: Column(
                      children: [
                        const WorkspaceTabBar(),
                        if (project != null && project.environmentId != 0)
                          Container(
                            height: 28,
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: AppColors.divider)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                _EnvBadge(
                                  environmentId: project.environmentId,
                                  projectName: project.name,
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: _buildTabContent(activeTab),
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
    );
  }

  Widget _buildTabContent(WorkspaceTab? activeTab) {
    if (activeTab == null) {
      return const _EmptyTabState();
    }

    switch (activeTab.type) {
      case WorkspaceTabType.flow:
        return WorkspaceCanvas(selectedFlow: activeTab.data as flow_domain.Flow);
      case WorkspaceTabType.endpoint:
        return EndpointEditor(endpoint: activeTab.data as Endpoint);
    }
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

class _EnvBadge extends StatefulWidget {
  final int environmentId;
  final String projectName;

  const _EnvBadge({
    required this.environmentId,
    required this.projectName,
  });

  @override
  State<_EnvBadge> createState() => _EnvBadgeState();
}

class _EnvBadgeState extends State<_EnvBadge> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          AppNavigator.pushNamed(
            AppRouter.projectEnvironmentRoute,
            arguments: {
              'environmentId': widget.environmentId,
              'projectName': widget.projectName,
            },
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 3,
            horizontal: 8,
          ),
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.hoverItem : AppColors.elevatedSurface,
            borderRadius: AppRadius.br4,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.settings2,
                size: 12,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'ENV',
                style: AppTypography.codeSm.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
