import 'dart:convert';
import 'dart:io';

import 'package:stress_pilot/core/system/logger.dart';

class KeymapService {
  static const String _dirName = '.pilot';
  static const String _subDirName = 'client';
  static const String _fileName = 'keymaps.json';

  Future<File> get _file async {
    final String home = Platform.environment['HOME'] ?? '/';
    final dir = Directory('$home/$_dirName/$_subDirName');

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File('${dir.path}/$_fileName');
  }

  Future<Map<String, String>> loadKeymap() async {
    try {
      final file = await _file;
      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> json = jsonDecode(content);
        final loaded = json.map(
          (key, value) => MapEntry(key, value.toString()),
        );

        // Merge defaults with loaded config (loaded takes precedence)
        final merged = Map<String, String>.from(defaultKeymaps)..addAll(loaded);

        // If we added new keys, save the updated config back to disk
        if (merged.length > loaded.length) {
          await saveKeymap(merged);
        }

        return merged;
      } else {
        return _createDefaultKeymap(file);
      }
    } catch (e) {
      AppLogger.warning('Error loading keymap: $e', name: 'KeymapService');
      return defaultKeymaps;
    }
  }

  Future<Map<String, String>> _createDefaultKeymap(File file) async {
    final defaults = defaultKeymaps;
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(defaults),
    );
    return defaults;
  }

  Future<void> saveKeymap(Map<String, String> keymap) async {
    final file = await _file;
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(keymap),
    );
  }

  Map<String, String> get defaultKeymaps => {
    'sidebar.toggle': 'Control+B',
    'app.settings': 'Control+,',
    'flow.save': 'Control+S',
    'flow.run': 'F5',
    'flow.new': 'Control+Alt+N',
    'node.delete': 'Delete',
    'sidebar.tab.flows': 'Alt+1',
    'sidebar.tab.nodes': 'Alt+2',
    'project.endpoints': 'Control+Shift+E',
    'project.environment': 'Control+E',
    'project.view_all': 'Control+Shift+P',
    'nav.notifications': 'Control+Shift+N',
    'nav.runs': 'Control+R',
    'nav.browser_spy': 'Control+Shift+B',
    'nav.marketplace': 'Control+Shift+M',
    'theme.toggle': 'Control+Shift+T',
  };
}
