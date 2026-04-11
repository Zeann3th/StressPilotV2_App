import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  Future<void> _copyError() async {
    if (_lastError != null) {
      final text = 'Error: $_lastError\n\nStack Trace:\n${_lastStack ?? 'N/A'}';
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        PilotToast.show(context, 'Full error log copied');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = AppColors.surface;
    final border = AppColors.border;
    final textColor = AppColors.textPrimary;

    if (_lastError == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('System Health', style: AppTypography.heading.copyWith(color: textColor, fontSize: 20)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: AppRadius.br12,
              border: Border.all(color: border.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('System Operational',
                          style: AppTypography.bodyLg.copyWith(color: textColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('No issues or crashes have been detected recently.',
                          style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('System Health', style: AppTypography.heading.copyWith(color: textColor, fontSize: 20)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: AppRadius.br12,
            border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recent Crash Detected',
                            style: AppTypography.bodyLg.copyWith(color: AppColors.error, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('Occurred at ${_lastCrashTime ?? 'Unknown'}',
                            style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
                      borderRadius: AppRadius.br8,
                      border: Border.all(color: border.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      _lastError ?? '',
                      style: AppTypography.codeSm.copyWith(color: AppColors.error.withValues(alpha: 0.8)),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: PilotButton.ghost(
                      icon: Icons.content_copy_rounded,
                      onPressed: _copyError,
                      compact: true,
                      foregroundOverride: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PilotButton.ghost(
                    label: 'Dismiss Log',
                    onPressed: _clearLog,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
