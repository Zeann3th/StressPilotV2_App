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
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(
                bottom: BorderSide(
                  color: colors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: colors.onSurface),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        CupertinoIcons.cart_fill,
                        size: 20,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Plugin Marketplace',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: 400,
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: (query) => provider.searchPlugins(query),
                        decoration: InputDecoration(
                          hintText: 'Search plugins...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colors.outlineVariant,
                            ),
                          ),
                          filled: true,
                          fillColor: colors.surfaceContainerHighest.withValues(
                            alpha: 0.3,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Expanded(child: SizedBox()),
              ],
            ),
          ),

          // Content
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.artifacts.isEmpty
                ? Center(
                    child: Text(
                      provider.statusMessage.isNotEmpty
                          ? provider.statusMessage
                          : 'No plugins found',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(32),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 400,
                          mainAxisExtent: 220,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.extension_rounded,
                  color: colors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artifact.artifactId,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      artifact.groupId,
                      style: TextStyle(
                        fontSize: 12,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'v${artifact.version}',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 11,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: _buildActionButton(context)),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    switch (status) {
      case PluginStatus.installed:
        return OutlinedButton.icon(
          onPressed: null, // Disabled
          icon: const Icon(Icons.check_circle, size: 18),
          label: const Text('Installed'),
        );
      case PluginStatus.updateAvailable:
        return FilledButton.icon(
          onPressed: onInstall,
          icon: const Icon(Icons.system_update_alt, size: 18),
          label: const Text('Update'),
        );
      case PluginStatus.notInstalled:
        return FilledButton.icon(
          onPressed: onInstall,
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text('Install'),
        );
    }
  }
}
