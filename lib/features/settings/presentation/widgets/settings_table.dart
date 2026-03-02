import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/features/settings/presentation/provider/setting_provider.dart';
import 'package:stress_pilot/features/settings/presentation/widgets/keymap_settings_table.dart';
import 'settings_row.dart';

class SettingsTable extends StatefulWidget {
  const SettingsTable({super.key});

  @override
  State<SettingsTable> createState() => _SettingsTableState();
}

class _SettingsTableState extends State<SettingsTable> {
  String _search = "";
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _categoryKeys = {};
  String? _selectedCategory;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingProvider>();
    final configs = provider.configs;
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final filteredEntries = configs.entries.where((e) {
      final q = _search.toLowerCase();
      return e.key.toLowerCase().contains(q) ||
          e.value.toLowerCase().contains(q);
    }).toList();

    final Map<String, List<MapEntry<String, String>>> grouped = {};
    for (var entry in filteredEntries) {
      final parts = entry.key.split('_');
      String category = parts.length > 1
          ? parts.first.toUpperCase()
          : 'GENERAL';
      if (entry.key.startsWith('AI_MODEL')) category = 'AI MODEL';
      grouped.putIfAbsent(category, () => []).add(entry);
    }
    final categories = grouped.keys.toList()..sort();
    categories.add('SHORTCUTS'); // Add Shortcuts category explicitly

    // Initialize keys and selection
    for (var cat in categories) {
      if (cat != 'SHORTCUTS') {
        _categoryKeys.putIfAbsent(cat, () => GlobalKey());
      }
    }
    if (_selectedCategory == null && categories.isNotEmpty) {
      _selectedCategory = categories.first;
    }

    return Column(
      children: [
        // Search Header
        if (categories.length > 1 || _search.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: 400,
              height: 36,
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search settings...",
                  hintStyle: TextStyle(color: colors.onSurfaceVariant),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                  filled: true,
                  fillColor: colors.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                style: text.bodyMedium?.copyWith(color: colors.onSurface),
                onChanged: (v) => setState(() => _search = v.trim()),
              ),
            ),
          ),

        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sidebar Navigation
              Container(
                width: 220,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: colors.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  color: colors.surface.withValues(alpha: 0.5),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 8,
                  ),
                  itemCount: categories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = cat == _selectedCategory;
                    return InkWell(
                      onTap: () => setState(() => _selectedCategory = cat),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.primary.withValues(alpha: 0.1)
                              : null,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          cat,
                          style: text.labelMedium?.copyWith(
                            color: isSelected
                                ? colors.primary
                                : colors.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Content Area
              Expanded(
                child: _selectedCategory == 'SHORTCUTS'
                    ? const SingleChildScrollView(
                        padding: EdgeInsets.all(32),
                        child: KeymapSettingsTable(),
                      )
                    : filteredEntries.isEmpty
                    ? Center(
                        child: Text(
                          "No matching settings found.",
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      )
                    : SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 700),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (var category in categories) ...[
                                  if (category != 'SHORTCUTS' &&
                                      (grouped[category] != null))
                                    Container(
                                      key: _categoryKeys[category],
                                      margin: const EdgeInsets.only(bottom: 32),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            category,
                                            style: text.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colors.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: colors.surface,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: colors.outlineVariant
                                                    .withValues(alpha: 0.5),
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.03),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            child: Column(
                                              children: [
                                                for (
                                                  int i = 0;
                                                  i < grouped[category]!.length;
                                                  i++
                                                ) ...[
                                                  if (i > 0)
                                                    Divider(
                                                      height: 1,
                                                      thickness: 1,
                                                      color: colors
                                                          .outlineVariant
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),
                                                      indent: 16,
                                                    ),
                                                  SettingsRow(
                                                    keyName:
                                                        grouped[category]![i]
                                                            .key,
                                                    value: grouped[category]![i]
                                                        .value,
                                                    onSave: (val) async {
                                                      await provider.setConfig(
                                                        grouped[category]![i]
                                                            .key,
                                                        val,
                                                      );
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              "Setting saved",
                                                            ),
                                                            behavior:
                                                                SnackBarBehavior
                                                                    .floating,
                                                            width: 200,
                                                          ),
                                                        );
                                                      }
                                                    },
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
