import 'dart:convert';
import 'package:flutter/material.dart';

class JsonViewer extends StatelessWidget {
  final Map<String, dynamic> json;
  final TextStyle? style;

  const JsonViewer({super.key, required this.json, this.style});

  @override
  Widget build(BuildContext context) {
    // Generate pretty JSON string
    final jsonString = const JsonEncoder.withIndent('  ').convert(json);

    return SelectableText.rich(
      TextSpan(
        style:
            style ??
            TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface,
            ),
        children: _highlightJson(jsonString, context),
      ),
    );
  }

  List<TextSpan> _highlightJson(String json, BuildContext context) {
    final List<TextSpan> spans = [];
    final regex = RegExp(
      r'(?<key>".*?":)|(?<string>".*?")|(?<number>-?\d+(?:\.\d+)?)|(?<bool>true|false)|(?<null>null)',
    );

    int lastMatchEnd = 0;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final keyColor = isDark
        ? const Color(0xFF9CDCFE)
        : const Color(0xFF0451A5); // Blue
    final stringColor = isDark
        ? const Color(0xFFCE9178)
        : const Color(0xFFA31515); // Orange/Red
    final numberColor = isDark
        ? const Color(0xFFB5CEA8)
        : const Color(0xFF098658); // Green
    final keywordColor = isDark
        ? const Color(0xFF569CD6)
        : const Color(0xFF0000FF); // Blue

    for (final match in regex.allMatches(json)) {
      // Add non-matching text (brackets, braces, commas, whitespace)
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: json.substring(lastMatchEnd, match.start)));
      }

      if (match.namedGroup('key') != null) {
        spans.add(
          TextSpan(
            text: match.group(0),
            style: TextStyle(color: keyColor),
          ),
        );
      } else if (match.namedGroup('string') != null) {
        spans.add(
          TextSpan(
            text: match.group(0),
            style: TextStyle(color: stringColor),
          ),
        );
      } else if (match.namedGroup('number') != null) {
        spans.add(
          TextSpan(
            text: match.group(0),
            style: TextStyle(color: numberColor),
          ),
        );
      } else if (match.namedGroup('bool') != null) {
        spans.add(
          TextSpan(
            text: match.group(0),
            style: TextStyle(color: keywordColor),
          ),
        );
      } else if (match.namedGroup('null') != null) {
        spans.add(
          TextSpan(
            text: match.group(0),
            style: TextStyle(color: keywordColor),
          ),
        );
      }

      lastMatchEnd = match.end;
    }

    // Add remaining text
    if (lastMatchEnd < json.length) {
      spans.add(TextSpan(text: json.substring(lastMatchEnd)));
    }

    return spans;
  }
}
