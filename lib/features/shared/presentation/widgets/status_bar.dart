import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
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
          _AgentToggle(isOpen: isAgentOpen, onToggle: onAgentToggle),
        ],
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onToggle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: widget.isOpen
                ? AppColors.accent.withValues(alpha: 0.15)
                : (_isHovered ? AppColors.hoverItem : Colors.transparent),
            borderRadius: AppRadius.br4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.sparkles,
                size: 11,
                color: widget.isOpen ? AppColors.accent : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Agent',
                style: AppTypography.caption.copyWith(
                  color: widget.isOpen ? AppColors.accent : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
