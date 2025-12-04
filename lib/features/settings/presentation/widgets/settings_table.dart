import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/features/settings/presentation/provider/setting_provider.dart';
import 'settings_row.dart'; // Import the separated widget

class SettingsTable extends StatefulWidget {
  const SettingsTable({super.key});

  @override
  State<SettingsTable> createState() => _SettingsTableState();
}

class _SettingsTableState extends State<SettingsTable> {
  String _search = "";
  bool _isSidebarOpen = true;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _categoryKeys = {};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCategory(String category) {
    final key = _categoryKeys[category];
    if (key != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingProvider>();
    final configs = provider.configs;
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    // Filter
    final filteredEntries = configs.entries.where((e) {
      final q = _search.toLowerCase();
      return e.key.toLowerCase().contains(q) ||
          e.value.toLowerCase().contains(q);
    }).toList();

    // Group
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

    // Init Keys
    for (var cat in categories) {
      _categoryKeys.putIfAbsent(cat, () => GlobalKey());
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- LEFT SIDEBAR (TOC) ---
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: _isSidebarOpen ? 240 : 0,
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: colors.outline)),
            color: colors.surface,
          ),
          child: ClipRect(
            child: OverflowBox(
              minWidth: 240,
              maxWidth: 240,
              alignment: Alignment.topLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Row(
                      children: [
                        Text(
                          "CONTENTS",
                          style: text.labelSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: colors.onSurface,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (categories.isEmpty && filteredEntries.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        "Parsing...",
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ),

                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        return InkWell(
                          onTap: () => _scrollToCategory(cat),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Text(
                              cat,
                              style: text.bodySmall?.copyWith(
                                color: colors.onSurface.withAlpha(200),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // --- MAIN CONTENT ---
        Expanded(
          child: Column(
            children: [
              // Search Bar & Toggle
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: colors.outline.withAlpha(50)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Toggle Sidebar Button
                    IconButton(
                      icon: Icon(
                        _isSidebarOpen ? Icons.menu_open : Icons.menu,
                        color: colors.onSurface,
                      ),
                      onPressed: () =>
                          setState(() => _isSidebarOpen = !_isSidebarOpen),
                      tooltip: _isSidebarOpen
                          ? "Collapse Sidebar"
                          : "Expand Sidebar",
                    ),
                    const SizedBox(width: 16),

                    // Search Input
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 600),
                        height: 40,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Search settings...",
                            hintStyle: text.bodyMedium?.copyWith(
                              color: colors.onSurface.withAlpha(100),
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              size: 18,
                              color: colors.onSurface,
                            ),
                            suffixIcon: _search.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      size: 16,
                                      color: colors.onSurface,
                                    ),
                                    onPressed: () =>
                                        setState(() => _search = ""),
                                    splashRadius: 16,
                                  )
                                : null,
                            filled: true,
                            fillColor: colors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(color: colors.onSurface),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(color: colors.outline),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                color: colors.onSurface,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                          ),
                          style: text.bodyMedium?.copyWith(
                            color: colors.onSurface,
                          ),
                          onChanged: (v) => setState(() => _search = v.trim()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content List
              Expanded(
                child: filteredEntries.isEmpty
                    ? Center(
                        child: Text(
                          "No matching settings found.",
                          style: text.bodyMedium?.copyWith(
                            color: colors.onSurface,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(48, 24, 48, 64),
                        // More padding for clean look
                        child: Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 800),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (var category in categories) ...[
                                  _CategoryHeader(
                                    title: category,
                                    key: _categoryKeys[category],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: colors.surface,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: colors.outline),
                                    ),
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
                                              color: colors.outline,
                                            ),
                                          SettingsRow(
                                            keyName: grouped[category]![i].key,
                                            value: grouped[category]![i].value,
                                            onSave: (val) async {
                                              await provider.setConfig(
                                                grouped[category]![i].key,
                                                val,
                                              );
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      "Setting saved. Restart required.",
                                                    ),
                                                    width: 300,
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    duration: Duration(
                                                      seconds: 2,
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 48),
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

class _CategoryHeader extends StatelessWidget {
  final String title;

  const _CategoryHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(width: 4, height: 16, color: colors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: colors.onSurface,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
