import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stress_pilot/features/settings/domain/repositories/setting_repository.dart';

class SettingProvider extends ChangeNotifier {
  final SettingRepository _settingRepository;

  SettingProvider(this._settingRepository);

  Map<String, String> _configs = {};
  bool _isLoading = false;
  String? _error;

  Map<String, String> get configs => _configs;

  bool get isLoading => _isLoading;

  String? get error => _error;

  static const String _cachedConfigsKey = 'cached_config_map';

  Future<void> initialize() async {
    await _loadCachedConfigs();
    await loadConfigs();
  }

  Future<void> loadConfigs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _settingRepository.getAllConfigs();
      _configs = result;
      await _cacheConfigs();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setConfig(String key, String value) async {
    try {
      await _settingRepository.setConfigValue(key: key, value: value);

      _configs[key] = value;
      await _cacheConfigs();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<String?> getConfig(String key) async {
    if (_configs.containsKey(key)) return _configs[key];

    final value = await _settingRepository.getConfigValue(key);
    if (value != null) {
      _configs[key] = value;
      await _cacheConfigs();
      notifyListeners();
    }
    return value;
  }

  Future<void> _cacheConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedConfigsKey, _configs.toString());
  }

  Future<void> _loadCachedConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final string = prefs.getString(_cachedConfigsKey);

    if (string != null && string.isNotEmpty) {
      try {
        final parsed = string
            .replaceAll('{', '')
            .replaceAll('}', '')
            .split(',')
            .map((e) => e.trim().split(':'))
            .where((pair) => pair.length == 2)
            .map((pair) => MapEntry(pair[0], pair[1]))
            .toList();

        _configs = Map.fromEntries(parsed);
        notifyListeners();
      } catch (_) {}
    }
  }
}
