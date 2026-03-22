import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/agent/domain/models/agent_message.dart';

class AgentToolDialog extends StatefulWidget {
  final List<ToolCall> toolCalls;
  final void Function(bool approved, String feedback) onResult;

  const AgentToolDialog({
    super.key,
    required this.toolCalls,
    required this.onResult,
  });

  static Future<void> show(
      BuildContext context, {
        required List<ToolCall> toolCalls,
        required void Function(bool approved, String feedback) onResult,
      }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AgentToolDialog(toolCalls: toolCalls, onResult: onResult),
    );
  }

  @override
  State<AgentToolDialog> createState() => _AgentToolDialogState();
}

class _AgentToolDialogState extends State<AgentToolDialog> {
  int _selectedIndex = 0;
  final _feedbackController = TextEditingController();
  bool _showFeedback = false;

  // Options: 0=Approve, 1=Reject, 2=Feedback
  final _options = ['Approve', 'Reject', 'Give feedback'];

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.keyW) {
      setState(() => _selectedIndex = (_selectedIndex - 1).clamp(0, _options.length - 1));
    } else if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.keyS) {
      setState(() => _selectedIndex = (_selectedIndex + 1).clamp(0, _options.length - 1));
    } else if (key == LogicalKeyboardKey.enter) {
      _confirm();
    } else if (key == LogicalKeyboardKey.escape) {
      widget.onResult(false, '');
      Navigator.of(context).pop();
    }
  }

  void _confirm() {
    if (_selectedIndex == 0) {
      widget.onResult(true, '');
      Navigator.of(context).pop();
    } else if (_selectedIndex == 1) {
      widget.onResult(false, '');
      Navigator.of(context).pop();
    } else {
      if (_showFeedback) {
        final feedback = _feedbackController.text.trim();
        widget.onResult(false, feedback);
        Navigator.of(context).pop();
      } else {
        setState(() => _showFeedback = true);
      }
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: _handleKeyEvent,
      child: Dialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.br16),
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  const Icon(LucideIcons.wrench, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text('Tool Call Approval', style: AppTypography.heading.copyWith(fontSize: 15)),
                ],
              ),
              const SizedBox(height: 16),

              // Tool calls list
              ...widget.toolCalls.map((tc) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.05),
                  borderRadius: AppRadius.br8,
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tc.name,
                      style: AppTypography.body.copyWith(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 12,
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (tc.args.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        const JsonEncoder.withIndent('  ').convert(tc.args),
                        style: AppTypography.body.copyWith(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 11,
                          color: border,
                        ),
                      ),
                    ],
                  ],
                ),
              )),

              const SizedBox(height: 16),

              // Options — keyboard navigable
              Text(
                'Use ↑↓ or W/S to navigate, Enter to select, Esc to cancel',
                style: TextStyle(fontSize: 11, color: border),
              ),
              const SizedBox(height: 8),

              ..._options.asMap().entries.map((e) {
                final selected = e.key == _selectedIndex;
                final (icon, color) = switch (e.key) {
                  0 => (LucideIcons.check, AppColors.darkGreenStart),
                  1 => (LucideIcons.x, Colors.red),
                  _ => (LucideIcons.messageSquare, Colors.blue),
                };
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedIndex = e.key);
                    _confirm();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? color.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: AppRadius.br8,
                      border: Border.all(
                        color: selected
                            ? color.withValues(alpha: 0.4)
                            : border.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, size: 14, color: selected ? color : border),
                        const SizedBox(width: 10),
                        Text(
                          e.value,
                          style: AppTypography.body.copyWith(
                            color: selected ? color : null,
                            fontWeight: selected ? FontWeight.w600 : null,
                          ),
                        ),
                        if (selected) ...[
                          const Spacer(),
                          Icon(LucideIcons.cornerDownLeft, size: 12, color: color),
                        ],
                      ],
                    ),
                  ),
                );
              }),

              // Feedback input (shown when "Give feedback" selected)
              if (_showFeedback) ...[
                const SizedBox(height: 12),
                ShadInput(
                  controller: _feedbackController,
                  placeholder: const Text('Your instructions to the agent...'),
                  autofocus: true,
                  maxLines: 3,
                  minLines: 1,
                ),
                const SizedBox(height: 8),
                PilotButton.primary(
                  label: 'Send feedback',
                  onPressed: _confirm,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
