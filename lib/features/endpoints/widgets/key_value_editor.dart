import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class KeyValueEditor extends StatefulWidget {
  final Map<String, String> data;
  final ValueChanged<Map<String, String>> onChanged;

  const KeyValueEditor({
    super.key,
    required this.data,
    required this.onChanged,
  });

  @override
  State<KeyValueEditor> createState() => _KeyValueEditorState();
}

class _KeyValueEditorState extends State<KeyValueEditor> {
  late List<MapEntry<TextEditingController, TextEditingController>>
  _controllers;

  @override
  void initState() {
    super.initState();
    _initControllers();
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
  Widget build(BuildContext context) {
    return ListView.separated(
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
              icon: const Icon(CupertinoIcons.minus_circle, size: 16),
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
