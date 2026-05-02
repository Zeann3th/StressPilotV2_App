import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/recent_pages_widget.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/projects_sidebar.dart';
import 'package:stress_pilot/features/shared/presentation/widgets/global_search_dropdown.dart';
import 'package:stress_pilot/features/shared/presentation/widgets/layout/app_nav_bar.dart';
import 'package:stress_pilot/features/shared/presentation/widgets/layout/app_status_bar.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final ValueNotifier<double> _sidebarWidth = ValueNotifier(260.0);
  bool _isSidebarOpen = true;

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
  void dispose() {
    _sidebarWidth.dispose();
    super.dispose();
  }

  void _toggleSidebar() => setState(() => _isSidebarOpen = !_isSidebarOpen);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.baseBackground,
      body: Column(
        children: [
          AppNavBar(
            onToggleSidebar: _toggleSidebar,
            isSidebarOpen: _isSidebarOpen,
            center: const SizedBox(
              width: 400,
              child: GlobalSearchDropdown(),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isSidebarOpen) ...[
                    ValueListenableBuilder<double>(
                      valueListenable: _sidebarWidth,
                      builder: (context, width, child) {
                        return Row(
                          children: [
                            ProjectsSidebar(width: width),
                            // Drag handle
                            MouseRegion(
                              cursor: SystemMouseCursors.resizeColumn,
                              child: GestureDetector(
                                onHorizontalDragUpdate: (details) {
                                  _sidebarWidth.value = (_sidebarWidth.value + details.delta.dx)
                                      .clamp(_minSidebarWidth, _maxSidebarWidth);
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
                          ],
                        );
                      },
                    ),
                  ],
                  
                  // Main Content: Recent Activity
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: 600,
                        child: const RecentPagesWidget(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const AppStatusBar(projectName: null),
        ],
      ),
    );
  }
}
