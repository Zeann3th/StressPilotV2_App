import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/design/tokens.dart';
import 'package:stress_pilot/core/design/components.dart';
import 'package:stress_pilot/features/settings/presentation/provider/setting_provider.dart';
import 'package:stress_pilot/features/settings/presentation/widgets/keymap_settings_table.dart';
import 'settings_row.dart';

class SettingsTable extends StatefulWidget {
  const SettingsTable({super.key});

  @override
  State<SettingsTable> createState() => _SettingsTableState();
}

class _SettingsTableState extends State<SettingsTable> {
  String _search = '';
  final ScrollController _scrollController = ScrollController();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.textPrimary : AppColors.textLight;

    final filteredEntries = configs.entries.where((e) {
      final q = _search.toLowerCase();
      return e.key.toLowerCase().contains(q) ||
          e.value.toLowerCase().contains(q);
    }).toList();

    final Map<String, List<MapEntry<String, String>>> grouped = {};
    for (var entry in filteredEntries) {
      final parts = entry.key.split('_');
      String category = parts.length > 1 ? parts.first.toUpperCase() : 'GENERAL';
      if (entry.key.startsWith('AI_MODEL')) category = 'AI MODEL';
      grouped.putIfAbsent(category, () => []).add(entry);
    }
    final categories = grouped.keys.toList()..sort();
    categories.add('SHORTCUTS');

    if (_selectedCategory == null && categories.isNotEmpty) {
      _selectedCategory = categories.first;
    }

    return Column(
      children: [
        // Search bar
        Container(
          color: surface,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          child: SizedBox(
            width: 360,
            height: 34,
            child: PilotInput(
              placeholder: 'Search settings...',
              prefixIcon: Icons.search_rounded,
              onChanged: (v) => setState(() => _search = v.trim()),
            ),
          ),
        ),
        Divider(height: 1, color: border),

        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category sidebar
              Container(
                width: 210,
                color: surface,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final isSelected = cat == _selectedCategory;
                          return _CategoryItem(
                            label: cat,
                            isSelected: isSelected,
                            onTap: () => setState(() => _selectedCategory = cat),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              VerticalDivider(width: 1, color: border),

              // Content area
              Expanded(
                child: Container(
                  color: bg,
                  child: _selectedCategory == 'SHORTCUTS'
                      ? const SingleChildScrollView(
                          padding: EdgeInsets.all(32),
                          child: KeymapSettingsTable(),
                        )
                      : filteredEntries.isEmpty
                      ? Center(
                          child: Text(
                            'No matching settings found.',
                            style: AppTypography.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 680),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_selectedCategory != null &&
                                      grouped[_selectedCategory] != null) ...[
                                    Text(
                                      _selectedCategory!,
                                      style: AppTypography.heading.copyWith(
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _SettingsGroup(
                                      entries: grouped[_selectedCategory]!,
                                      provider: provider,
                                    ),
                                  ],
                                ],
                              ),
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

class _CategoryItem extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<_CategoryItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimary : AppColors.textLight;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          children: [
            if (widget.isSelected)
              Positioned(
                left: 0,
                top: 3,
                bottom: 3,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: AppRadius.br4,
                  ),
                ),
              ),
            AnimatedContainer(
              duration: AppDurations.micro,
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? AppColors.accent.withValues(alpha: 0.10)
                    : _hovered
                    ? AppColors.accent.withValues(alpha: 0.05)
                    : Colors.transparent,
                borderRadius: AppRadius.br8,
              ),
              child: Text(
                widget.label,
                style: AppTypography.body.copyWith(
                  color: widget.isSelected ? AppColors.accent : textColor,
                  fontWeight: widget.isSelected
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<MapEntry<String, String>> entries;
  final SettingProvider provider;

  const _SettingsGroup({required this.entries, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.br12,
        border: Border.all(color: border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < entries.length; i++) ...[
            if (i > 0) Divider(height: 1, color: border),
            SettingsRow(
              keyName: entries[i].key,
              value: entries[i].value,
              onSave: (val) async {
                await provider.setConfig(entries[i].key, val);
                if (context.mounted) {
                  PilotToast.show(context, 'Setting saved');
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}
