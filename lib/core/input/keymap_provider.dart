import 'package:flutter/material.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/input/shortcut_parser.dart';
import 'package:stress_pilot/core/system/settings_manager.dart';

class KeymapProvider extends ChangeNotifier {
  final Map<String, String> _keymap = {};
  final List<MapEntry<SingleActivator, String>> _cachedActivators = [];
  bool _isLoading = false;

  Map<String, String> get keymap => _keymap;
  List<MapEntry<SingleActivator, String>> get cachedActivators => _cachedActivators;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    final settingsManager = getIt<SettingsManager>();
    if (!settingsManager.isInitialized) {
      await settingsManager.initialize();
    }

    _keymap.clear();
    final defaultKeymapKeys = [
      'keymap.sidebar.toggle', 'keymap.app.settings', 'keymap.flow.save',
      'keymap.flow.run', 'keymap.flow.new', 'keymap.node.delete',
      'keymap.sidebar.tab.flows', 'keymap.sidebar.tab.nodes',
      'keymap.project.endpoints', 'keymap.project.environment',
      'keymap.project.view_all', 'keymap.nav.notifications',
      'keymap.nav.runs', 'keymap.theme.toggle'
    ];

    for (var key in defaultKeymapKeys) {
      final actionId = key.replaceFirst('keymap.', '');
      _keymap[actionId] = settingsManager.getString(key);
    }

    _updateCache();
    _isLoading = false;
    notifyListeners();
  }

  String? getShortcut(String actionId) {
    return _keymap[actionId];
  }

  Future<void> updateShortcut(String actionId, String shortcut) async {
    _keymap[actionId] = shortcut;
    _updateCache();
    notifyListeners();
    await getIt<SettingsManager>().setString('keymap.$actionId', shortcut);
  }

  Future<void> resetToDefaults() async {
    final settingsManager = getIt<SettingsManager>();
    await settingsManager.resetKeymaps();
    await initialize();
  }

  void _updateCache() {
    _cachedActivators.clear();
    for (final entry in _keymap.entries) {
      final activator = ShortcutParser.parseActivator(entry.value);
      if (activator != null) {
        _cachedActivators.add(MapEntry(activator, entry.key));
      }
    }
  }
}
