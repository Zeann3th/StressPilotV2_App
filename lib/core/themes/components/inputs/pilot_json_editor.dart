import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/json.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';

class PilotJsonEditor extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;
  final String? hintText;
  final bool expands;

  const PilotJsonEditor({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.hintText,
    this.expands = true,
  });

  @override
  State<PilotJsonEditor> createState() => _PilotJsonEditorState();
}

class _PilotJsonEditorState extends State<PilotJsonEditor> {
  late CodeController _controller;
  Timer? _beautifyTimer;

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      text: widget.initialValue,
      language: json,
    );
    _controller.addListener(_handleChanged);
  }

  @override
  void dispose() {
    _beautifyTimer?.cancel();
    _controller.removeListener(_handleChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged() {
    widget.onChanged(_controller.text);
    _scheduleBeautify();
  }

  void _scheduleBeautify() {
    _beautifyTimer?.cancel();
    _beautifyTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      
      final text = _controller.text.trim();
      if (text.isEmpty) return;

      try {
        final decoded = jsonDecode(text);
        final pretty = const JsonEncoder.withIndent('  ').convert(decoded);
        
        if (pretty != _controller.text) {
          final selection = _controller.selection;
          
          // Only update if the text is valid JSON and actually changed
          _controller.removeListener(_handleChanged);
          _controller.value = TextEditingValue(
            text: pretty,
            selection: selection.isValid && selection.end <= pretty.length
                ? selection
                : TextSelection.collapsed(offset: pretty.length),
          );
          _controller.addListener(_handleChanged);
        }
      } catch (_) {
        // Silently ignore invalid JSON during typing
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.baseBackground,
        borderRadius: AppRadius.br8,
        border: Border.all(color: AppColors.divider),
      ),
      child: CodeTheme(
        data: CodeThemeData(
          styles: Theme.of(context).brightness == Brightness.dark
              ? monokaiSublimeTheme
              : githubTheme,
        ),
        child: CodeField(
          controller: _controller,
          expands: widget.expands,
          maxLines: widget.expands ? null : 10,
          minLines: widget.expands ? null : 1,
          gutterStyle: GutterStyle(
            showLineNumbers: true,
            showFoldingHandles: true,
            background: AppColors.sidebarBackground,
            textStyle: AppTypography.codeSm.copyWith(color: AppColors.textMuted),
          ),
          textStyle: AppTypography.code.copyWith(fontSize: 13),
        ),
      ),
    );
  }
}
