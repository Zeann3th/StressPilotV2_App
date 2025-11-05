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
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.refresh, color: colors.onSurface),
            onPressed: onRefresh,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              height: 40,
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search projects...',
                  hintStyle: text.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: colors.onSurfaceVariant,
                  ),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            size: 18,
                            color: colors.onSurfaceVariant,
                          ),
                          onPressed: () {
                            searchController.clear();
                            onRefresh();
                            onSearchChanged();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: colors.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                style: text.bodyMedium?.copyWith(color: colors.onSurface),
                onChanged: (_) => onSearchChanged(),
                onSubmitted: onSearchSubmitted,
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: Icon(Icons.add, color: colors.onSurface),
            onPressed: onAdd,
            tooltip: 'Create Project',
          ),
        ],
      ),
    );
  }
}
