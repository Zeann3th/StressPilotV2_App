import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/agent/domain/repositories/agent_repository.dart';

class AgentHeader extends StatelessWidget {
  final AgentState state;
  final VoidCallback onBack;
  final VoidCallback onNewSession;

  const AgentHeader({
    super.key,
    required this.state,
    required this.onBack,
    required this.onNewSession,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          PilotButton.ghost(
            icon: LucideIcons.chevronLeft,
            onPressed: onBack,
          ),
          const SizedBox(width: 8),
          const Icon(LucideIcons.sparkles, size: 18, color: AppColors.darkGreenStart),
          const SizedBox(width: 12),
          Text('StressPilot AI Agent', style: AppTypography.heading.copyWith(fontSize: 16)),
          const SizedBox(width: 12),
          _StatusDot(state: state),
          const Spacer(),
          PilotButton.ghost(
            icon: LucideIcons.squarePen,
            onPressed: onNewSession,
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final AgentState state;
  const _StatusDot({required this.state});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (state) {
      AgentState.ready => (AppColors.darkGreenStart, 'Ready'),
      AgentState.thinking => (Colors.amber, 'Thinking'),
      AgentState.starting => (Colors.blue, 'Starting'),
      AgentState.pendingApproval => (Colors.orange, 'Approval needed'),
      AgentState.error => (Colors.red, 'Error'),
      AgentState.idle => (Colors.grey, 'Idle'),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}
