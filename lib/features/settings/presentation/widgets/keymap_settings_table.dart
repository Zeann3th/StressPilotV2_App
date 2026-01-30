import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/input/keymap_provider.dart';

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
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text(
                  'SHORTCUTS',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: () => provider.resetToDefaults(),
                  child: const Text('Reset Defaults'),
                )
               ],
             ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  for (final entry in keymap.entries) ...[
                    _buildRow(context, entry.key, entry.value),
                    if (entry.key != keymap.keys.last)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: colors.outlineVariant.withValues(alpha: 0.3),
                        indent: 16,
                      ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, String actionId, String shortcut) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _editShortcut(context, actionId, shortcut),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _humanizeActionId(actionId),
                style: const TextStyle(fontSize: 14),
              ),
            ),

             Text(
                shortcut,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
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
    String? newShortcut = await showDialog<String>(
      context: context,
      builder: (context) => _ShortcutDialog(initial: current, actionName: _humanizeActionId(actionId)),
    );

    if (newShortcut != null) {
      provider.updateShortcut(actionId, newShortcut);
    }
  }
}

class _ShortcutDialog extends StatefulWidget {
  final String initial;
  final String actionName;

  const _ShortcutDialog({required this.initial, required this.actionName});

  @override
  State<_ShortcutDialog> createState() => _ShortcutDialogState();
}

class _ShortcutDialogState extends State<_ShortcutDialog> {
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
    return AlertDialog(
      title: Text('Edit Shortcut for ${widget.actionName}'),
      content: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
             _handleKeyPress(event);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
             border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
             borderRadius: BorderRadius.circular(8)
          ),
          alignment: Alignment.center,
          child: Text(
            _current.isEmpty ? 'Press keys...' : _current,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, _current), child: const Text('Save')),
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
