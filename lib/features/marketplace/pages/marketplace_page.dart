import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/design/tokens.dart';
import 'package:stress_pilot/core/design/components.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/features/marketplace/domain/models/nexus_artifact.dart';
import 'package:stress_pilot/features/marketplace/presentation/provider/marketplace_provider.dart';

class MarketplacePage extends StatelessWidget {
  const MarketplacePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: getIt<MarketplaceProvider>(),
      child: const _MarketplaceView(),
    );
  }
}

class _MarketplaceView extends StatefulWidget {
  const _MarketplaceView();

  @override
  State<_MarketplaceView> createState() => _MarketplaceViewState();
}

class _MarketplaceViewState extends State<_MarketplaceView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MarketplaceProvider>();
      provider.loadInstalledPlugins();
      provider.searchPlugins('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.textPrimary : AppColors.textLight;
    final provider = context.watch<MarketplaceProvider>();

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // Header
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: surface,
              border: Border(bottom: BorderSide(color: border, width: 1)),
            ),
            child: Row(
              children: [
                PilotButton.ghost(
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                Icon(Icons.storefront_rounded, size: 18, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(
                  'Plugin Marketplace',
                  style: AppTypography.heading.copyWith(color: textColor),
                ),
              ],
            ),
          ),

          // Search bar
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            color: surface,
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 34,
                    child: PilotInput(
                      controller: _searchController,
                      placeholder: 'Search plugins...',
                      prefixIcon: Icons.search_rounded,
                      onChanged: (query) => provider.searchPlugins(query),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: border),

          // Content
          Expanded(
            child: provider.isLoading
                ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    ),
                  )
                : provider.artifacts.isEmpty
                ? _buildEmptyState(context, provider)
                : GridView.builder(
                    padding: const EdgeInsets.all(24),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 380,
                          mainAxisExtent: 170,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                    itemCount: provider.artifacts.length,
                    itemBuilder: (context, index) {
                      final artifact = provider.artifacts[index];
                      return _PluginCard(
                        artifact: artifact,
                        status: provider.getPluginStatus(artifact),
                        onInstall: () =>
                            provider.installPlugin(artifact, context),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, MarketplaceProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimary : AppColors.textLight;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.10),
              borderRadius: AppRadius.br12,
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.extension_rounded,
              size: 36,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            provider.statusMessage.isNotEmpty
                ? provider.statusMessage
                : 'No plugins found',
            style: AppTypography.heading.copyWith(color: textColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

enum PluginStatus { notInstalled, installed, updateAvailable }

class _PluginCard extends StatefulWidget {
  final NexusArtifact artifact;
  final PluginStatus status;
  final VoidCallback onInstall;

  const _PluginCard({
    required this.artifact,
    required this.status,
    required this.onInstall,
  });

  @override
  State<_PluginCard> createState() => _PluginCardState();
}

class _PluginCardState extends State<_PluginCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.textPrimary : AppColors.textLight;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppDurations.short,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: AppRadius.br12,
          border: Border.all(
            color: _hovered
                ? AppColors.accent.withValues(alpha: 0.4)
                : border,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        transform: Matrix4.translationValues(0, _hovered ? -2.0 : 0.0, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.10),
                    borderRadius: AppRadius.br8,
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Icon(
                    Icons.extension_rounded,
                    color: AppColors.accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.artifact.artifactId,
                        style: AppTypography.bodyLg.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.artifact.groupId,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.darkElevated,
                    borderRadius: AppRadius.br4,
                  ),
                  child: Text(
                    'v${widget.artifact.version}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                _buildAction(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAction() {
    switch (widget.status) {
      case PluginStatus.installed:
        return const Icon(
          Icons.check_circle_rounded,
          size: 18,
          color: AppColors.accent,
        );
      case PluginStatus.updateAvailable:
        return PilotButton.primary(
          icon: Icons.system_update_alt_rounded,
          label: 'Update',
          compact: true,
          onPressed: widget.onInstall,
        );
      case PluginStatus.notInstalled:
        return PilotButton.ghost(
          icon: Icons.download_rounded,
          label: 'Install',
          compact: true,
          onPressed: widget.onInstall,
        );
    }
  }
}
