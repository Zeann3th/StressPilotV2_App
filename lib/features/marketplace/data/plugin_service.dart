import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:stress_pilot/core/system/logger.dart';
import 'package:stress_pilot/features/marketplace/domain/models/nexus_artifact.dart';

class PluginService {
  final Dio _dio = Dio();

  Future<String> _getUpdatesDirectory() async {
    String? appHome = Platform.environment['PILOT_HOME'];

    if (appHome == null || appHome.isEmpty) {
      final userHome =
          Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
      if (userHome != null) {
        appHome = p.join(userHome, '.pilot');
      } else {
        appHome = '.pilot';
      }
    }

    final updatesDir = p.join(appHome, 'core', 'updates');
    final dir = Directory(updatesDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return updatesDir;
  }

  /// Lists installed plugins (checking both plugins dir and updates dir if needed)
  /// For now, we still list from the main plugins directory as that's where the runtime loads them.
  /// NOTE: This logic might need to be expanded if we want to show pending updates.
  Future<List<File>> getInstalledPlugins() async {
    try {
      String? appHome = Platform.environment['PILOT_HOME'];
      if (appHome == null || appHome.isEmpty) {
        final userHome =
            Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
        if (userHome != null) {
          appHome = p.join(userHome, '.pilot');
        } else {
          appHome = '.pilot';
        }
      }

      final List<File> allPlugins = [];

      // 1. Scan core/plugins
      final pluginsDir = Directory(p.join(appHome, 'core', 'plugins'));
      if (await pluginsDir.exists()) {
        allPlugins.addAll(
          pluginsDir
              .listSync()
              .where((event) => event is File && event.path.endsWith('.jar'))
              .cast<File>(),
        );
      }

      // 2. Scan core/drivers (Requested for DB Jars)
      final driversDir = Directory(p.join(appHome, 'core', 'drivers'));
      if (await driversDir.exists()) {
        allPlugins.addAll(
          driversDir
              .listSync()
              .where((event) => event is File && event.path.endsWith('.jar'))
              .cast<File>(),
        );
      }

      return allPlugins;
    } catch (e) {
      AppLogger.warning('Failed to list plugins: $e', name: 'PluginService');
      return [];
    }
  }

  /// Downloads the plugin from Nexus to the appropriate updates subfolder
  Future<File> installPlugin(NexusArtifact artifact) async {
    try {
      if (artifact.downloadUrl == null) {
        throw Exception('Artifact has no download URL');
      }

      String subfolder = 'misc'; // Default

      // 1. Check for your own custom categories first
      if (artifact.groupId.startsWith('com.stresspilot')) {
        if (artifact.groupId.endsWith('.db')) {
          subfolder = 'connectors';
        } else if (artifact.groupId.endsWith('.reporter')) {
          subfolder = 'reporters';
        } else {
          subfolder = 'plugins';
        }
      }
      // 2. Check for Known Official Vendors (The "Translation Layer")
      else {
        switch (artifact.groupId) {
          case 'com.mysql':
          case 'org.postgresql':
          case 'com.microsoft.sqlserver':
          case 'org.mongodb':
          case 'org.xerial': // SQLite
            subfolder = 'connectors';
            break;

          case 'org.slf4j':
          case 'ch.qos.logback':
            subfolder = 'libs'; // Core libraries
            break;

          default:
            subfolder = 'libs';
            break;
        }
      }

      final updatesDir = await _getUpdatesDirectory();
      final targetDir = Directory(p.join(updatesDir, subfolder));

      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      // Create a clean filename: artifactId-version.jar
      final fileName = '${artifact.artifactId}-${artifact.version}.jar';
      final savePath = p.join(targetDir.path, fileName);

      AppLogger.info('Downloading plugin to $savePath', name: 'PluginService');

      // Download the file
      await _dio.download(
        artifact.downloadUrl!,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            // final percentage = (received / total * 100).toStringAsFixed(0);
            // Logging progress might be too verbose
          }
        },
      );

      AppLogger.info(
        'Plugin downloaded successfully: $fileName (Target: $subfolder)',
        name: 'PluginService',
      );

      return File(savePath);
    } catch (e) {
      AppLogger.error('Failed to download plugin: $e', name: 'PluginService');
      throw Exception('Failed to download plugin: $e');
    }
  }
}
