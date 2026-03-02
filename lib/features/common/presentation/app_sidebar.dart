import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/design/tokens.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/themes/theme_manager.dart';
import 'package:stress_pilot/core/input/keymap_provider.dart';

class AppSidebar extends StatefulWidget {
  const AppSidebar({super.key});

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar>
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
    _pulseAnim = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
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
      width: 70,
      decoration: BoxDecoration(
        color: bg,
        border: Border(right: BorderSide(color: border, width: 1)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Logo with pulse glow
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, _) {
              return Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: AppRadius.br8,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: _pulseAnim.value * 0.45),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              );
            },
          ),
          const SizedBox(height: 28),

          _SidebarIcon(
            icon: Icons.settings_outlined,
            tooltip: _tip('Settings', keymap.getShortcut('app.settings')),
            onTap: () => AppNavigator.pushNamed(AppRouter.settingsRoute),
          ),
          const SizedBox(height: 12),
          _SidebarIcon(
            icon: Icons.notifications_none_rounded,
            tooltip: _tip('Notifications', keymap.getShortcut('nav.notifications')),
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _SidebarIcon(
            icon: Icons.list_alt_rounded,
            tooltip: _tip('Runs', keymap.getShortcut('nav.runs')),
            onTap: () => AppNavigator.pushNamed(AppRouter.runsRoute),
          ),

          const Spacer(),

          _SidebarIcon(
            icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            tooltip: _tip(
              isDark ? 'Light Mode' : 'Dark Mode',
              keymap.getShortcut('theme.toggle'),
            ),
            onTap: themeManager.toggleTheme,
          ),
          const SizedBox(height: 12),
          _SidebarIcon(
            icon: Icons.storefront_outlined,
            tooltip: _tip('Marketplace', keymap.getShortcut('nav.marketplace')),
            onTap: () => AppNavigator.pushNamed(AppRouter.marketplaceRoute),
          ),
          const SizedBox(height: 12),
          _SidebarIcon(
            icon: Icons.account_circle_outlined,
            tooltip: 'Profile',
            onTap: () {},
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _tip(String label, String? shortcut) {
    if (shortcut == null || shortcut.isEmpty) return label;
    return '$label ($shortcut)';
  }
}

class _SidebarIcon extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _SidebarIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_SidebarIcon> createState() => _SidebarIconState();
}

class _SidebarIconState extends State<_SidebarIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final iconColor = _isHovered ? AppColors.accentHover : AppColors.textSecondary;

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: AppDurations.micro,
            width: 46,
            height: 40,
            decoration: BoxDecoration(
              color: _isHovered
                  ? AppColors.accent.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: AppRadius.br8,
            ),
            child: Icon(widget.icon, size: 20, color: iconColor),
          ),
        ),
      ),
    );
  }
}
