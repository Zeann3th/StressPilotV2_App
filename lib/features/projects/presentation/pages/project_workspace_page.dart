import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/agent/presentation/pages/agent_page.dart' show AgentTerminalView;
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
import 'package:stress_pilot/features/projects/presentation/widgets/recent_pages_widget.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/project/project_dialog.dart';
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
            child: project == null
                ? const _ProjectSelectionView()
                : BottomPanelShell(
                    isOpen: _isAgentOpen,
                    panel: const _AgentPanel(),
                    body: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Row(
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
                                width: 6,
                                color: Colors.transparent,
                                child: Center(
                                  child: Container(width: 1, color: AppColors.divider),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
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
                        ],
                      ),
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

// Shown when no project is selected — project picker + recent activity
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
          Text('Recent Activity', style: AppTypography.heading.copyWith(fontSize: 18)),
          const SizedBox(height: 16),
          const Expanded(flex: 1, child: _RecentActivitySummary()),
        ],
      ),
    );
  }

  void _onNewProject(BuildContext context) {
    ProjectDialogs.showCreateDialog(
      context,
      onCreate: (name, description) async {
        final provider = context.read<ProjectProvider>();
        final project = await provider.createProject(name: name, description: description);
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
