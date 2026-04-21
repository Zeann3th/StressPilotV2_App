import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:xterm/xterm.dart';

class AgentProvider extends ChangeNotifier {
  final terminal = Terminal(maxLines: 10000);
  Pty? _pty;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AgentProvider() {
    _initTerminal();
  }

  void _initTerminal() {

    terminal.onOutput = (data) {
      _pty?.write(utf8.encode(data));
    };

    terminal.onResize = (cols, rows, _, _) {
      _pty?.resize(rows, cols);
    };
  }

  Future<void> ensureStarted() async {
    if (_isInitialized || _isLoading) return;
    await restart();
  }

  Future<void> restart() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {

      _pty?.kill();
      _pty = null;

      terminal.buffer.clear();
      terminal.buffer.setCursor(0, 0);

      final supportDir = await getApplicationSupportDirectory();
      final agentDir = Directory(p.join(supportDir.path, 'agent'));
      if (!await agentDir.exists()) {
        await agentDir.create(recursive: true);
      }

      final agentPath = p.join(agentDir.path, 'stresspilot-agent.exe');
      final agentFile = File(agentPath);

      final assetData = await rootBundle.load('assets/agent/stresspilot-agent.exe');
      if (!await agentFile.exists() || await agentFile.length() != assetData.lengthInBytes) {
        final bytes = assetData.buffer.asUint8List(assetData.offsetInBytes, assetData.lengthInBytes);
        await agentFile.writeAsBytes(bytes);
      }

      _pty = Pty.start(
        agentPath,
        columns: terminal.viewWidth,
        rows: terminal.viewHeight,
        environment: {
          'TERM': 'xterm-256color',
          'COLORTERM': 'truecolor',
        },
      );

      _pty!.output.listen(
        (data) {
          terminal.write(utf8.decode(data));
        },
        onError: (e) {
          _error = e.toString();
          notifyListeners();
        },
        onDone: () {
          _isInitialized = false;
          notifyListeners();
        }
      );

      _isInitialized = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _pty?.kill();
    super.dispose();
  }
}
