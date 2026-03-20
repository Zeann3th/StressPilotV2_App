import 'package:flutter/material.dart';
import 'package:webview_cef/webview_cef.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/common/presentation/widgets/app_topbar.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  static const _initialUrl = 'https://en.wikipedia.org';

  late WebViewController _controller;
  bool _isReady = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initWebview();
  }

  Future<void> _initWebview() async {
    await WebviewManager().initialize();

    _controller.setWebviewListener(
      WebviewEventsListener(
        onLoadStart: (controller, url) {
          if (mounted) setState(() => _isLoading = true);
        },
        onLoadEnd: (controller, url) {
          if (mounted) setState(() => _isLoading = false);
        },
      ),
    );

    await _controller.initialize(_initialUrl);

    if (mounted) setState(() => _isReady = true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textCol = isDark ? AppColors.textPrimary : AppColors.textLight;

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
                child: Stack(
                  children: [
                    // ── WebView ─────────────────────────────────
                    if (_isReady)
                      WebView(_controller)
                    else
                      Container(
                        color: surface,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              'Initializing browser engine...',
                              style: AppTypography.body.copyWith(
                                color: textCol.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ── Loading bar ──────────────────────────────
                    if (_isLoading && _isReady)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(
                          minHeight: 2,
                          backgroundColor: Colors.transparent,
                          color: Theme.of(context).colorScheme.primary,
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