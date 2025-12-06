import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/environment_provider.dart';
import '../../domain/environment_variable.dart';

class EnvironmentTable extends StatefulWidget {
  const EnvironmentTable({super.key});

  @override
  State<EnvironmentTable> createState() => _EnvironmentTableState();
}

class _EnvironmentTableState extends State<EnvironmentTable> {
  String _search = "";

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EnvironmentProvider>();
    final variables = provider.variables;
    final colors = Theme.of(context).colorScheme;

    // Filter
    final filtered = variables.where((v) {
      final q = _search.toLowerCase();
      return v.key.toLowerCase().contains(q) ||
          v.value.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        // Toolbar
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              // Search
              SizedBox(
                width: 300,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search variables...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colors.outlineVariant),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              const Spacer(),
              // Add Button
              FilledButton.icon(
                onPressed: () => provider.addVariable(),
                icon: const Icon(Icons.add),
                label: const Text('Add Variable'),
              ),
            ],
          ),
        ),

        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.outlineVariant)),
            color: colors.surfaceContainerLow,
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 60,
                child: Text(
                  'Active',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                flex: 1,
                child: Text(
                  'Key',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                flex: 2,
                child: Text(
                  'Value',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 48), // Actions
            ],
          ),
        ),

        // List
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (c, i) => Divider(
                    height: 1,
                    color: colors.outlineVariant.withOpacity(0.5),
                  ),
                  itemBuilder: (context, index) {
                    // We need the actual index in the provider list, not the filtered list
                    // But for simplicity, let's assume we pass the object and find index in provider
                    // Or better, just pass the index if we didn't filter.
                    // Since we filter, we need to find the real index.
                    final v = filtered[index];
                    final realIndex = variables.indexOf(v);

                    return _EnvironmentRow(
                      key: ValueKey(
                        v.id,
                      ), // Use ID as key. For new items, ID is unique negative.
                      variable: v,
                      onChanged: (key, value, isActive) {
                        provider.updateVariable(
                          realIndex,
                          key: key,
                          value: value,
                          isActive: isActive,
                        );
                      },
                      onDelete: () {
                        provider.removeVariable(realIndex);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _EnvironmentRow extends StatefulWidget {
  final EnvironmentVariable variable;
  final Function(String key, String value, bool isActive) onChanged;
  final VoidCallback onDelete;

  const _EnvironmentRow({
    super.key,
    required this.variable,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_EnvironmentRow> createState() => _EnvironmentRowState();
}

class _EnvironmentRowState extends State<_EnvironmentRow> {
  late TextEditingController _keyCtrl;
  late TextEditingController _valCtrl;

  @override
  void initState() {
    super.initState();
    _keyCtrl = TextEditingController(text: widget.variable.key);
    _valCtrl = TextEditingController(text: widget.variable.value);
  }

  @override
  void didUpdateWidget(covariant _EnvironmentRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.variable.key != _keyCtrl.text) {
      _keyCtrl.text = widget.variable.key;
    }
    if (widget.variable.value != _valCtrl.text) {
      _valCtrl.text = widget.variable.value;
    }
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _valCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged(_keyCtrl.text, _valCtrl.text, widget.variable.isActive);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Checkbox(
              value: widget.variable.isActive,
              onChanged: (v) => widget.onChanged(
                widget.variable.key,
                widget.variable.value,
                v ?? true,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: TextField(
              controller: _keyCtrl,
              decoration: const InputDecoration(
                hintText: 'KEY',
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.bold,
              ),
              onChanged: (_) => _notify(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _valCtrl,
              decoration: const InputDecoration(
                hintText: 'Value',
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(fontFamily: 'JetBrains Mono'),
              onChanged: (_) => _notify(),
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: colors.error),
            onPressed: widget.onDelete,
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}
