import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stress_pilot/features/projects/domain/canvas.dart';

class NodeConfigurationDialog extends StatefulWidget {
  final CanvasNode node;

  const NodeConfigurationDialog({super.key, required this.node});

  @override
  State<NodeConfigurationDialog> createState() =>
      _NodeConfigurationDialogState();
}

class _NodeConfigurationDialogState extends State<NodeConfigurationDialog> {
  late Map<String, dynamic> _preProcessor;
  late Map<String, dynamic> _postProcessor;
  int _selectedTab = 0; 

  @override
  void initState() {
    super.initState();
    _preProcessor = Map<String, dynamic>.from(
      widget.node.data['preProcessor'] ?? {},
    );
    _postProcessor = Map<String, dynamic>.from(
      widget.node.data['postProcessor'] ?? {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: colors.surface,
      surfaceTintColor: colors.surfaceTint,
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configure Node',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                _buildTab('Pre-Processor', 0, colors),
                const SizedBox(width: 8),
                _buildTab('Post-Processor', 1, colors),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _selectedTab == 0
                  ? _ProcessorEditor(
                      data: _preProcessor,
                      onChanged: (data) => _preProcessor = data,
                    )
                  : _ProcessorEditor(
                      data: _postProcessor,
                      onChanged: (data) => _postProcessor = data,
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop({
                      'preProcessor': _preProcessor,
                      'postProcessor': _postProcessor,
                    });
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, int index, ColorScheme colors) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? colors.primary : colors.outlineVariant,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? colors.onPrimaryContainer : colors.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ProcessorEditor extends StatefulWidget {
  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const _ProcessorEditor({required this.data, required this.onChanged});

  @override
  State<_ProcessorEditor> createState() => _ProcessorEditorState();
}

class _ProcessorEditorState extends State<_ProcessorEditor> {
  late TextEditingController _sleepController;
  late TextEditingController _injectController;
  late TextEditingController _extractController;

  @override
  void initState() {
    super.initState();
    _sleepController = TextEditingController(
      text: widget.data['sleep']?.toString() ?? '',
    );
    _injectController = TextEditingController(
      text: _formatJson(widget.data['inject']),
    );
    _extractController = TextEditingController(
      text: _formatJson(widget.data['extract']),
    );
  }

  String _formatJson(dynamic data) {
    if (data == null) return '';
    try {
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (e) {
      return data.toString();
    }
  }

  void _updateData() {
    final newData = <String, dynamic>{};

    if (_sleepController.text.isNotEmpty) {
      newData['sleep'] = int.tryParse(_sleepController.text);
    }

    if (_injectController.text.isNotEmpty) {
      try {
        newData['inject'] = jsonDecode(_injectController.text);
      } catch (_) {
        
      }
    }

    if (_extractController.text.isNotEmpty) {
      try {
        newData['extract'] = jsonDecode(_extractController.text);
      } catch (_) {
        
      }
    }

    widget.onChanged(newData);
  }

  @override
  void dispose() {
    _sleepController.dispose();
    _injectController.dispose();
    _extractController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _buildSection(
          context,
          'Sleep (ms)',
          'Delay execution by milliseconds',
          _sleepController,
          isNumeric: true,
        ),
        const SizedBox(height: 16),
        _buildSection(
          context,
          'Inject Variables (JSON)',
          '{"key": "value"}',
          _injectController,
          isMultiline: true,
        ),
        const SizedBox(height: 16),
        _buildSection(
          context,
          'Extract Variables (JSON)',
          '{"varName": "path.to.value"}',
          _extractController,
          isMultiline: true,
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    String label,
    String hint,
    TextEditingController controller, {
    bool isNumeric = false,
    bool isMultiline = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: (_) => _updateData(),
          keyboardType: isNumeric
              ? TextInputType.number
              : TextInputType.multiline,
          maxLines: isMultiline ? 5 : 1,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.all(12),
          ),
          style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13),
        ),
      ],
    );
  }
}
