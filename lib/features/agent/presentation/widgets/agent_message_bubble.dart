import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/agent/domain/models/agent_message.dart';

class AgentMessageBubble extends StatelessWidget {
  final AgentMessage message;

  const AgentMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return switch (message.role) {
      MessageRole.user   => _UserBubble(message: message),
      MessageRole.agent  => _AgentBubble(message: message),
      MessageRole.system => _SystemBubble(message: message),
      MessageRole.tool   => _SystemBubble(message: message),
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
          color: AppColors.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: const Radius.circular(4),
          ),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
        ),
        child: Text(message.content, style: AppTypography.body),
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
    final surface = AppColors.surface;
    final border = AppColors.border;

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
            ? const _ThinkingIndicator()
            : _MarkdownContent(content: message.content, isDark: isDark, border: border),
      ),
    );
  }
}

class _MarkdownContent extends StatelessWidget {
  final String content;
  final bool isDark;
  final Color border;

  const _MarkdownContent({
    required this.content,
    required this.isDark,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: content,
      selectable: true,

      extensionSet: md.ExtensionSet(
        [
          ...md.ExtensionSet.gitHubFlavored.blockSyntaxes,
        ],
        [
          ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
        ],
      ),
      builders: {

        'table': _TableBuilder(isDark: isDark, border: border),
      },
      styleSheet: MarkdownStyleSheet(

        p: AppTypography.body,
        pPadding: const EdgeInsets.only(bottom: 4),

        h1: AppTypography.heading.copyWith(fontSize: 20),
        h2: AppTypography.heading.copyWith(fontSize: 17),
        h3: AppTypography.heading.copyWith(fontSize: 15),
        h1Padding: const EdgeInsets.only(top: 8, bottom: 4),
        h2Padding: const EdgeInsets.only(top: 6, bottom: 4),
        h3Padding: const EdgeInsets.only(top: 4, bottom: 2),

        code: AppTypography.body.copyWith(
          fontFamily: 'JetBrains Mono',
          fontSize: 12,
          backgroundColor: Colors.transparent,
          color: AppColors.accent,
        ),
        codeblockDecoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border.withValues(alpha: 0.2)),
        ),
        codeblockPadding: const EdgeInsets.all(12),

        blockquote: AppTypography.body.copyWith(
          color: AppColors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: AppColors.accent, width: 3),
          ),
        ),
        blockquotePadding: const EdgeInsets.only(left: 12, top: 2, bottom: 2),

        listBullet: AppTypography.body,
        listIndent: 20,
        listBulletPadding: const EdgeInsets.only(right: 8),

        tableHead: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
        tableBody: AppTypography.body,
        tableBorder: TableBorder.all(
          color: border.withValues(alpha: 0.2),
          width: 1,
          borderRadius: BorderRadius.circular(8),
        ),
        tableHeadAlign: TextAlign.left,
        tableCellsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        tableColumnWidth: const FlexColumnWidth(),

        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: border.withValues(alpha: 0.2), width: 1),
          ),
        ),

        strong: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
        em: AppTypography.body.copyWith(fontStyle: FontStyle.italic),
      ),
    );
  }
}

class _TableBuilder extends MarkdownElementBuilder {
  final bool isDark;
  final Color border;

  _TableBuilder({required this.isDark, required this.border});

  @override
  Widget? visitElementAfterWithContext(
      BuildContext context,
      md.Element element,
      TextStyle? preferredStyle,
      TextStyle? parentStyle,
      ) {
    if (element.tag != 'table') return null;

    final headRows = <List<String>>[];
    final bodyRows = <List<String>>[];

    for (final child in element.children ?? []) {
      if (child is md.Element) {
        if (child.tag == 'thead') {
          for (final row in child.children ?? []) {
            if (row is md.Element && row.tag == 'tr') {
              headRows.add(_extractCells(row));
            }
          }
        } else if (child.tag == 'tbody') {
          for (final row in child.children ?? []) {
            if (row is md.Element && row.tag == 'tr') {
              bodyRows.add(_extractCells(row));
            }
          }
        }
      }
    }

    if (headRows.isEmpty && bodyRows.isEmpty) return null;

    return _StyledTable(
      headRows: headRows,
      bodyRows: bodyRows,
      isDark: isDark,
      border: border,
    );
  }

  List<String> _extractCells(md.Element row) {
    final cells = <String>[];
    for (final child in row.children ?? []) {
      if (child is md.Element && (child.tag == 'th' || child.tag == 'td')) {
        cells.add(child.textContent);
      }
    }
    return cells;
  }
}

class _StyledTable extends StatelessWidget {
  final List<List<String>> headRows;
  final List<List<String>> bodyRows;
  final bool isDark;
  final Color border;

  const _StyledTable({
    required this.headRows,
    required this.bodyRows,
    required this.isDark,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    final colCount = headRows.isNotEmpty
        ? headRows.first.length
        : bodyRows.isNotEmpty
        ? bodyRows.first.length
        : 0;

    if (colCount == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border.withValues(alpha: 0.2)),
        color: AppColors.surface,
      ),
      clipBehavior: Clip.hardEdge,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          border: TableBorder(
            horizontalInside: BorderSide(color: border.withValues(alpha: 0.15)),
            verticalInside: BorderSide(color: border.withValues(alpha: 0.15)),
          ),
          children: [

            ...headRows.map((cells) => TableRow(
              decoration: BoxDecoration(
                color: AppColors.textPrimary.withValues(alpha: 0.04),
              ),
              children: cells.map((cell) => _HeaderCell(text: cell)).toList(),
            )),

            ...bodyRows.asMap().entries.map((e) => TableRow(
              decoration: BoxDecoration(
                color: e.key.isOdd
                    ? AppColors.textPrimary.withValues(alpha: 0.02)
                    : Colors.transparent,
              ),
              children: e.value.map((cell) => _BodyCell(text: cell)).toList(),
            )),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        text,
        style: AppTypography.body.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  final String text;
  const _BodyCell({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        text,
        style: AppTypography.body.copyWith(fontSize: 12),
      ),
    );
  }
}

class _ThinkingIndicator extends StatefulWidget {
  const _ThinkingIndicator();

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
            builder: (_, _) {
              final offset = ((_controller.value + i / 3) % 1.0);
              final dy = -4 * (1 - (offset * 2 - 1).abs().clamp(0.0, 1.0));
              return Transform.translate(
                offset: Offset(0, dy),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.7),
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
