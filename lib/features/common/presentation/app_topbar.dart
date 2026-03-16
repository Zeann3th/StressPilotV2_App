import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:stress_pilot/core/design/tokens.dart';
import 'dart:io';

import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/system/process_manager.dart';
import 'package:stress_pilot/core/themes/theme_manager.dart';
import 'package:stress_pilot/core/input/keymap_provider.dart';

class AppTopBar extends StatefulWidget {
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchSubmitted;

  const AppTopBar({super.key, this.searchController, this.onSearchSubmitted});

  @override
  State<AppTopBar> createState() => _AppTopBarState();
}

class _AppTopBarState extends State<AppTopBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.4,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();
    final keymap = context.watch<KeymapProvider>();
    final isDark = themeManager.isDark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border, width: 1)),
      ),
      child: Row(
        children: [
          // Logo
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, _) {
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: AppRadius.br8,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(
                        alpha: _pulseAnim.value * 0.45,
                      ),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.send,
                  color: Colors.white,
                  size: 18,
                ),
              );
            },
          ),

          const SizedBox(width: 16),

          // Global search (flexible center)
          Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.text,
              child: TextField(
                controller: widget.searchController,
                onSubmitted: widget.onSearchSubmitted,
                decoration: InputDecoration(
                  hintText: 'Search projects, flows, runs...',
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: border),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Action icons (no text; tooltip on hover)
          _TopBarIcon(
            icon: LucideIcons.settings,
            tooltip: _tip('Settings', keymap.getShortcut('app.settings')),
            onTap: () => AppNavigator.pushNamed(AppRouter.settingsRoute),
          ),
          const SizedBox(width: 8),
          _TopBarIcon(
            icon: themeManager.isDark ? LucideIcons.sun : LucideIcons.moon,
            tooltip: _tip(
              themeManager.isDark ? 'Light Mode' : 'Dark Mode',
              keymap.getShortcut('theme.toggle'),
            ),
            onTap: themeManager.toggleTheme,
          ),
          const SizedBox(width: 8),
          // Profile icon shows a small popup menu with Exit action
          GestureDetector(
            onTapDown: (tap) async {
              final renderBox = context.findRenderObject() as RenderBox?;
              final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
              final pos = renderBox?.localToGlobal(tap.globalPosition) ?? tap.globalPosition;
              final selected = await showMenu<String>(
                context: context,
                position: RelativeRect.fromLTRB(pos.dx, pos.dy, overlay.size.width - pos.dx, overlay.size.height - pos.dy),
                items: const [
                  PopupMenuItem(value: 'profile', child: Text('Profile')),
                  PopupMenuItem(value: 'exit', child: Text('Exit')),
                ],
              );

              if (selected == 'exit') {
                // Try to shutdown backend and exit immediately
                try {
                  await getIt<ProcessManager>().forceKill();
                } catch (_) {}
                exit(0);
              }
            },
            child: _TopBarIcon(
              icon: LucideIcons.user,
              tooltip: 'Profile',
              onTap: () {},
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = _isHovered ? AppColors.accentHover : AppColors.textSecondary;

    return ShadTooltip(
      builder: (context) => Text(widget.tooltip),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: AppDurations.micro,
            width: 44,
            height: 40,
            decoration: BoxDecoration(
              color: _isHovered
                  ? (isDark ? AppColors.darkSurface : AppColors.accent.withValues(alpha: 0.06))
                  : Colors.transparent,
              borderRadius: AppRadius.br8,
            ),
            child: Icon(widget.icon, size: 18, color: iconColor),
          ),
        ),
      ),
    );
  }
}

