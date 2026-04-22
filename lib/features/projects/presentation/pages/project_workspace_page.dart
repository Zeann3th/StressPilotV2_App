import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/projects/domain/models/flow.dart' as flow_domain;
import 'package:stress_pilot/features/projects/domain/models/project.dart';
import 'package:stress_pilot/features/endpoints/domain/models/endpoint.dart';
import 'package:stress_pilot/features/shared/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/shared/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/features/shared/presentation/provider/endpoint_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/workspace_tab_provider.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/workspace_nav_bar.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/workspace_sidebar.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/workspace_tab_bar.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/workspace/workspace_canvas.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/run_flow_dialog.dart';
import 'package:stress_pilot/features/shared/presentation/widgets/endpoint_editor.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/recent_pages_widget.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/project/project_dialog.dart';

class ProjectWorkspacePage extends StatefulWidget {
  const ProjectWorkspacePage({super.key});

  @override
  State<ProjectWorkspacePage> createState() => _ProjectWorkspacePageState();
}

class _ProjectWorkspacePageState extends State<ProjectWorkspacePage> {
  int? _lastLoadedProjectId;
  double _sidebarWidth = 260;
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
            child: project == null
                ? const _ProjectSelectionView()
                : Row(
                    children: [
                      WorkspaceSidebar(width: _sidebarWidth),
                      // Drag handle between sidebar and content
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
                              child: Container(
                                width: 1,
                                color: AppColors.divider,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xs),
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
                                _ActionBar(
                                  project: project,
                                  activeTab: activeTab,
                                ),
                                Expanded(
                                  child: _buildTabContent(activeTab),
                                ),
                              ],
                            ),
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

class _ActionBar extends StatelessWidget {
  final Project project;
  final WorkspaceTab? activeTab;

  const _ActionBar({required this.project, required this.activeTab});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.sidebarBackground,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _PlayStopButton(project: project, activeTab: activeTab),
          const SizedBox(width: AppSpacing.xs),
          if (project.environmentId != 0)
            _EnvIconButton(
              environmentId: project.environmentId,
              projectName: project.name,
            ),
        ],
      ),
    );
  }
}

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
          child: Container(
            width: 28,
            height: 24,
            decoration: BoxDecoration(
              color: _isHovered ? AppColors.hoverItem : Colors.transparent,
              borderRadius: AppRadius.br4,
            ),
            child: Icon(
              LucideIcons.settings2,
              size: 14,
              color: _isHovered ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayStopButton extends StatefulWidget {
  final Project project;
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

    final bool canAct = widget.activeTab != null;
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
            width: 28,
            height: 24,
            decoration: BoxDecoration(
              color: _isHovered && canAct ? AppColors.hoverItem : Colors.transparent,
              borderRadius: AppRadius.br4,
            ),
            child: Icon(icon, size: 14, color: iconColor),
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

class _ProjectSelectionView extends StatefulWidget {
  const _ProjectSelectionView();

  @override
  State<_ProjectSelectionView> createState() => _ProjectSelectionViewState();
}

class _ProjectSelectionViewState extends State<_ProjectSelectionView> {
  final _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final projects = provider.projects.where((p) =>
        p.name.toLowerCase().contains(_searchCtrl.text.toLowerCase())).toList();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Projects',
                style: AppTypography.heading.copyWith(fontSize: 24),
              ),
              const Spacer(),
              SizedBox(
                width: 300,
                child: PilotInput(
                  controller: _searchCtrl,
                  placeholder: 'Search projects...',
                  prefixIcon: LucideIcons.search,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              PilotButton.primary(
                label: 'New Project',
                icon: LucideIcons.plus,
                onPressed: () => _onNewProject(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (provider.isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (projects.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.folderX, size: 48, color: AppColors.textDisabled),
                    const SizedBox(height: 16),
                    Text('No projects found', style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              flex: 2,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  mainAxisExtent: 100,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final p = projects[index];
                  return _ProjectCard(project: p);
                },
              ),
            ),
          const SizedBox(height: 32),
          Text(
            'Recent Activity',
            style: AppTypography.heading.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 16),
          const Expanded(
            flex: 1,
            child: _RecentActivitySummary(),
          ),
        ],
      ),
    );
  }

  void _onNewProject(BuildContext context) {
    ProjectDialogs.showCreateDialog(
      context,
      onCreate: (name, description) async {
        final provider = context.read<ProjectProvider>();
        final project = await provider.createProject(
          name: name,
          description: description,
        );
        await provider.selectProject(project);
      },
    );
  }
}

class _ProjectCard extends StatefulWidget {
  final Project project;
  const _ProjectCard({required this.project});

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => context.read<ProjectProvider>().selectProject(widget.project),
        child: AnimatedContainer(
          duration: AppDurations.short,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.hoverItem : AppColors.sidebarBackground,
            borderRadius: AppRadius.br8,
            border: Border.all(
              color: _isHovered ? AppColors.accent.withValues(alpha: 0.5) : AppColors.border,
            ),
            boxShadow: _isHovered ? AppShadows.subtle : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.project.name,
                style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                widget.project.description.isEmpty ? 'No description' : widget.project.description,
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentActivitySummary extends StatelessWidget {
  const _RecentActivitySummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sidebarBackground,
        borderRadius: AppRadius.br8,
        border: Border.all(color: AppColors.border),
      ),
      child: const RecentPagesWidget(),
    );
  }
}
