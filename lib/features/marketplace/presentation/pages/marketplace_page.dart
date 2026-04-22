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
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          webViewController?.setVisible(false);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.baseBackground,
        body: Column(
          children: [
            const AppTopBar(),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: AppColors.sidebarBackground,
                  borderRadius: AppRadius.br8,
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.br8,
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
                          foregroundOverride: AppColors.textPrimary.withValues(alpha: 0.6),
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
                          foregroundOverride: AppColors.textPrimary.withValues(alpha: 0.6),
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
