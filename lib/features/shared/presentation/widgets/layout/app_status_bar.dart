import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/system/app_state_manager.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';

import 'package:stress_pilot/features/endpoints/presentation/provider/endpoint_provider.dart';

class AppStatusBar extends StatelessWidget {
  final String? projectName;

  const AppStatusBar({
    super.key,
    this.projectName,
  });

  @override
  Widget build(BuildContext context) {
    final stateManager = context.watch<AppStateManager>();
    final endpointProvider = context.watch<EndpointProvider>();
    final isIndexing = stateManager.isRecovering('Backend Process');

    return Container(
      height: 22,
      color: AppColors.sidebarBackground,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Text(
            projectName ?? '<No Project Selected>',
            style: AppTypography.caption.copyWith(
              color: projectName != null ? AppColors.textSecondary : AppColors.textDisabled,
            ),
          ),
          const Spacer(),
          if (isIndexing) ...[
            const _IndexingIndicator(),
            const SizedBox(width: 8),
          ],
          _StatusIconButton(
            icon: LucideIcons.history,
            tooltip: 'Recent Runs',
            onTap: () => AppNavigator.pushNamed(AppRouter.recentRunsRoute),
          ),
          const SizedBox(width: 4),
          _StatusIconButton(
            icon: LucideIcons.terminal,
            tooltip: 'Toggle Response Panel',
            onTap: () => endpointProvider.toggleResponsePanel(),
          ),
        ],
      ),
    );
  }
}

class _IndexingIndicator extends StatefulWidget {
  const _IndexingIndicator();

  @override
  State<_IndexingIndicator> createState() => _IndexingIndicatorState();
}

class _IndexingIndicatorState extends State<_IndexingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RotationTransition(
          turns: _ctrl,
          child: Icon(LucideIcons.refreshCcw, size: 10, color: AppColors.accent),
        ),
        const SizedBox(width: 4),
        Text(
          'Indexing...',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _StatusIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _StatusIconButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  State<_StatusIconButton> createState() => _StatusIconButtonState();
}

class _StatusIconButtonState extends State<_StatusIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: _isHovered ? AppColors.hoverItem : Colors.transparent,
              borderRadius: AppRadius.br4,
            ),
            child: Icon(widget.icon, size: 12, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}
