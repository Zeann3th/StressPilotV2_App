import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';

class AppHealthSection extends StatefulWidget {
  const AppHealthSection({super.key});

  @override
  State<AppHealthSection> createState() => _AppHealthSectionState();
}

class _AppHealthSectionState extends State<AppHealthSection> {
  String? _lastError;
  String? _lastStack;
  String? _lastCrashTime;

  @override
  void initState() {
    super.initState();
    _loadCrashLog();
  }

  Future<void> _loadCrashLog() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastError = prefs.getString('last_crash_error');
      _lastStack = prefs.getString('last_crash_stack');
      _lastCrashTime = prefs.getString('last_crash_time');
    });
  }

  Future<void> _clearLog() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_crash_error');
    await prefs.remove('last_crash_stack');
    await prefs.remove('last_crash_time');
    setState(() {
      _lastError = null;
      _lastStack = null;
      _lastCrashTime = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.textPrimary : AppColors.textLight;

    if (_lastError == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: AppRadius.br12,
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success),
            const SizedBox(width: 12),
            Text('App is healthy. No recent crashes.',
                style: AppTypography.body.copyWith(color: textColor)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.br12,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.error),
              const SizedBox(width: 12),
              Text('Last App Crash Detected',
                  style: AppTypography.heading.copyWith(color: AppColors.error)),
              const Spacer(),
              Text(_lastCrashTime ?? '',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          Text(_lastError ?? '',
              style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, color: AppColors.error),
              maxLines: 3,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PilotButton.ghost(
                label: 'Clear Log',
                onPressed: _clearLog,
              ),
              const SizedBox(width: 8),
              PilotButton.primary(
                label: 'Report Issue',
                icon: Icons.bug_report_rounded,
                onPressed: () {
                  AppNavigator.pushNamed(
                    AppRouter.reportIssueRoute,
                    arguments: {
                      'error': _lastError,
                      'stack': _lastStack,
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
