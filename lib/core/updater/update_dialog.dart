import 'package:flutter/material.dart';
import 'package:stress_pilot/core/updater/updater.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo info;

  const UpdateDialog({super.key, required this.info});

  static Future<void> checkAndShow(BuildContext context, {bool manual = false}) async {
    if (manual) {
      AppUpdater.resetCheck();
    }
    final update = await AppUpdater.check();
    if (!context.mounted) return;

    if (update == null) {
      if (manual) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stress Pilot is already up to date.'),
            behavior: SnackBarBehavior.floating,
            width: 320,
          ),
        );
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdateDialog(info: update),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog>
    with SingleTickerProviderStateMixin {
  _Phase _phase = _Phase.prompt;
  double _progress = 0;
  double _speedMbps = 0;
  String _eta = '';
  String? _error;

  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startDownload() {
    setState(() => _phase = _Phase.downloading);
    AppUpdater.downloadAndInstall(
      widget.info.downloadUrl,
      (progress, speed, eta) {
        if (!mounted) return;
        setState(() {
          _progress = progress;
          _speedMbps = speed;
          _eta = eta;
          if (progress >= 1.0) _phase = _Phase.installing;
        });
      },
    ).catchError((e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _error = e.toString();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: switch (_phase) {
            _Phase.prompt => _buildPrompt(colors),
            _Phase.downloading => _buildDownloading(colors),
            _Phase.installing => _buildInstalling(colors),
            _Phase.error => _buildError(colors),
          },
        ),
      ),
    );
  }

  Widget _buildPrompt(ColorScheme colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.system_update_rounded, color: colors.primary, size: 28),
            const SizedBox(width: 12),
            Text(
              'Update available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'v${widget.info.version}',
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              color: colors.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'A new version of Stress Pilot is ready to install.',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        if (widget.info.releaseNotes != null) ...[
          const SizedBox(height: 12),
          Text(
            widget.info.releaseNotes!,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _startDownload,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Update now'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDownloading(ColorScheme colors) {
    final pct = (_progress * 100).toStringAsFixed(1);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Downloading update…',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 10,
            backgroundColor: colors.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(colors.primary),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$pct%',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
            if (_speedMbps > 0)
              Text(
                '${_speedMbps.toStringAsFixed(1)} MB/s · $_eta remaining',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildInstalling(ColorScheme colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, child) => Opacity(opacity: _pulse.value, child: child),
          child: Icon(
            Icons.settings_rounded,
            size: 48,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Installing…',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'The app will restart automatically.',
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildError(ColorScheme colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.error_outline_rounded, color: colors.error, size: 24),
            const SizedBox(width: 10),
            Text(
              'Update failed',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _error!,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: colors.onErrorContainer,
              ),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Dismiss'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _phase = _Phase.prompt;
                  _error = null;
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ],
    );
  }
}

enum _Phase { prompt, downloading, installing, error }
