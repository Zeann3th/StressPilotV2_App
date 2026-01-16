import 'package:stress_pilot/core/system/logger.dart';
import 'dart:async';
import 'package:puppeteer/puppeteer.dart';
import '../domain/request_entry.dart';

class BrowserService {
  Browser? _browser;
  Page? _page;
  final StreamController<RequestEntry> _requestController =
      StreamController<RequestEntry>.broadcast();

  Stream<RequestEntry> get requestStream => _requestController.stream;

  bool get isBrowserOpen => _browser != null && _browser!.isConnected;

  Future<void> launchBrowser() async {
    if (isBrowserOpen) return;

    AppLogger.info('Attempting to launch browser...', name: 'BrowserSpy');

    try {
      _browser = await puppeteer.launch(
        executablePath: '/usr/bin/google-chrome',
        headless: false,
        defaultViewport: null,
        args: [
          '--start-maximized',
          '--no-first-run',
          '--no-default-browser-check',
          '--disable-setuid-sandbox',
          '--no-sandbox',
        ],
      );

      AppLogger.info('Browser launched successfully.', name: 'BrowserSpy');

      // Get the initial page or create new one
      final pages = await _browser!.pages;
      _page = pages.isNotEmpty ? pages.first : await _browser!.newPage();

      // Enable request interception (allows us to read data and potentially modify later)
      await _page!.setRequestInterception(true);

      // Listen for requests to continue them
      _page!.onRequest.listen((request) {
        request.continueRequest();
      });

      // Capture responses
      _page!.onResponse.listen((response) async {
        try {
          final request = response.request;

          // Skip data URLs or empty URLs
          if (response.url.startsWith('data:') || response.url.isEmpty) return;

          String? responseBody;
          try {
            // Attempt to get text, might fail for binary
            responseBody = await response.text;
          } catch (e) {
            responseBody = '<Binary Data or Error: $e>';
          }

          final entry = RequestEntry(
            id: '${DateTime.now().millisecondsSinceEpoch}_${response.url.hashCode}',
            url: response.url,
            method: request.method.toString(),
            statusCode: response.status,
            statusText: response.statusText,
            requestHeaders: request.headers.cast<String, String>(),
            responseHeaders: response.headers.cast<String, String>(),
            requestBody: request.postData,
            responseBody: responseBody,
            timestamp: DateTime.now(),
            resourceType: request.resourceType?.toString(),
          );

          _requestController.add(entry);
        } catch (e, st) {
          AppLogger.error(
            'Error processing response',
            name: 'BrowserSpy',
            error: e,
            stackTrace: st,
          );
        }
      });

      // Handle browser disconnection
      _browser!.disconnected.then((_) {
        AppLogger.info('Browser disconnected/closed.', name: 'BrowserSpy');
        _browser = null;
        _page = null;
        // Optionally notify that browser closed?
        // We need a way to update UI state if the user closes the window manually.
        // The Service doesn't have a way to callback the provider easily without a stream or callback.
        // We can add a simple stream for status.
      });
    } catch (e, st) {
      AppLogger.error(
        'Error launching browser',
        name: 'BrowserSpy',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<void> stopBrowser() async {
    await _browser?.close();
    _browser = null;
    _page = null;
  }

  void dispose() {
    _requestController.close();
    stopBrowser();
  }
}
