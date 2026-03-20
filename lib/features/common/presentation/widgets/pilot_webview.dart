import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' as inapp;

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
    // Use xdg-open directly — avoids snap Firefox spawning issues
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
  bool _launched = false; // prevent multiple opens on rebuild

  @override
  void initState() {
    super.initState();
    if (_isLinux) {
      // Open once in initState, not in build
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

  @override
  Widget build(BuildContext context) {
    return _isLinux ? _buildLinux() : _buildInApp();
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
      initialSettings: inapp.InAppWebViewSettings(javaScriptEnabled: true),
      onWebViewCreated: (controller) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onWebViewCreated?.call(InAppPilotController(controller));
        });
      },
    );
  }
}