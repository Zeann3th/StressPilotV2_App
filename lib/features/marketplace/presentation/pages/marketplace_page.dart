import 'package:flutter/material.dart';
import 'package:stress_pilot/core/config/app_config.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/features/shared/presentation/widgets/app_topbar.dart';
import 'package:stress_pilot/features/shared/presentation/widgets/pilot_webview.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  PilotWebViewController? webViewController;

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.background;
    final surface = AppColors.surface;
    final border = AppColors.border;
    final textColor = AppColors.textPrimary;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          webViewController?.setVisible(false);
        }
      },
      child: Scaffold(
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
                      Positioned.fill(
                        child: PilotWebView(
                          initialUrl: AppConfig.pluginCmsBaseUrl,
                          onWebViewCreated: (controller) {
                            setState(() {
                              webViewController = controller;
                            });
                          },
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: PilotButton.ghost(
                          icon: Icons.arrow_back_rounded,
                          onPressed: () {
                            webViewController?.setVisible(false);
                            Navigator.of(context).pop();
                          },
                          backgroundOverride: Colors.transparent,
                          foregroundOverride: textColor.withValues(alpha: 0.6),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: PilotButton.ghost(
                          icon: Icons.refresh_rounded,
                          onPressed: () {
                            webViewController?.reload();
                          },
                          backgroundOverride: Colors.transparent,
                          foregroundOverride: textColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
