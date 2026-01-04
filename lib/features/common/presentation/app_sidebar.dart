import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/themes/theme_manager.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 70, // Slightly wider for comfort
      padding: const EdgeInsets.symmetric(vertical: 20),
      color: colors.surfaceContainer, // Dynamic background
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              CupertinoIcons.paperplane_fill,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 32),

          _icon(context, CupertinoIcons.settings, 'Settings', () {
            AppNavigator.pushNamed(AppRouter.settingsRoute);
          }),
          const SizedBox(height: 16),

          _icon(context, CupertinoIcons.bell, 'Notifications', () {}),
          const SizedBox(height: 16),

          _icon(context, CupertinoIcons.square_list, 'Runs', () {
            AppNavigator.pushNamed(AppRouter.runsRoute);
          }),

          const Spacer(),

          _icon(
            context,
            themeManager.isDark ? CupertinoIcons.sun_max : CupertinoIcons.moon,
            themeManager.isDark ? 'Light Mode' : 'Dark Mode',
            themeManager.toggleTheme,
          ),
          const SizedBox(height: 16),
          _icon(context, CupertinoIcons.person_crop_circle, 'Profile', () {}),
        ],
      ),
    );
  }

  Widget _icon(
    BuildContext context,
    IconData icon,
    String tooltip,
    VoidCallback onTap,
  ) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(
          icon,
          size: 22,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onPressed: onTap,
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}
