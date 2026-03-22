import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/features/settings/presentation/provider/setting_provider.dart';
import 'package:stress_pilot/features/settings/presentation/widgets/settings_table.dart';
import 'package:stress_pilot/core/utils/tutorial_helper.dart';

import 'package:stress_pilot/features/shared/presentation/widgets/app_topbar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<SettingProvider>();
    Future.microtask(() async {
      await provider.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor = isDark ? AppColors.textPrimary : AppColors.textLight;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          const AppTopBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              children: [
                PilotButton.ghost(
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                Text(
                  'Settings',
                  style: AppTypography.heading.copyWith(color: textColor),
                ),
                const Spacer(),
                PilotButton.ghost(
                  label: 'Reset Tutorials',
                  icon: Icons.refresh_rounded,
                  onPressed: () async {
                    await TutorialHelper.resetTutorials();
                    if (context.mounted) {
                      PilotToast.show(context, 'Tutorials reset successfully');
                    }
                  },
                ),
              ],
            ),
          ),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SettingsTable(),
            ),
          ),
        ],
      ),
    );
  }
}
