import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:stress_pilot/core/system/logger.dart';

class PluginService {
  final Dio _dio = Dio(); // Separate Dio instance for downloads if needed

  Future<String> _getPluginsDirectory() async {
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

    final pluginsDir = p.join(appHome, 'core', 'plugins');
    final dir = Directory(pluginsDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return pluginsDir;
  }

  Future<List<File>> getInstalledPlugins() async {
    try {
      final path = await _getPluginsDirectory();
      final dir = Directory(path);

      if (await dir.exists()) {
        return dir
            .listSync() // Sync is usually fine for local directory listing unless huge
            .where((event) => event is File && event.path.endsWith('.jar'))
            .cast<File>()
            .toList();
      }
      return [];
    } catch (e) {
      AppLogger.warning('Failed to list plugins: $e', name: 'PluginService');
      return [];
    }
  }

  /// Downloads the plugin from Nexus to the local directory
  Future<File> installPlugin(
    String downloadUrl,
    String artifactId,
    String version,
  ) async {
    try {
      final dirPath = await _getPluginsDirectory();
      // Create a clean filename: stress-test-plugin-1.0.0.jar
      final fileName = '$artifactId-$version.jar';
      final savePath = p.join(dirPath, fileName);

      AppLogger.info('Downloading plugin to $savePath', name: 'PluginService');

      // Download the file
      await _dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          // Optional: You could expose a stream to show progress bars in UI
          if (total != -1) {
            final percentage = (received / total * 100).toStringAsFixed(0);
            AppLogger.debug(
              'Download progress: $percentage%',
              name: 'PluginService',
            );
          }
        },
      );

      AppLogger.info(
        'Plugin installed successfully: $fileName',
        name: 'PluginService',
      );
      return File(savePath);
    } catch (e) {
      AppLogger.error('Failed to download plugin: $e', name: 'PluginService');
      throw Exception('Failed to download plugin: $e');
    }
  }
}
