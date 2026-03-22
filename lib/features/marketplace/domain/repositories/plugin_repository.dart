import 'dart:io';

abstract class PluginRepository {
  Future<List<File>> getInstalledPlugins();
  Future<void> reloadPlugin(String pluginId);
  Future<void> reloadAllPlugins();
  Future<List<dynamic>> listPlugins();
}
