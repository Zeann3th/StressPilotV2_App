import 'package:flutter/material.dart';
import 'package:stress_pilot/features/marketplace/domain/models/plugin_descriptor.dart';
import 'package:stress_pilot/features/marketplace/domain/repositories/plugin_repository.dart';
import 'package:stress_pilot/core/system/logger.dart';

class PluginSettingsProvider extends ChangeNotifier {
  final PluginRepository _repository;

  List<PluginDescriptor> _plugins = [];
  bool _isLoading = false;
  String? _error;
  PluginDescriptor? _selectedPlugin;

  PluginSettingsProvider(this._repository);

  List<PluginDescriptor> get plugins => _plugins;
  bool get isLoading => _isLoading;
  String? get error => _error;
  PluginDescriptor? get selectedPlugin => _selectedPlugin;

  Future<void> loadPlugins() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _plugins = await _repository.listPlugins();
      if (_selectedPlugin != null) {

        final stillExists = _plugins.any((p) => p.pluginId == _selectedPlugin!.pluginId);
        if (!stillExists) _selectedPlugin = null;
      }
    } catch (e) {
      AppLogger.error('Failed to load plugins', name: 'PluginSettingsProvider', error: e);
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectPlugin(PluginDescriptor? plugin) {
    _selectedPlugin = plugin;
    notifyListeners();
  }

  Future<void> reloadPlugin(String pluginId) async {
    try {
      await _repository.reloadPlugin(pluginId);
      await loadPlugins();
    } catch (e) {
      AppLogger.error('Failed to reload plugin: $pluginId', name: 'PluginSettingsProvider', error: e);
      rethrow;
    }
  }

  Future<void> reloadAllPlugins() async {
    try {
      await _repository.reloadAllPlugins();
      await loadPlugins();
    } catch (e) {
      AppLogger.error('Failed to reload all plugins', name: 'PluginSettingsProvider', error: e);
      rethrow;
    }
  }
}
