import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' as inapp;
import 'package:local_notifier/local_notifier.dart';
import 'package:path/path.dart' as p;
import 'package:stress_pilot/core/network/http_client.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';

abstract class PilotWebViewController {
  Future<void> loadUrl(String url);
  Future<void> reload();
  Future<void> goBack();
  Future<bool> canGoBack();
  Future<void> dispose();
  void setVisible(bool visible);
}

class InAppPilotController implements PilotWebViewController {
  final inapp.InAppWebViewController controller;
  InAppPilotController(this.controller);

  @override
  Future<void> loadUrl(String url) => controller.loadUrl(
    urlRequest: inapp.URLRequest(url: inapp.WebUri(url)),
  );
  @override
  Future<void> reload() => controller.reload();
  @override
  Future<void> goBack() => controller.goBack();
  @override
  Future<bool> canGoBack() async => await controller.canGoBack();
  @override
  Future<void> dispose() async {}
  @override
  void setVisible(bool visible) {}
}

class LinuxPilotController implements PilotWebViewController {
  String _currentUrl;
  LinuxPilotController(this._currentUrl);

  Future<void> _open(String url) async {

    await Process.run('xdg-open', [url]);
  }

  @override
  Future<void> loadUrl(String url) async {
    _currentUrl = url;
    await _open(url);
  }

  @override
  Future<void> reload() => _open(_currentUrl);
  @override
  Future<void> goBack() async {}
  @override
  Future<bool> canGoBack() async => false;
  @override
  Future<void> dispose() async {}
  @override
  void setVisible(bool visible) {}
}

typedef PilotWebViewCreatedCallback = void Function(PilotWebViewController controller);

class PilotWebView extends StatefulWidget {
  final String initialUrl;
  final PilotWebViewCreatedCallback? onWebViewCreated;

  const PilotWebView({
    super.key,
    required this.initialUrl,
    this.onWebViewCreated,
  });

  @override
  State<PilotWebView> createState() => _PilotWebViewState();
}

class _PilotWebViewState extends State<PilotWebView> {
  final bool _isLinux = !kIsWeb && Platform.isLinux;
  bool _launched = false;
  bool _isDownloading = false;
  double _downloadProgress = 0;

  @override
  void initState() {
    super.initState();
    if (_isLinux) {

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_launched) {
          _launched = true;
          final controller = LinuxPilotController(widget.initialUrl);
          widget.onWebViewCreated?.call(controller);
          Process.run('xdg-open', [widget.initialUrl]);
        }
      });
    }
  }

  Future<void> _handleDownload(String url, String filename) async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    try {
      final String home = Platform.isWindows
          ? Platform.environment['USERPROFILE'] ?? ''
          : Platform.environment['HOME'] ?? '';

      if (home.isEmpty) throw Exception('Could not determine home directory');

      final pluginsDir = p.join(home, '.pilot', 'core', 'plugins');
      final dir = Directory(pluginsDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final savePath = p.join(pluginsDir, filename);
      final dio = HttpClient.getInstance();

      await dio.download(
        url,
        savePath,
        onReceiveProgress: (count, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = count / total;
            });
          }
        },
      );

      final notification = LocalNotification(
        title: 'Plugin Downloaded',
        body: '$filename has been installed to ~/.pilot/core/plugins',
        actions: [
          LocalNotificationAction(text: 'OK'),
        ],
      );
      notification.show();
    } catch (e) {
      final notification = LocalNotification(
        title: 'Download Failed',
        body: 'Failed to download $filename: $e',
      );
      notification.show();
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _isLinux ? _buildLinux() : _buildInApp(),
        if (_isDownloading) _buildDownloadOverlay(),
      ],
    );
  }

  Widget _buildDownloadOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.br16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.accent)),
              const SizedBox(height: 16),
              Text(
                'Downloading Plugin...',
                style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Installing to ~/.pilot/core/plugins',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: _downloadProgress > 0 ? _downloadProgress : null,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(AppColors.accent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinux() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.open_in_browser_rounded, size: 48),
          const SizedBox(height: 16),
          const Text('Opened in your default browser.'),
          const SizedBox(height: 12),
          TextButton.icon(
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Open again'),
            onPressed: () => Process.run('xdg-open', [widget.initialUrl]),
          ),
        ],
      ),
    );
  }

  Widget _buildInApp() {
    return inapp.InAppWebView(
      initialUrlRequest: inapp.URLRequest(url: inapp.WebUri(widget.initialUrl)),
      initialSettings: inapp.InAppWebViewSettings(
        javaScriptEnabled: true,
        useOnDownloadStart: true,
      ),
      onDownloadStartRequest: (controller, downloadStartRequest) async {
        final url = downloadStartRequest.url.toString();
        final filename = downloadStartRequest.suggestedFilename ?? url.split('/').last;
        await _handleDownload(url, filename);
      },
      onWebViewCreated: (controller) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onWebViewCreated?.call(InAppPilotController(controller));
        });
      },
    );
  }
}
