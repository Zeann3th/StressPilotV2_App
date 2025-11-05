import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/features/settings/presentation/provider/setting_provider.dart';

class SettingsTable extends StatefulWidget {
  const SettingsTable({super.key});

  @override
  State<SettingsTable> createState() => _SettingsTableState();
}

class _SettingsTableState extends State<SettingsTable> {
  String _search = "";

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingProvider>();
    final configs = provider.configs;

    final filtered = configs.entries.where((e) {
      final q = _search.toLowerCase();
      return e.key.toLowerCase().contains(q) ||
          e.value.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              height: 44,
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search settings...",
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            size: 18,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () => setState(() => _search = ""),
                        )
                      : null,
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onChanged: (v) => setState(() => _search = v.trim()),
              ),
            ),
          ),
        ),

        // Table Container
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.shadow.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _SettingsHeader(),
                const Divider(height: 1),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text("No matching settings found."),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final entry = filtered[index];
                        return _SettingsRow(
                          keyName: entry.key,
                          value: entry.value,
                          onSubmit: (newValue) async {
                            await provider.setConfig(entry.key, newValue);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Saved. (Cached & Applies Next Restart)",
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          _HeaderCell("Key", flex: 2, text: text, colors: colors),
          _HeaderCell("Value", flex: 3, text: text, colors: colors),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final int flex;
  final TextTheme text;
  final ColorScheme colors;

  const _HeaderCell(
    this.label, {
    required this.flex,
    required this.text,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: text.labelSmall?.copyWith(
          color: colors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SettingsRow extends StatefulWidget {
  final String keyName;
  final String value;
  final Future<void> Function(String newValue) onSubmit;

  const _SettingsRow({
    required this.keyName,
    required this.value,
    required this.onSubmit,
  });

  @override
  State<_SettingsRow> createState() => _SettingsRowState();
}

class _SettingsRowState extends State<_SettingsRow> {
  bool editing = false;
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.value);
  }

  void _finishEdit() async {
    final newValue = controller.text.trim();
    if (newValue != widget.value) {
      await widget.onSubmit(newValue);
    }
    if (mounted) setState(() => editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              widget.keyName,
              style: text.bodyMedium?.copyWith(color: colors.onSurface),
            ),
          ),
          Expanded(
            flex: 3,
            child: editing
                ? Focus(
                    onFocusChange: (hasFocus) {
                      if (!hasFocus) _finishEdit();
                    },
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      onSubmitted: (_) => _finishEdit(),
                      style: text.bodySmall?.copyWith(color: colors.onSurface),
                    ),
                  )
                : InkWell(
                    onTap: () => setState(() => editing = true),
                    child: Text(
                      widget.value,
                      style: text.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
