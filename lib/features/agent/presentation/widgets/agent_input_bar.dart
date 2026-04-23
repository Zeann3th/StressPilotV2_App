import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';

class AgentCommand {
  final String command;
  final String description;
  final String? usage;

  const AgentCommand({
    required this.command,
    required this.description,
    this.usage,
  });
}

const _kCommands = [
  AgentCommand(command: '/model',    description: 'Manage AI models'),
  AgentCommand(command: '/sessions', description: 'Browse & resume past chats'),
  AgentCommand(command: '/new',      description: 'Start a fresh session'),
  AgentCommand(command: '/theme',    description: 'Change color theme'),
  AgentCommand(command: '/allow',    description: 'Auto-approve tool patterns', usage: '/allow <pattern>'),
  AgentCommand(command: '/reset',    description: 'Reset thread & allowlist'),
  AgentCommand(command: '/clear',    description: 'Clear screen'),
  AgentCommand(command: '/quit',     description: 'Exit the agent'),
];

class AgentInputBar extends StatefulWidget {
  final bool enabled;
  final ValueChanged<String> onSend;

  const AgentInputBar({
    super.key,
    required this.enabled,
    required this.onSend,
  });

  @override
  State<AgentInputBar> createState() => _AgentInputBarState();
}

class _AgentInputBarState extends State<AgentInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _keyboardFocusNode = FocusNode();

  List<AgentCommand> _suggestions = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = _controller.text;
    if (text.startsWith('/') && !text.contains(' ')) {
      final matches = _kCommands
          .where((c) => c.command.startsWith(text.toLowerCase()))
          .toList();
      setState(() {
        _suggestions = matches;
        _selectedIndex = 0;
      });
    } else {
      setState(() => _suggestions = []);
    }
  }

  void _applySuggestion(AgentCommand cmd) {
    final needsArg = cmd.usage?.contains('<') ?? false;
    _controller.text = needsArg ? '${cmd.command} ' : cmd.command;
    _controller.selection =
        TextSelection.collapsed(offset: _controller.text.length);
    setState(() => _suggestions = []);
    _focusNode.requestFocus();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    widget.onSend(text);
    _controller.clear();
    setState(() => _suggestions = []);
    _focusNode.requestFocus();
  }

  bool _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent || _suggestions.isEmpty) return false;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowUp) {
      setState(() => _selectedIndex =
          (_selectedIndex - 1).clamp(0, _suggestions.length - 1));
      return true;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() => _selectedIndex =
          (_selectedIndex + 1).clamp(0, _suggestions.length - 1));
      return true;
    }
    if (key == LogicalKeyboardKey.tab || key == LogicalKeyboardKey.enter) {
      _applySuggestion(_suggestions[_selectedIndex]);
      return true;
    }
    if (key == LogicalKeyboardKey.escape) {
      setState(() => _suggestions = []);
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = AppColors.border;
    final surface = AppColors.surface;

    final mutedColor = AppColors.textSecondary;
    final subtleColor = AppColors.textSecondary.withValues(alpha: 0.6);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        AnimatedSize(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: _suggestions.isEmpty
              ? const SizedBox.shrink()
              : Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
              border: Border.all(color: border.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  child: Row(
                    children: [
                      Icon(LucideIcons.terminal,
                          size: 10, color: subtleColor),
                      const SizedBox(width: 4),
                      Text(
                        '↑↓  navigate   Tab / Enter  select   Esc  dismiss',
                        style: TextStyle(
                          fontSize: 10,
                          color: subtleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                    height: 1,
                    color: border.withValues(alpha: 0.15)),

                ..._suggestions.asMap().entries.map((e) =>
                    _SuggestionRow(
                      cmd: e.value,
                      selected: e.key == _selectedIndex,
                      isDark: isDark,
                      border: border,
                      mutedColor: mutedColor,
                      onTap: () => _applySuggestion(e.value),
                    )),
              ],
            ),
          ),
        ),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: border.withValues(alpha: 0.3)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: KeyboardListener(
                  focusNode: _keyboardFocusNode,
                  onKeyEvent: (event) {
                    if (_handleKey(event)) return;
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.enter &&
                        !HardwareKeyboard.instance.isShiftPressed &&
                        _suggestions.isEmpty) {
                      _send();
                    }
                  },
                  child: ShadInput(
                    controller: _controller,
                    focusNode: _focusNode,
                    placeholder: const Text('Message or /command...'),
                    enabled: widget.enabled,
                    maxLines: 4,
                    minLines: 1,
                    keyboardType: TextInputType.multiline,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PilotButton.primary(
                icon: LucideIcons.sendHorizontal,
                onPressed: widget.enabled ? _send : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  final AgentCommand cmd;
  final bool selected;
  final bool isDark;
  final Color border;
  final Color mutedColor;
  final VoidCallback onTap;

  const _SuggestionRow({
    required this.cmd,
    required this.selected,
    required this.isDark,
    required this.border,
    required this.mutedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        color: selected
            ? AppColors.accent.withValues(alpha: 0.1)
            : Colors.transparent,
        child: Row(
          children: [

            SizedBox(
              width: 96,
              child: Text(
                cmd.command,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.accent : null,
                ),
              ),
            ),

            Expanded(
              child: Text(
                cmd.description,
                style: TextStyle(
                  fontSize: 12,
                  color: mutedColor,
                ),
              ),
            ),

            if (cmd.usage != null) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.textPrimary.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  cmd.usage!,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    color: mutedColor,
                  ),
                ),
              ),
            ],

            if (selected) ...[
              const SizedBox(width: 8),
              Icon(
                LucideIcons.cornerDownLeft,
                size: 12,
                color: AppColors.accent,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
