import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';

class StatusBar extends StatelessWidget {
  final String? projectName;
  final bool isAgentOpen;
  final VoidCallback onAgentToggle;

  const StatusBar({
    super.key,
    this.projectName,
    required this.isAgentOpen,
    required this.onAgentToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      color: AppColors.sidebarBackground,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          if (projectName != null)
            Text(
              projectName!,
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),
          const Spacer(),
          _StatusIconButton(
            icon: LucideIcons.history,
            tooltip: 'Recent Runs',
            onTap: () => AppNavigator.pushNamed(AppRouter.recentRunsRoute),
          ),
          const SizedBox(width: 2),
          _AgentToggle(isOpen: isAgentOpen, onToggle: onAgentToggle),
        ],
      ),
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

class _AgentToggle extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onToggle;
  const _AgentToggle({required this.isOpen, required this.onToggle});

  @override
  State<_AgentToggle> createState() => _AgentToggleState();
}

class _AgentToggleState extends State<_AgentToggle> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Agent',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: widget.isOpen
                  ? AppColors.accent.withValues(alpha: 0.15)
                  : (_isHovered ? AppColors.hoverItem : Colors.transparent),
              borderRadius: AppRadius.br4,
            ),
            child: Icon(
              LucideIcons.sparkles,
              size: 12,
              color: widget.isOpen ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
