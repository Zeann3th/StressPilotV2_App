import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/shared/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/recent_pages_widget.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/runs_list_widget.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/project/project_dialog.dart';

class RecentActivityPage extends StatefulWidget {
  const RecentActivityPage({super.key});

  @override
  State<RecentActivityPage> createState() => _RecentActivityPageState();
}

class _RecentActivityPageState extends State<RecentActivityPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProjectProvider>().loadProjects();
    });
  }

  void _onNewProject() {
    ProjectDialogs.showCreateDialog(
      context,
      onCreate: (name, description) async {
        final provider = context.read<ProjectProvider>();
        final project = await provider.createProject(
          name: name,
          description: description,
        );
        await provider.selectProject(project);
        AppNavigator.pushReplacementNamed(AppRouter.workspaceRoute);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.baseBackground,
      body: Column(
        children: [

          Container(
            height: AppSpacing.navBarHeight,
            decoration: BoxDecoration(
              color: AppColors.baseBackground,
              border: Border(
                bottom: BorderSide(color: AppColors.divider, width: 1),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Text(
                  'StressPilot',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                _NewProjectButton(onTap: _onNewProject),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: AppSpacing.pagePadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  Expanded(
                    flex: 2,
                    child: _PanelContainer(
                      child: const Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: RecentPagesWidget(),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),

                  Expanded(
                    flex: 1,
                    child: ClipRRect(
                      borderRadius: AppRadius.br6,
                      child: _PanelContainer(
                        child: const RunsListWidget(flowId: null),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelContainer extends StatelessWidget {
  final Widget child;

  const _PanelContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sidebarBackground,
        borderRadius: AppRadius.br6,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }
}

class _NewProjectButton extends StatefulWidget {
  final VoidCallback onTap;

  const _NewProjectButton({required this.onTap});

  @override
  State<_NewProjectButton> createState() => _NewProjectButtonState();
}

class _NewProjectButtonState extends State<_NewProjectButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.short,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.accentHover : AppColors.accent,
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, size: 14, color: Colors.white),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'New Project',
                style: AppTypography.body.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
