import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:stress_pilot/core/system/logger.dart';

class SettingsManager extends ChangeNotifier {
  static const String _dirName = '.pilot';
  static const String _subDirName = 'client';
  static const String _fileName = 'settings.json';

  Map<String, dynamic> _settings = {};
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<File> get _file async {
    final String home = Platform.environment['HOME'] ??
                        Platform.environment['USERPROFILE'] ??
                        '/';
    final dir = Directory(p.join(home, _dirName, _subDirName));

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File(p.join(dir.path, _fileName));
  }

  Future<void> initialize() async {
    try {
      final file = await _file;
      if (await file.exists()) {
        final content = await file.readAsString();
        _settings = jsonDecode(content);
      }

      final defaults = _defaultSettings;
      bool needsSave = false;
      for (final key in defaults.keys) {
        if (!_settings.containsKey(key)) {
          _settings[key] = defaults[key];
          needsSave = true;
        }
      }

      if (needsSave || !(await file.exists())) {
        await _save();
      }
    } catch (e) {
      AppLogger.warning('Error loading settings: $e', name: 'SettingsManager');
      _settings = Map.from(_defaultSettings);
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  String getString(String key, {String defaultValue = ''}) {
    return _settings[key]?.toString() ?? defaultValue;
  }

  Future<void> setString(String key, String value) async {
    _settings[key] = value;
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    try {
      final file = await _file;
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(_settings));
    } catch (e) {
      AppLogger.error('Failed to save settings: $e', name: 'SettingsManager');
    }
  }

  Future<void> resetKeymaps() async {
    final defaults = _defaultSettings;
    for (final key in defaults.keys) {
      if (key.startsWith('keymap.')) {
        _settings[key] = defaults[key];
      }
    }
    notifyListeners();
    await _save();
  }

  Map<String, dynamic> get _defaultSettings => {
    'workbench.colorTheme': 'dark',
    'keymap.sidebar.toggle': 'Control+B',
    'keymap.app.settings': 'Control+,',
    'keymap.flow.save': 'Control+S',
    'keymap.flow.run': 'F5',
    'keymap.flow.new': 'Control+Alt+N',
    'keymap.node.delete': 'Delete',
    'keymap.sidebar.tab.flows': 'Alt+1',
    'keymap.sidebar.tab.nodes': 'Alt+2',
    'keymap.project.endpoints': 'Control+Shift+E',
    'keymap.project.environment': 'Control+E',
    'keymap.project.view_all': 'Control+Shift+P',
    'keymap.nav.notifications': 'Control+Shift+N',
    'keymap.nav.runs': 'Control+R',
    'keymap.theme.toggle': 'Control+Shift+T',
  };
}
