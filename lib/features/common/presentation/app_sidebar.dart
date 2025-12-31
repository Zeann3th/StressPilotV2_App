import 'package:flutter/material.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/themes/theme_manager.dart';

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
            AppNavigator.pushNamed(AppRouter.settingsRoute);
          }),

          const SizedBox(height: 8),
          _icon(Icons.notifications_outlined, 'Notifications', () {}),

          const SizedBox(height: 8),
          _icon(Icons.list_alt_outlined, 'Runs', () {
            AppNavigator.pushNamed(AppRouter.runsRoute);
          }),

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
