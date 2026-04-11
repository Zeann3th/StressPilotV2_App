import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/features/settings/presentation/provider/setting_provider.dart';
import 'package:stress_pilot/features/settings/presentation/widgets/settings_table.dart';

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
    final bg = AppColors.background;
    final surface = AppColors.surface;
    final border = AppColors.border;
    final textColor = AppColors.textPrimary;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          const AppTopBar(),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: AppRadius.br16,
                border: Border.all(color: border.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: AppRadius.br16,
                child: Column(
                  children: [
                    Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: surface,
                        border: Border(bottom: BorderSide(color: border.withValues(alpha: 0.3), width: 1)),
                      ),
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
                        ],
                      ),
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: SettingsTable(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
