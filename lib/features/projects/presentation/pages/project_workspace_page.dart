import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/features/common/presentation/app_sidebar.dart';
import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/endpoint_provider.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final projectProvider = context.read<ProjectProvider>();
      final flowProvider = context.read<FlowProvider>();
      final endpointProvider = context.read<EndpointProvider>();

      projectProvider.loadProjects();

      if (projectProvider.selectedProject != null) {
        Future.microtask(() {
          _resetWorkspaceState();
          flowProvider.loadFlows(projectId: projectProvider.selectedProject!.id);
          endpointProvider.loadEndpoints(projectId: projectProvider.selectedProject!.id);
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final projectProvider = context.watch<ProjectProvider>();
    final flowProvider = context.read<FlowProvider>();
    final endpointProvider = context.read<EndpointProvider>();
    final currentProjectId = projectProvider.selectedProject?.id;
    // Always reset workspace and reload flows/endpoints when project changes
    _resetWorkspaceState();
    if (currentProjectId != null) {
      Future.microtask(() {
        flowProvider.loadFlows(projectId: currentProjectId);
        endpointProvider.loadEndpoints(projectId: currentProjectId);
        setState(() {}); // Trigger UI refresh
      });
    }
  }

  void _resetWorkspaceState() {
    _selectedFlow = null;
    _sidebarTab = SidebarTab.flows;
    // Reset other workspace state here if needed
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
                        onTabChanged: (tab) => setState(() => _sidebarTab = tab),
                        selectedFlow: _selectedFlow,
                        onFlowSelected: (flow) => setState(() => _selectedFlow = flow),
                      ),
                      Expanded(child: WorkspaceCanvas(selectedFlow: _selectedFlow)),
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
