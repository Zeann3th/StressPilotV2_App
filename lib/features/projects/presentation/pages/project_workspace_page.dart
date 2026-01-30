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
  int? _lastLoadedProjectId; 
  double _expandedWidth = 280.0; 

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return; 
      context.read<ProjectProvider>().loadProjects();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    
    
    
    final project = context.watch<ProjectProvider>().selectedProject;

    
    if (project != null && project.id != _lastLoadedProjectId) {
      _lastLoadedProjectId = project.id;
      _resetWorkspaceState();

      
      
      final flowProvider = context.read<FlowProvider>();
      final endpointProvider = context.read<EndpointProvider>();

      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        flowProvider.loadFlows(projectId: project.id);
        endpointProvider.loadEndpoints(projectId: project.id);
      });
    }
  }

  void _resetWorkspaceState() {
    
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
// Keep existing code
                    children: [
                      Consumer<ProjectProvider>(
                        builder: (context, projectProvider, child) {
                          final width = projectProvider.isSidebarCollapsed ? 60.0 : _expandedWidth;
                          return SizedBox(
                            width: width,
                            child: WorkspaceSidebar(
                              sidebarTab: _sidebarTab,
                              onTabChanged: (tab) =>
                                  setState(() => _sidebarTab = tab),
                              selectedFlow: _selectedFlow,
                              onFlowSelected: (flow) =>
                                  setState(() => _selectedFlow = flow),
                              isCollapsed: projectProvider.isSidebarCollapsed,
                            ),
                          );
                        }
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.resizeColumn,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onHorizontalDragUpdate: (details) {
                            final projectProvider = context.read<ProjectProvider>();
                            final currentWidth = projectProvider.isSidebarCollapsed ? 60.0 : _expandedWidth;
                            final newWidth = currentWidth + details.delta.dx;
                            
                            if (newWidth < 180) {
                              if (!projectProvider.isSidebarCollapsed) {
                                projectProvider.setSidebarCollapsed(true);
                              }
                            } else {
                              if (projectProvider.isSidebarCollapsed) {
                                projectProvider.setSidebarCollapsed(false);
                              }
                               setState(() {
                                _expandedWidth = newWidth.clamp(180.0, 600.0);
                              });
                            }
                          },
                          child: Container(
                            width: 8,
                            color: Colors.transparent,
                            alignment: Alignment.center,
                            child: Container(
                              width: 1,
                              color: Theme.of(context).colorScheme.outlineVariant,
                            ),
                          ),
                        ),
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
