import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/updater/update_dialog.dart';

class AppAboutSection extends StatefulWidget {
  const AppAboutSection({super.key});

  @override
  State<AppAboutSection> createState() => _AppAboutSectionState();
}

class _AppAboutSectionState extends State<AppAboutSection> {
  String? _lastError;
  String? _lastStack;
  String? _lastCrashTime;
  String _appVersion = '...';

  @override
  void initState() {
    super.initState();
    _loadCrashLog();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = info.version;
      });
    }
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

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version', style: AppTypography.heading.copyWith(color: textColor, fontSize: 20)),
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
                      color: AppColors.accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.auto_awesome_rounded, color: AppColors.accent, size: 24),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Stress Pilot v$_appVersion',
                            style: AppTypography.bodyLg.copyWith(color: textColor, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('The application is running the latest stable build.',
                            style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      PilotButton.ghost(
                        label: 'Check for Updates',
                        icon: Icons.refresh_rounded,
                        onPressed: () => UpdateDialog.checkAndShow(context, manual: true),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            Text('System Health', style: AppTypography.heading.copyWith(color: textColor, fontSize: 20)),
            const SizedBox(height: 24),
            _buildHealthStatus(surface, border, textColor, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthStatus(Color surface, Color border, Color textColor, bool isDark) {
    if (_lastError == null) {
      return Container(
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
      );
    }

    return Container(
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
    );
  }
}
