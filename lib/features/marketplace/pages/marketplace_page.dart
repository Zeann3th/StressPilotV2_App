import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
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
    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MarketplaceProvider>();
      provider.loadInstalledPlugins();
      provider.searchPlugins('');
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final provider = context.watch<MarketplaceProvider>();

    return Scaffold(
      backgroundColor: colors.surface,
      body: Column(
        children: [
          _buildHeader(context),
          Divider(height: 1, color: Theme.of(context).dividerTheme.color),
          _buildFilterBar(context, provider),
          Divider(height: 1, color: Theme.of(context).dividerTheme.color),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.artifacts.isEmpty
                ? _buildEmptyState(context, provider)
                : GridView.builder(
                    padding: const EdgeInsets.all(24),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 400,
                          mainAxisExtent: 180, // slightly more compact
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(CupertinoIcons.arrow_left),
            tooltip: 'Back',
            color: Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(width: 8),
          Icon(
            CupertinoIcons.cart_fill,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(
            'Plugin Marketplace',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, MarketplaceProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: CupertinoSearchTextField(
              controller: _searchController,
              placeholder: 'Search plugins...',
              onChanged: (query) => provider.searchPlugins(query),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, MarketplaceProvider provider) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.cube_box,
              size: 64,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            provider.statusMessage.isNotEmpty
                ? provider.statusMessage
                : 'No plugins found',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms.',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

enum PluginStatus { notInstalled, installed, updateAvailable }

class _PluginCard extends StatelessWidget {
  final NexusArtifact artifact;
  final PluginStatus status;
  final VoidCallback onInstall;

  const _PluginCard({
    required this.artifact,
    required this.status,
    required this.onInstall,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.extension_rounded,
                  color: colors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artifact.artifactId,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      artifact.groupId,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'v${artifact.version}',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(),
              _buildActionButton(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    switch (status) {
      case PluginStatus.installed:
        return Icon(
          Icons.check_circle,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        );
      case PluginStatus.updateAvailable:
        return FilledButton.icon(
          onPressed: onInstall,
          icon: const Icon(Icons.system_update_alt, size: 14),
          label: const Text('Update', style: TextStyle(fontSize: 12)),
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        );
      case PluginStatus.notInstalled:
        return FilledButton.icon(
          onPressed: onInstall,
          icon: const Icon(Icons.download_rounded, size: 14),
          label: const Text('Install', style: TextStyle(fontSize: 12)),
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        );
    }
  }
}
