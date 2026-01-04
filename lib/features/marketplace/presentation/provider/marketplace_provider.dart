import 'dart:io';
import 'package:flutter/material.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/features/marketplace/data/nexus_service.dart';
import 'package:stress_pilot/features/marketplace/data/plugin_service.dart';
import 'package:stress_pilot/features/marketplace/domain/models/nexus_artifact.dart';
import 'package:stress_pilot/features/marketplace/pages/marketplace_page.dart';

class MarketplaceProvider extends ChangeNotifier {
  final NexusService _nexusService = getIt<NexusService>();
  final PluginService _pluginService = getIt<PluginService>();

  List<NexusArtifact> _artifacts = [];
  List<File> _installedPlugins = [];
  bool _isLoading = false;
  String _statusMessage = '';

  List<NexusArtifact> get artifacts => _artifacts;
  List<File> get installedPlugins => _installedPlugins;
  bool get isLoading => _isLoading;
  String get statusMessage => _statusMessage;

  Future<void> loadInstalledPlugins() async {
    _installedPlugins = await _pluginService.getInstalledPlugins();
    notifyListeners();
  }

  Future<void> searchPlugins(String query) async {
    _isLoading = true;
    _statusMessage = '';
    notifyListeners();

    try {
      _artifacts = await _nexusService.searchPlugins(query);
    } catch (e) {
      _statusMessage = 'Failed to load plugins: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> installPlugin(
    NexusArtifact artifact,
    BuildContext context,
  ) async {
    if (artifact.downloadUrl == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _pluginService.installPlugin(
        artifact.downloadUrl!,
        artifact.artifactId,
        artifact.version,
      );

      // Refresh list to show "Installed" status
      await loadInstalledPlugins();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Installed ${artifact.artifactId}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  PluginStatus _compareVersions(String local, String remote) {
    if (local == remote) return PluginStatus.installed;
    // Basic semver check could go here. For now, if different, assume update?
    // Or just "Installed" if present.
    // Let's assume if they differ, it's an update.
    // Ideally we parse major.minor.patch
    return PluginStatus.updateAvailable;
  }

  String? _extractVersion(String filename, String artifactId) {
    // Expected format: artifactId-version.jar
    // e.g. stress-pilot-plugin-jdbc-1.0.0.jar
    try {
      final name = filename.split('/').last;
      if (!name.startsWith(artifactId)) return null;

      final withoutExt = name.replaceAll('.jar', '');
      // remove artifactId + hyphen
      // artifactId might contain hyphens, so be careful.
      // Assuming standard: [artifactId]-[version].jar
      final version = withoutExt.substring(artifactId.length + 1);
      return version;
    } catch (_) {
      return null;
    }
  }

  PluginStatus getPluginStatus(NexusArtifact artifact) {
    try {
      final installedFile = _installedPlugins.firstWhere((file) {
        final name = file.path.split(Platform.pathSeparator).last;
        return name.startsWith('${artifact.artifactId}-');
      });

      final localVersion = _extractVersion(
        installedFile.path,
        artifact.artifactId,
      );

      if (localVersion != null) {
        return _compareVersions(localVersion, artifact.version);
      }
      return PluginStatus.installed; // Fallback
    } catch (_) {
      return PluginStatus.notInstalled;
    }
  }
}
