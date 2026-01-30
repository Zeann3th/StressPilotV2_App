import 'package:flutter/material.dart';
import 'package:stress_pilot/core/input/keymap_service.dart';

class KeymapProvider extends ChangeNotifier {
  final KeymapService _service = KeymapService();
  Map<String, String> _keymap = {};
  bool _isLoading = false;

  Map<String, String> get keymap => _keymap;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    _keymap = await _service.loadKeymap();
    _isLoading = false;
    notifyListeners();
  }

  String? getShortcut(String actionId) {
    return _keymap[actionId];
  }

  Future<void> updateShortcut(String actionId, String shortcut) async {
    _keymap[actionId] = shortcut;
    notifyListeners();
    await _service.saveKeymap(_keymap);
  }
  
  Future<void> resetToDefaults() async {
    _keymap = _service.defaultKeymaps; 
    notifyListeners();
    await _service.saveKeymap(_keymap);
  }
}
// Expose the getter for defaults if needed, simpler to just access via instance or static in service.
// For now, I'll fix the access issue by making _defaultKeymaps public or exposing a method.
