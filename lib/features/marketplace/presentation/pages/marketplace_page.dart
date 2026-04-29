import 'package:flutter/material.dart';
import 'package:stress_pilot/core/config/app_config.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/features/shared/presentation/widgets/fleet_page_bar.dart';
import 'package:stress_pilot/features/marketplace/presentation/widgets/pilot_webview.dart';

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
            const FleetPageBar(title: 'Marketplace'),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.sidebarBackground,
                  borderRadius: AppRadius.br6,
                  border: Border.all(color: AppColors.divider),
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.br6,
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
                          compact: true,
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
                          compact: true,
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
