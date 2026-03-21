import 'package:flutter/material.dart';
import 'package:stress_pilot/core/config/app_config.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/features/common/presentation/widgets/app_topbar.dart';
import 'package:stress_pilot/features/common/presentation/widgets/pilot_webview.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  PilotWebViewController? webViewController;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.textPrimary : AppColors.textLight;

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
                  child: Column(
                    children: [
                      Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: surface,
                          border: Border(bottom: BorderSide(color: border.withValues(alpha: 0.3), width: 1)),
                        ),
                        child: Row(
                          children: [
                            PilotButton.ghost(
                              icon: Icons.arrow_back_rounded,
                              onPressed: () {
                                webViewController?.setVisible(false);
                                Navigator.of(context).pop();
                              },
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Marketplace',
                              style: AppTypography.heading.copyWith(color: textColor),
                            ),
                            const Spacer(),
                            PilotButton.ghost(
                              icon: Icons.refresh_rounded,
                              onPressed: () {
                                webViewController?.reload();
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: PilotWebView(
                          initialUrl: AppConfig.pluginCmsBaseUrl,
                          onWebViewCreated: (controller) {
                            setState(() {
                              webViewController = controller;
                            });
                          },
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
