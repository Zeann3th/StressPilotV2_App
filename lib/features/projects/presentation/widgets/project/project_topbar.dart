import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProjectTopBar extends StatelessWidget {
  final TextEditingController searchController;
  final VoidCallback onRefresh;
  final VoidCallback onAdd;
  final VoidCallback onImport;
  final VoidCallback onExport;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onSearchChanged;

  const ProjectTopBar({
    super.key,
    required this.searchController,
    required this.onRefresh,
    required this.onAdd,
    required this.onImport,
    required this.onExport,
    required this.onSearchSubmitted,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerTheme.color!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              CupertinoIcons.refresh,
              color: Color(0xFF98989D),
              size: 18,
            ),
            onPressed: onRefresh,
            tooltip: 'Refresh',
            splashRadius: 20,
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              height: 36,
              child: CupertinoSearchTextField(
                controller: searchController,
                placeholder: 'Search projects',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontFamily: 'Inter', // or default
                  fontSize: 13,
                ),
                onChanged: (_) => onSearchChanged(),
                onSubmitted: onSearchSubmitted,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                placeholderStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
                itemColor: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 16),

          _ActionButton(
            icon: CupertinoIcons.arrow_down_doc,
            label: 'Import',
            onPressed: onImport,
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: CupertinoIcons.arrow_up_doc,
            label: 'Export',
            onPressed: onExport,
          ),
          const SizedBox(width: 8),
          _PrimaryButton(
            icon: CupertinoIcons.plus,
            label: 'New Project',
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      minimumSize: const Size(0, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: BorderRadius.circular(8),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurface),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      color: const Color(0xFF007AFF),
      minimumSize: const Size(0, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: BorderRadius.circular(8),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
