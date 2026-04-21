import 'dart:convert';
import 'package:flutter/material.dart';

class JsonViewer extends StatefulWidget {
  final Map<String, dynamic> json;
  final TextStyle? style;
  final String? searchQuery;
  final int activeMatchIndex;
  final Function(int)? onMatchesCountChanged;

  const JsonViewer({
    super.key,
    required this.json,
    this.style,
    this.searchQuery,
    this.activeMatchIndex = 0,
    this.onMatchesCountChanged,
  });

  @override
  State<JsonViewer> createState() => _JsonViewerState();
}

class _JsonViewerState extends State<JsonViewer> {
  final List<GlobalKey> _matchKeys = [];
  int _lastReportedCount = -1;

  @override
  void didUpdateWidget(JsonViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If only the active index changed, scroll to it
    if (widget.activeMatchIndex != oldWidget.activeMatchIndex &&
        widget.activeMatchIndex >= 0 &&
        widget.activeMatchIndex < _matchKeys.length) {
      _scrollToActiveMatch();
    }
    // If query or json changed, reset tracking and scroll will happen after next build
    if (widget.searchQuery != oldWidget.searchQuery || widget.json != oldWidget.json) {
       _lastReportedCount = -1;
    }
  }

  void _scrollToActiveMatch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.activeMatchIndex < 0 || widget.activeMatchIndex >= _matchKeys.length) return;
      
      final key = _matchKeys[widget.activeMatchIndex];
      final context = key.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: 0.5,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ALWAYS clear keys before generating new spans to avoid duplication
    _matchKeys.clear();
    
    final jsonString = const JsonEncoder.withIndent('  ').convert(widget.json);
    final spans = _highlightJson(jsonString, context);

    if (widget.onMatchesCountChanged != null) {
      final currentCount = _matchKeys.length;
      if (currentCount != _lastReportedCount) {
        _lastReportedCount = currentCount;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onMatchesCountChanged!(currentCount);
        });
      }
    }

    return SelectableText.rich(
      TextSpan(
        style: widget.style ??
            TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface,
            ),
        children: spans,
      ),
    );
  }

  List<InlineSpan> _highlightJson(String json, BuildContext context) {
    final List<InlineSpan> spans = [];
    final regex = RegExp(
      r'(?<key>".*?":)|(?<string>".*?")|(?<number>-?\d+(?:\.\d+)?)|(?<bool>true|false)|(?<null>null)',
    );

    int lastMatchEnd = 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final keyColor = isDark ? const Color(0xFF9CDCFE) : const Color(0xFF0451A5);
    final stringColor = isDark ? const Color(0xFFCE9178) : const Color(0xFFA31515);
    final numberColor = isDark ? const Color(0xFFB5CEA8) : const Color(0xFF098658);
    final keywordColor = isDark ? const Color(0xFF569CD6) : const Color(0xFF0000FF);

    for (final match in regex.allMatches(json)) {
      if (match.start > lastMatchEnd) {
        _addTextWithSearch(spans, json.substring(lastMatchEnd, match.start), null);
      }

      Color? color;
      if (match.namedGroup('key') != null) {
        color = keyColor;
      } else if (match.namedGroup('string') != null) {
        color = stringColor;
      } else if (match.namedGroup('number') != null) {
        color = numberColor;
      } else if (match.namedGroup('bool') != null) {
        color = keywordColor;
      } else if (match.namedGroup('null') != null) {
        color = keywordColor;
      }

      _addTextWithSearch(spans, match.group(0)!, color);
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < json.length) {
      _addTextWithSearch(spans, json.substring(lastMatchEnd), null);
    }

    return spans;
  }

  void _addTextWithSearch(List<InlineSpan> spans, String text, Color? color) {
    if (widget.searchQuery == null || widget.searchQuery!.isEmpty) {
      spans.add(TextSpan(text: text, style: color != null ? TextStyle(color: color) : null));
      return;
    }

    final query = widget.searchQuery!.toLowerCase();
    final lowerText = text.toLowerCase();
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(query, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start), style: color != null ? TextStyle(color: color) : null));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: color != null ? TextStyle(color: color) : null));
      }

      final matchText = text.substring(index, index + query.length);
      final matchIndex = _matchKeys.length;
      final key = GlobalKey();
      _matchKeys.add(key);

      final isActive = matchIndex == widget.activeMatchIndex;

      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          key: key,
          decoration: BoxDecoration(
            color: isActive 
              ? Colors.orange.withValues(alpha: 0.8) 
              : Colors.yellow.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            matchText,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 13,
              color: isActive ? Colors.black : color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ));

      start = index + query.length;
    }
  }
}
