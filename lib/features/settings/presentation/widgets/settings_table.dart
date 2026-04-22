import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/core/themes/theme_manager.dart';
import 'package:stress_pilot/core/themes/pilot_theme.dart';
import 'package:stress_pilot/features/settings/presentation/provider/setting_provider.dart';
import 'package:stress_pilot/features/settings/presentation/widgets/keymap_settings_table.dart';
import 'package:stress_pilot/features/settings/presentation/widgets/app_about_section.dart';
import 'package:stress_pilot/features/settings/presentation/widgets/plugin_settings_view.dart';
import 'package:stress_pilot/features/settings/presentation/widgets/function_settings_view.dart';
import 'package:stress_pilot/features/scheduling/presentation/widgets/task_scheduling_view.dart';
import 'settings_row.dart';

class SettingsTable extends StatefulWidget {
  const SettingsTable({super.key});

  @override
  State<SettingsTable> createState() => _SettingsTableState();
}

class _SettingsTableState extends State<SettingsTable> {
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
    final border = AppColors.border;
    final textColor = AppColors.textPrimary;

    final Map<String, List<MapEntry<String, String>>> grouped = {};
    for (var entry in configs.entries) {
      final parts = entry.key.split('_');
      String category = parts.length > 1 ? parts.first.toUpperCase() : 'GENERAL';
      if (entry.key.startsWith('AI_MODEL')) category = 'AI MODEL';

      if (category == 'HTTP' || category == 'FLOW' || category == 'BREAKPOINT') {
        category = 'CONFIGURATIONS';
      }

      grouped.putIfAbsent(category, () => []).add(entry);
    }

    final categories = [
      'ABOUT',
      'THEME',
      'SHORTCUTS',
      'CONFIGURATIONS',
      'FUNCTIONS',
      'TASK SCHEDULING',
      'PLUGINS',
    ];

    final staticCats = categories.toSet();
    final dynamicCats = grouped.keys.where((c) => !staticCats.contains(c)).toList()..sort();
    categories.addAll(dynamicCats);

    if (_selectedCategory == null && categories.isNotEmpty) {
      _selectedCategory = categories.first;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Container(
          width: 200,
          margin: const EdgeInsets.only(right: 24),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = cat == _selectedCategory;

              IconData icon = Icons.settings_rounded;
              if (cat == 'THEME') icon = Icons.palette_rounded;
              if (cat == 'ABOUT') icon = Icons.info_outline_rounded;
              if (cat == 'SHORTCUTS') icon = Icons.keyboard_rounded;
              if (cat == 'PLUGINS') icon = Icons.extension_rounded;
              if (cat == 'FUNCTIONS') icon = Icons.functions_rounded;
              if (cat == 'TASK SCHEDULING') icon = Icons.schedule_rounded;
              if (cat == 'CONFIGURATIONS') icon = Icons.tune_rounded;
              if (cat == 'AI MODEL') icon = Icons.auto_awesome_rounded;
              if (cat == 'DATABASE') icon = Icons.storage_rounded;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: PilotButton.ghost(
                  label: cat,
                  icon: icon,
                  onPressed: () => setState(() => _selectedCategory = cat),
                  foregroundOverride: isSelected ? AppColors.accent : AppColors.textSecondary,
                  backgroundOverride: isSelected ? AppColors.accent.withValues(alpha: 0.1) : null,
                ),
              );
            },
          ),
        ),

        VerticalDivider(width: 1, thickness: 1, color: border),
        const SizedBox(width: 24),

        Expanded(
          child: _buildContent(grouped, textColor, border),
        ),
      ],
    );
  }

  Widget _buildContent(Map<String, List<MapEntry<String, String>>> grouped, Color textColor, Color border) {
    if (_selectedCategory == 'THEME') {
      return const _ThemeSettings();
    }

    if (_selectedCategory == 'ABOUT') {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(32),
        child: AppAboutSection(),
      );
    }

    if (_selectedCategory == 'SHORTCUTS') {
      return const KeymapSettingsTable();
    }

    if (_selectedCategory == 'PLUGINS') {
      return const PluginSettingsView();
    }

    if (_selectedCategory == 'FUNCTIONS') {
      return const FunctionSettingsView();
    }

    if (_selectedCategory == 'TASK SCHEDULING') {
      return const TaskSchedulingView();
    }

    if (_selectedCategory == 'CONFIGURATIONS') {
      final entries = grouped['CONFIGURATIONS'] ?? [];
      final flowEntries = entries.where((e) => e.key.startsWith('FLOW') || e.key.startsWith('BREAKPOINT')).toList();
      final httpEntries = entries.where((e) => e.key.startsWith('HTTP')).toList();

      return SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configurations',
                  style: AppTypography.heading.copyWith(color: textColor, fontSize: 20),
                ),
                const SizedBox(height: 24),

                if (flowEntries.isNotEmpty) ...[
                  Text('Flow', style: AppTypography.label),
                  const SizedBox(height: 12),
                  _buildSettingsContainer(flowEntries, border),
                  const SizedBox(height: 32),
                ],

                if (httpEntries.isNotEmpty) ...[
                  Text('HTTP', style: AppTypography.label),
                  const SizedBox(height: 12),
                  _buildSettingsContainer(httpEntries, border),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final entries = grouped[_selectedCategory] ?? [];

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedCategory!,
                style: AppTypography.heading.copyWith(color: textColor, fontSize: 20),
              ),
              const SizedBox(height: 24),
              _buildSettingsContainer(entries, border),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsContainer(List<MapEntry<String, String>> entries, Color border) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.br8,
        border: Border.all(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < entries.length; i++) ...[
            if (i > 0) Divider(height: 1, color: AppColors.divider),
            SettingsRow(
              keyName: entries[i].key,
              value: entries[i].value,
              onSave: (val) async {
                await context.read<SettingProvider>().setConfig(entries[i].key, val);
                if (mounted) {
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

class _ThemeSettings extends StatelessWidget {
  const _ThemeSettings();

  @override
  Widget build(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();
    final availableThemes = themeManager.availableThemes;
    final currentTheme = themeManager.currentTheme;
    final textColor = AppColors.textPrimary;
    final border = AppColors.border;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Appearance',
                style: AppTypography.heading.copyWith(color: textColor, fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                'Customize how Stress Pilot looks on your machine.',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),

              Text('Active Theme', style: AppTypography.label),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.br8,
                  border: Border.all(color: border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var theme in availableThemes)
                      _ThemeOption(
                        theme: theme,
                        isSelected: theme.id == currentTheme.id,
                        onSelect: () => themeManager.setTheme(theme.id),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              PilotButton.ghost(
                label: 'Reload External Themes',
                icon: Icons.refresh_rounded,
                onPressed: () => themeManager.loadAvailableThemes(),
              ),
              const SizedBox(height: 12),
              Text(
                'External themes are loaded from ~/.pilot/client/themes/*.json',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeOption extends StatefulWidget {
  final PilotTheme theme;
  final bool isSelected;
  final VoidCallback onSelect;

  const _ThemeOption({
    required this.theme,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  State<_ThemeOption> createState() => _ThemeOptionState();
}

class _ThemeOptionState extends State<_ThemeOption> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final textColor = AppColors.textPrimary;
    final border = AppColors.border;

    final bg = widget.isSelected
        ? AppColors.accent.withValues(alpha: 0.1)
        : _isHovered
            ? AppColors.hoverItem
            : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onSelect,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: bg,
            border: Border(
              bottom: BorderSide(color: border),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isSelected ? AppColors.accent : AppColors.textSecondary,
                    width: 2,
                  ),
                ),
                child: widget.isSelected
                    ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accent,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.theme.name,
                    style: AppTypography.body.copyWith(
                      color: textColor,
                      fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(
                    widget.theme.isDark ? 'Dark Theme' : 'Light Theme',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
              const Spacer(),
              _ThemePreview(theme: widget.theme),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  final PilotTheme theme;
  const _ThemePreview({required this.theme});

  @override
  Widget build(BuildContext context) {
    final colors = [
      theme.getColor('background', Colors.grey),
      theme.getColor('surface', Colors.grey),
      theme.getColor('accent', Colors.green),
    ];

    return Row(
      children: [
        for (var c in colors)
          Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border),
            ),
          ),
      ],
    );
  }
}
