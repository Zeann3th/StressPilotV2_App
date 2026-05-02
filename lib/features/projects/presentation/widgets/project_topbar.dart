import 'package:flutter/material.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/themes/components/components.dart';

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
    final bg = AppColors.sidebarBackground;
    final border = AppColors.border;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border, width: 1)),
      ),
      child: Row(
        children: [
          Text(
            'Projects',
            style: AppTypography.title.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: PilotInput(
                controller: searchController,
                placeholder: 'Filter projects...',
                prefixIcon: Icons.search_rounded,
                onChanged: (_) => onSearchChanged(),
                onSubmitted: onSearchSubmitted,
              ),
            ),
          ),
          const SizedBox(width: 24),
          _ActionIcon(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            onTap: onRefresh,
          ),
          _ActionIcon(
            icon: Icons.download_rounded,
            tooltip: 'Import',
            onTap: onImport,
          ),
          _ActionIcon(
            icon: Icons.upload_rounded,
            tooltip: 'Export',
            onTap: onExport,
          ),
          const SizedBox(width: 8),
          PilotButton.primary(
            label: 'New Project',
            icon: Icons.add_rounded,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionIcon({required this.icon, required this.tooltip, required this.onTap});

  @override
  State<_ActionIcon> createState() => _ActionIconState();
}

class _ActionIconState extends State<_ActionIcon> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: TweenAnimationBuilder<double>(
            duration: AppDurations.short,
            tween: Tween(begin: 1.0, end: _pressed ? 0.92 : 1.0),
            builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
            child: AnimatedContainer(
              duration: AppDurations.micro,
              width: 36,
              height: 36,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: _hovered
                    ? AppColors.activeItem.withValues(alpha: 0.8)
                    : Colors.transparent,
                borderRadius: AppRadius.br4,
              ),
              child: Icon(
                widget.icon,
                size: 18,
                color: _hovered ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
