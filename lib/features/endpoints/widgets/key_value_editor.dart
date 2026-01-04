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
    final colors = Theme.of(context).colorScheme;
    return ListView.separated(
      itemCount: _controllers.length,
      separatorBuilder: (c, i) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = _controllers[index];
        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: entry.key,
                decoration: const InputDecoration(
                  hintText: 'Key',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                style: const TextStyle(fontSize: 13),
                onChanged: (v) {
                  if (index == _controllers.length - 1 && v.isNotEmpty) {
                    setState(() => _addEmptyRow());
                  }
                  _updateData();
                },
              ),
            ),
            Container(width: 1, height: 24, color: colors.outlineVariant),
            Expanded(
              child: TextField(
                controller: entry.value,
                decoration: const InputDecoration(
                  hintText: 'Value',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                style: const TextStyle(fontSize: 13),
                onChanged: (v) => _updateData(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 16),
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
