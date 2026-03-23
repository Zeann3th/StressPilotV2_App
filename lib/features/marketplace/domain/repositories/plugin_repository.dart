import 'dart:io';
import '../models/plugin_descriptor.dart';

abstract class PluginRepository {
  Future<List<File>> getInstalledPlugins();
  Future<void> reloadPlugin(String pluginId);
  Future<void> reloadAllPlugins();
  Future<List<PluginDescriptor>> listPlugins();
}
