import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:stress_pilot/core/system/logger.dart';
import 'package:stress_pilot/core/network/http_client.dart';

class PluginService {
  final Dio _apiClient = HttpClient.getInstance();

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

      final pluginsDir = Directory(p.join(appHome, 'core', 'plugins'));
      if (await pluginsDir.exists()) {
        allPlugins.addAll(
          pluginsDir
              .listSync()
              .where((event) => event is File && event.path.endsWith('.jar'))
              .cast<File>(),
        );
      }

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

  Future<void> reloadPlugin(String pluginId) async {
    await _apiClient.post('/api/v1/plugins/$pluginId/reload');
  }

  Future<void> reloadAllPlugins() async {
    await _apiClient.post('/api/v1/plugins/reload-all');
  }

  Future<List<dynamic>> listPlugins() async {
    final response = await _apiClient.get('/api/v1/plugins/list');
    return response.data['data'] as List<dynamic>;
  }
}
