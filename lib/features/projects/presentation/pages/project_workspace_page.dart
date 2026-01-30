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
  double? _dragWidth; 

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
                          // If dragging, use drag width. Else use state width.
                          final currentWidth = projectProvider.isSidebarCollapsed ? 60.0 : _expandedWidth;
                          final width = _dragWidth ?? currentWidth;
                          
                          return SizedBox(
                            width: width,
                            child: WorkspaceSidebar(
                              sidebarTab: _sidebarTab,
                              onTabChanged: (tab) =>
                                  setState(() => _sidebarTab = tab),
                              selectedFlow: _selectedFlow,
                              onFlowSelected: (flow) =>
                                  setState(() => _selectedFlow = flow),
                              isCollapsed: width < 180,
                            ),
                          );
                        }
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.resizeColumn,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onHorizontalDragStart: (details) {
                            final projectProvider = context.read<ProjectProvider>();
                            setState(() {
                              _dragWidth = projectProvider.isSidebarCollapsed ? 60.0 : _expandedWidth;
                            });
                          },
                          onHorizontalDragUpdate: (details) {
                            setState(() {
                              if (_dragWidth == null) return;
                              // Allow dragging bigger, min 60. Max 600.
                              _dragWidth = (_dragWidth! + details.delta.dx).clamp(60.0, 600.0);
                            });
                          },
                          onHorizontalDragEnd: (details) {
                            final projectProvider = context.read<ProjectProvider>();
                            if (_dragWidth != null) {
                                if (_dragWidth! < 180) {
                                  projectProvider.setSidebarCollapsed(true);
                                } else {
                                  projectProvider.setSidebarCollapsed(false);
                                  _expandedWidth = _dragWidth!;
                                }
                            }
                            setState(() {
                              _dragWidth = null;
                            });
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
