import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stress_pilot/core/input/keymap_provider.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/shared/presentation/widgets/global_search_dropdown.dart';

class DashboardTopBar extends StatefulWidget {
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchSubmitted;

  const DashboardTopBar({super.key, this.searchController, this.onSearchSubmitted});

  @override
  State<DashboardTopBar> createState() => _DashboardTopBarState();
}

class _DashboardTopBarState extends State<DashboardTopBar> {
  @override
  Widget build(BuildContext context) {
    final keymap = context.watch<KeymapProvider>();
    final bg = AppColors.baseBackground;
    final border = AppColors.border;

    return Container(
      height: AppSpacing.navBarHeight,
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(color: border, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Stack(
        children: [
          // Center: Global Search
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: const GlobalSearchDropdown(),
            ),
          ),

          // Right: Action Icons
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TopBarIcon(
                  icon: LucideIcons.shoppingBag,
                  tooltip: 'Marketplace',
                  onTap: () => AppNavigator.pushNamed(AppRouter.marketplaceRoute),
                ),
                const SizedBox(width: 4),
                _TopBarIcon(
                  icon: LucideIcons.settings,
                  tooltip: _tip('Settings', keymap.getShortcut('app.settings')),
                  onTap: () => AppNavigator.pushNamed(AppRouter.settingsRoute),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _tip(String label, String? shortcut) {
    if (shortcut == null || shortcut.isEmpty) return label;
    return '$label ($shortcut)';
  }
}

class _TopBarIcon extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _TopBarIcon({required this.icon, required this.tooltip, required this.onTap});

  @override
  State<_TopBarIcon> createState() => _TopBarIconState();
}

class _TopBarIconState extends State<_TopBarIcon> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent;
    final accentHover = AppColors.accentHover;

    final iconColor = _isHovered ? accentHover : AppColors.textSecondary;

    return ShadTooltip(
      builder: (context) => Text(widget.tooltip),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: TweenAnimationBuilder<double>(
            duration: AppDurations.short,
            tween: Tween(begin: 1.0, end: _isPressed ? 0.95 : 1.0),
            builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
            child: AnimatedContainer(
              duration: AppDurations.micro,
              width: 36, // Slightly narrower for Fleet density
              height: 32, // Match sidebarRowHeight
              decoration: BoxDecoration(
                color: _isHovered
                    ? accent.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: AppRadius.br4,
              ),
              child: Icon(widget.icon, size: 16, color: iconColor),
            ),
          ),
        ),
      ),
    );
  }
}
