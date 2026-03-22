import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/agent/domain/models/agent_message.dart';

class AgentMessageBubble extends StatelessWidget {
  final AgentMessage message;

  const AgentMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return switch (message.role) {
      MessageRole.user => _UserBubble(message: message),
      MessageRole.agent => _AgentBubble(message: message),
      MessageRole.system => _SystemBubble(message: message),
      MessageRole.tool => _SystemBubble(message: message),
    };
  }
}

class _UserBubble extends StatelessWidget {
  final AgentMessage message;
  const _UserBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(left: 64, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.darkGreenStart.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: const Radius.circular(4),
          ),
          border: Border.all(color: AppColors.darkGreenStart.withValues(alpha: 0.2)),
        ),
        child: Text(
          message.content,
          style: AppTypography.body,
        ),
      ),
    );
  }
}

class _AgentBubble extends StatelessWidget {
  final AgentMessage message;
  const _AgentBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(right: 64, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: const Radius.circular(4),
          ),
          border: Border.all(color: border.withValues(alpha: 0.3)),
        ),
        child: message.status == MessageStatus.thinking
            ? _ThinkingIndicator()
            : MarkdownBody(
          data: message.content,
          styleSheet: MarkdownStyleSheet(
            p: AppTypography.body,
            code: AppTypography.body.copyWith(
              fontFamily: 'JetBrains Mono',
              fontSize: 12,
              backgroundColor: Colors.transparent,
            ),
            codeblockDecoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            blockquoteDecoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: AppColors.darkGreenStart,
                  width: 3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThinkingIndicator extends StatefulWidget {
  @override
  State<_ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<_ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final offset = ((_controller.value + i / 3) % 1.0);
              final dy = -4 * (1 - (offset * 2 - 1).abs().clamp(0.0, 1.0));
              return Transform.translate(
                offset: Offset(0, dy),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.darkGreenStart.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class _SystemBubble extends StatelessWidget {
  final AgentMessage message;
  const _SystemBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isError = message.status == MessageStatus.error;
    final color = isError ? Colors.red : Colors.grey;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Text(
          message.content,
          style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8)),
        ),
      ),
    );
  }
}
