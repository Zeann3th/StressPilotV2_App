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

  bool _isPurgingCache = false;

  Future<void> _purgeCache() async {
    setState(() => _isPurgingCache = true);
    try {
      final prefs = await SharedPreferences.getInstance();

      final legacyKeys = [
        'projects_list_json',
        'flows_list_json',
      ];

      for (final key in legacyKeys) {
        if (prefs.containsKey(key)) {
          await prefs.remove(key);
        }
      }

      final allKeys = prefs.getKeys();
      for (final key in allKeys) {
        if (key.startsWith('endpoints_project_') && key.endsWith('_json')) {
          await prefs.remove(key);
        }
      }

      if (mounted) {
        PilotToast.show(context, 'Cache purged successfully');
      }
    } catch (e) {
      if (mounted) {
        PilotToast.show(context, 'Failed to purge cache: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isPurgingCache = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final border = AppColors.border;
    final textColor = AppColors.textPrimary;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version', style: AppTypography.heading.copyWith(color: textColor, fontSize: 20)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.sidebarBackground,
                borderRadius: AppRadius.br8,
                border: Border.all(color: border),
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
            const SizedBox(height: 12),
            Text('System Health', style: AppTypography.heading.copyWith(color: textColor, fontSize: 20)),
            const SizedBox(height: 12),
            _buildHealthStatus(border, textColor),
            const SizedBox(height: 24),
            Text('Cache Management', style: AppTypography.heading.copyWith(color: textColor, fontSize: 20)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.sidebarBackground,
                borderRadius: AppRadius.br8,
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.cleaning_services_rounded, color: AppColors.warning, size: 24),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Purge Application Cache',
                            style: AppTypography.bodyLg.copyWith(color: textColor, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('Delete legacy cached data. This will not delete your actual projects or settings.',
                            style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      PilotButton.ghost(
                        label: _isPurgingCache ? 'Purging...' : 'Purge Cache',
                        icon: Icons.delete_outline_rounded,
                        onPressed: _isPurgingCache ? null : _purgeCache,
                        foregroundOverride: AppColors.warning,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthStatus(Color border, Color textColor) {
    if (_lastError == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.sidebarBackground,
          borderRadius: AppRadius.br8,
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
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
        color: AppColors.sidebarBackground,
        borderRadius: AppRadius.br8,
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
                child: Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
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
                  color: AppColors.elevatedSurface,
                  borderRadius: AppRadius.br8,
                  border: Border.all(color: border),
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
