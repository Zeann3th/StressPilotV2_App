import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/themes/components/layout/pilot_panel.dart';
import 'package:stress_pilot/features/settings/presentation/provider/setting_provider.dart';
import 'package:stress_pilot/features/settings/presentation/widgets/settings_table.dart';

import 'package:stress_pilot/features/shared/presentation/widgets/fleet_page_bar.dart';

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
    return Scaffold(
      backgroundColor: AppColors.sidebarBackground,
      body: Column(
        children: [
          FleetPageBar(title: 'Settings'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: PilotPanel(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: const SettingsTable(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
