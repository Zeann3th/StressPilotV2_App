import 'package:flutter/material.dart';

class ProjectTopBar extends StatelessWidget {
  final TextEditingController searchController;
  final VoidCallback onRefresh;
  final VoidCallback onAdd;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onSearchChanged;

  const ProjectTopBar({
    super.key,
    required this.searchController,
    required this.onRefresh,
    required this.onAdd,
    required this.onSearchSubmitted,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.outline, width: 1)),
      ),
      child: Row(
        children: [
          // Refresh Icon (Subtle)
          IconButton(
            icon: Icon(Icons.refresh, color: colors.onSurfaceVariant, size: 20),
            onPressed: onRefresh,
            tooltip: 'Refresh',
            splashRadius: 20,
          ),
          const SizedBox(width: 16),

          // Search Input (Clean & Minimal)
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              height: 36,
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search projects...',
                  hintStyle: text.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant.withAlpha(150),
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 16,
                            color: colors.onSurfaceVariant,
                          ),
                          onPressed: () {
                            searchController.clear();
                            onRefresh();
                            onSearchChanged();
                          },
                          splashRadius: 16,
                        )
                      : null,
                  filled: true,
                  fillColor: colors.surfaceContainerLow,
                  // Minimal background
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide
                        .none, // No border for cleaner look inside toolbar
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: colors.primary.withAlpha(100),
                      width: 1,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0, // Centered vertically
                  ),
                ),
                style: text.bodyMedium?.copyWith(
                  color: colors.onSurface,
                  fontSize: 13,
                ),
                onChanged: (_) => onSearchChanged(),
                onSubmitted: onSearchSubmitted,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Create Button (Primary Action)
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text("New Project"),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
