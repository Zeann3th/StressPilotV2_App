import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/features/common/presentation/app_sidebar.dart';
import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/features/common/presentation/provider/endpoint_provider.dart';
import 'package:stress_pilot/features/projects/domain/flow.dart' as flow;
import 'package:stress_pilot/features/projects/presentation/widgets/workspace/workspace_topbar.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/workspace/workspace_sidebar.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/workspace/workspace_canvas.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/workspace/workspace_flow_list.dart';

class ProjectWorkspacePage extends StatefulWidget {
  const ProjectWorkspacePage({super.key});

  @override
  State<ProjectWorkspacePage> createState() => _ProjectWorkspacePageState();
}

class _ProjectWorkspacePageState extends State<ProjectWorkspacePage> {
  flow.Flow? _selectedFlow;
  SidebarTab _sidebarTab = SidebarTab.flows;
  int? _lastLoadedProjectId; // Track the last ID to prevent loops

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback for one-time initialization actions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return; // Always check mounted
      context.read<ProjectProvider>().loadProjects();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // We use watch() here to listen to changes.
    // Note: This will trigger on ANY change in ProjectProvider, but our guard clause below
    // ensures we only act when the project ID actually changes.
    final project = context.watch<ProjectProvider>().selectedProject;

    // GUARD CLAUSE: Only load if the ID has actually changed
    if (project != null && project.id != _lastLoadedProjectId) {
      _lastLoadedProjectId = project.id;
      _resetWorkspaceState();

      // Perform data loading
      // We don't need Future.microtask here if loadFlows is properly async and doesn't notify immediately during build
      final flowProvider = context.read<FlowProvider>();
      final endpointProvider = context.read<EndpointProvider>();

      // Execute after the current build frame is done to be safe
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        flowProvider.loadFlows(projectId: project.id);
        endpointProvider.loadEndpoints(projectId: project.id);
      });
    }
  }

  void _resetWorkspaceState() {
    // No need to setState here if called during didChangeDependencies/build phase
    _selectedFlow = null;
    _sidebarTab = SidebarTab.flows;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Row(
        children: [
          const AppSidebar(),
          Expanded(
            child: Column(
              children: [
                const WorkspaceTopBar(),
                Expanded(
                  child: Row(
                    children: [
                      WorkspaceSidebar(
                        sidebarTab: _sidebarTab,
                        onTabChanged: (tab) =>
                            setState(() => _sidebarTab = tab),
                        selectedFlow: _selectedFlow,
                        onFlowSelected: (flow) =>
                            setState(() => _selectedFlow = flow),
                      ),
                      Expanded(
                        child: WorkspaceCanvas(selectedFlow: _selectedFlow),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
