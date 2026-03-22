import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';

class GithubWebviewPage extends StatefulWidget {
  final String url;
  const GithubWebviewPage({super.key, required this.url});

  @override
  State<GithubWebviewPage> createState() => _GithubWebviewPageState();
}

class _GithubWebviewPageState extends State<GithubWebviewPage> {
  InAppWebViewController? webViewController;
  double progress = 0;

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.background;
    final textCol = AppColors.textPrimary;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                PilotButton.ghost(
                  icon: Icons.close_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                Text(
                  'GitHub Issues',
                  style: AppTypography.heading.copyWith(color: textCol),
                ),
                const Spacer(),
                if (progress < 1.0)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 2,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.url)),
              onWebViewCreated: (controller) {
                webViewController = controller;
              },
              onProgressChanged: (controller, progress) {
                setState(() {
                  this.progress = progress / 100;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
