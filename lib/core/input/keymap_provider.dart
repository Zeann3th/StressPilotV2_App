import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:stress_pilot/core/input/keymap_service.dart';
import 'package:stress_pilot/core/input/shortcut_parser.dart';

class KeymapProvider extends ChangeNotifier {
  final KeymapService _service = KeymapService();
  Map<String, String> _keymap = {};
  List<MapEntry<SingleActivator, String>> _cachedActivators = [];
  bool _isLoading = false;

  Map<String, String> get keymap => _keymap;
  List<MapEntry<SingleActivator, String>> get cachedActivators => _cachedActivators;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    _keymap = await _service.loadKeymap();
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
    await _service.saveKeymap(_keymap);
  }
  
  Future<void> resetToDefaults() async {
    _keymap = _service.defaultKeymaps; 
    _updateCache();
    notifyListeners();
    await _service.saveKeymap(_keymap);
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
// Expose the getter for defaults if needed, simpler to just access via instance or static in service.
// For now, I'll fix the access issue by making _defaultKeymaps public or exposing a method.
