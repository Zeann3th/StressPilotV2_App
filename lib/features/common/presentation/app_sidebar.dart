import 'package:flutter/material.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/themes/theme_manager.dart';
import 'package:stress_pilot/features/settings/presentation/pages/settings_page.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = getIt<ThemeManager>();
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 60,
      color: colors.surfaceContainerHighest,
      child: Column(
        children: [
          const SizedBox(height: 16),

          _icon(Icons.settings_outlined, 'Settings', () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
          }),

          const SizedBox(height: 8),
          _icon(Icons.notifications_outlined, 'Notifications', () {}),

          const Spacer(),

          _icon(
            themeManager.isDark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
            themeManager.isDark ? 'Light Mode' : 'Dark Mode',
            themeManager.toggleTheme,
          ),

          const SizedBox(height: 16),
          _icon(Icons.account_circle_outlined, 'Profile', () {}),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _icon(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: IconButton(icon: Icon(icon), onPressed: onTap),
    );
  }
}
