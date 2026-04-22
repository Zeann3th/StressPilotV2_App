import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter/material.dart';

class KeyValueEditor extends StatefulWidget {
  final Map<String, String> data;
  final ValueChanged<Map<String, String>> onChanged;
  final ScrollController? controller;

  const KeyValueEditor({
    super.key,
    required this.data,
    required this.onChanged,
    this.controller,
  });

  @override
  State<KeyValueEditor> createState() => _KeyValueEditorState();
}

class _KeyValueEditorState extends State<KeyValueEditor> {
  late List<MapEntry<TextEditingController, TextEditingController>>
  _controllers;
  ScrollController? _internalScrollController;

  ScrollController get _effectiveController =>
      widget.controller ?? (_internalScrollController ??= ScrollController());

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(KeyValueEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) {

      bool needsRebuild = false;
      if (widget.data.length != _controllers.length - 1) {
        needsRebuild = true;
      } else {
        final entries = widget.data.entries.toList();
        for (int i = 0; i < entries.length; i++) {
          if (_controllers[i].key.text != entries[i].key ||
              _controllers[i].value.text != entries[i].value) {
            needsRebuild = true;
            break;
          }
        }
      }

      if (needsRebuild) {
        _initControllers();
      }
    }
  }

  void _initControllers() {
    _controllers = widget.data.entries
        .map(
          (e) => MapEntry(
            TextEditingController(text: e.key),
            TextEditingController(text: e.value),
          ),
        )
        .toList();

    _addEmptyRow();
  }

  void _addEmptyRow() {
    _controllers.add(
      MapEntry(TextEditingController(), TextEditingController()),
    );
  }

  void _updateData() {
    final newData = <String, String>{};
    for (var entry in _controllers) {
      if (entry.key.text.isNotEmpty) {
        newData[entry.key.text] = entry.value.text;
      }
    }
    widget.onChanged(newData);
  }

  @override
  void dispose() {
    _internalScrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: _effectiveController,
      itemCount: _controllers.length,
      separatorBuilder: (c, i) =>
          Divider(height: 1, color: Theme.of(context).dividerTheme.color),
      itemBuilder: (context, index) {
        final entry = _controllers[index];
        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: entry.key,
                decoration: InputDecoration(
                  hintText: 'Key',
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontFamily: 'JetBrains Mono',
                ),
                onChanged: (v) {
                  if (index == _controllers.length - 1 && v.isNotEmpty) {
                    setState(() => _addEmptyRow());
                  }
                  _updateData();
                },
              ),
            ),
            Container(
              width: 1,
              height: 24,
              color: Theme.of(context).dividerTheme.color,
            ),
            Expanded(
              child: TextField(
                controller: entry.value,
                decoration: InputDecoration(
                  hintText: 'Value',
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontFamily: 'JetBrains Mono',
                ),
                onChanged: (v) => _updateData(),
              ),
            ),
            IconButton(
              icon: Icon(LucideIcons.circleMinus, size: 16),
              color: const Color(0xFFFF453A),
              tooltip: 'Remove',
              onPressed: () {
                if (index < _controllers.length - 1) {
                  setState(() {
                    _controllers.removeAt(index);
                    _updateData();
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }
}
