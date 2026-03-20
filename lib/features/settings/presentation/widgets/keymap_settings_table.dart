import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/input/keymap_provider.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/themes/components/components.dart';

class KeymapSettingsTable extends StatefulWidget {
  const KeymapSettingsTable({super.key});

  @override
  State<KeymapSettingsTable> createState() => _KeymapSettingsTableState();
}

class _KeymapSettingsTableState extends State<KeymapSettingsTable> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KeymapProvider>();
    final keymap = provider.keymap;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.textPrimary : AppColors.textLight;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SHORTCUTS',
                    style: AppTypography.heading.copyWith(color: textColor),
                  ),
                  PilotButton.ghost(
                    label: 'Reset Defaults',
                    icon: Icons.refresh_rounded,
                    onPressed: () => provider.resetToDefaults(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: AppRadius.br12,
                  border: Border.all(color: border, width: 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final entry in keymap.entries) ...[
                      _buildRow(context, entry.key, entry.value),
                      if (entry.key != keymap.keys.last)
                        Divider(height: 1, color: border),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, String actionId, String shortcut) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimary : AppColors.textLight;

    return _ShortcutRow(
      label: _humanizeActionId(actionId),
      shortcut: shortcut,
      onTap: () => _editShortcut(context, actionId, shortcut),
      textColor: textColor,
    );
  }

  String _humanizeActionId(String actionId) {
    return actionId
        .split('.')
        .map((e) => e[0].toUpperCase() + e.substring(1))
        .join(' ');
  }

  Future<void> _editShortcut(BuildContext context, String actionId, String current) async {
    final provider = context.read<KeymapProvider>();
    String? newShortcut = await PilotDialog.show<String>(
      context: context,
      title: 'Edit Shortcut for ${_humanizeActionId(actionId)}',
      content: _ShortcutListener(initial: current, onRecorded: (val) {
         Navigator.pop(context, val);
      }),
      actions: [
         PilotButton.ghost(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context),
          ),
      ]
    );

    if (newShortcut != null) {
      provider.updateShortcut(actionId, newShortcut);
    }
  }
}

class _ShortcutRow extends StatefulWidget {
  final String label;
  final String shortcut;
  final VoidCallback onTap;
  final Color textColor;

  const _ShortcutRow({
    required this.label,
    required this.shortcut,
    required this.onTap,
    required this.textColor,
  });

  @override
  State<_ShortcutRow> createState() => _ShortcutRowState();
}

class _ShortcutRowState extends State<_ShortcutRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.micro,
          color: _hovered ? AppColors.accent.withValues(alpha: 0.04) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  widget.label,
                  style: AppTypography.body.copyWith(
                    color: widget.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: AppRadius.br4,
                      ),
                      child: Text(
                        widget.shortcut,
                        style: AppTypography.code.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    if (_hovered) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.edit_rounded,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutListener extends StatefulWidget {
  final String initial;
  final ValueChanged<String> onRecorded;

  const _ShortcutListener({required this.initial, required this.onRecorded});

  @override
  State<_ShortcutListener> createState() => _ShortcutListenerState();
}

class _ShortcutListenerState extends State<_ShortcutListener> {
  final FocusNode _focusNode = FocusNode();
  String _current = "";

  @override
  void initState() {
    super.initState();
    _current = widget.initial;
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Press any combination of keys to record a new shortcut.'),
        const SizedBox(height: 24),
        KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: (event) {
            if (event is KeyDownEvent) {
              _handleKeyPress(event);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.05),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              borderRadius: AppRadius.br12,
            ),
            alignment: Alignment.center,
            child: Text(
              _current.isEmpty ? 'Waiting for keys...' : _current,
              style: AppTypography.code.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        PilotButton.primary(
          label: 'Save Shortcut',
          onPressed: () => widget.onRecorded(_current),
        ),
      ],
    );
  }

  void _handleKeyPress(KeyDownEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.enter) return;

    final keys = <String>[];
    if (HardwareKeyboard.instance.isControlPressed) keys.add('Control');
    if (HardwareKeyboard.instance.isShiftPressed) keys.add('Shift');
    if (HardwareKeyboard.instance.isAltPressed) keys.add('Alt');
    if (HardwareKeyboard.instance.isMetaPressed) keys.add('Meta');

    final keyLabel = event.logicalKey.keyLabel;
    if (!['Control', 'Shift', 'Alt', 'Meta', 'Control Left', 'Control Right', 'Shift Left', 'Shift Right', 'Alt Left', 'Alt Right', 'Meta Left', 'Meta Right'].contains(keyLabel)) {
      keys.add(keyLabel);
      setState(() {
        _current = keys.join('+');
      });
    }
  }
}
