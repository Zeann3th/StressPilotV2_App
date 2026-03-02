import 'package:flutter/material.dart';
import 'package:stress_pilot/core/design/tokens.dart';
import 'package:stress_pilot/core/design/components.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border, width: 1)),
      ),
      child: Row(
        children: [
          Tooltip(
            message: 'Refresh',
            child: _HoverIconButton(
              icon: Icons.refresh_rounded,
              onTap: onRefresh,
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: SizedBox(
                height: 34,
                child: PilotInput(
                  controller: searchController,
                  placeholder: 'Search projects...',
                  prefixIcon: Icons.search_rounded,
                  onChanged: (_) => onSearchChanged(),
                  onSubmitted: onSearchSubmitted,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          PilotButton.ghost(
            icon: Icons.download_rounded,
            label: 'Import',
            onPressed: onImport,
          ),
          const SizedBox(width: 8),
          PilotButton.ghost(
            icon: Icons.upload_rounded,
            label: 'Export',
            onPressed: onExport,
          ),
          const SizedBox(width: 8),
          PilotButton.primary(
            icon: Icons.add_rounded,
            label: 'New Project',
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _HoverIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HoverIconButton({required this.icon, required this.onTap});

  @override
  State<_HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<_HoverIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.micro,
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.accent.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: AppRadius.br8,
          ),
          child: Icon(
            widget.icon,
            size: 16,
            color: _hovered ? AppColors.accent : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
