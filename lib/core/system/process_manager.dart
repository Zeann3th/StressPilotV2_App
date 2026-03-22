import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:stress_pilot/core/config/app_config.dart';
import 'package:stress_pilot/core/system/logger.dart';

class PilotProcess {
  final String name;
  Process? process;
  StreamSubscription? stdoutSub;
  StreamSubscription? stderrSub;

  final List<String> outputBuffer = [];

  final StreamController<String> _outputController = StreamController<String>.broadcast();
  final StreamController<List<int>> _rawOutputController = StreamController<List<int>>.broadcast();

  PilotProcess(this.name);

  Stream<String> get output => _outputController.stream;
  Stream<List<int>> get rawOutput => _rawOutputController.stream;

  void addOutput(String data) {
    outputBuffer.add(data);
    _outputController.add(data);
  }

  void addRawOutput(List<int> data) {
    _rawOutputController.add(data);
  }

  void writeStdin(String data) {
    process?.stdin.writeln(data);
  }

  void writeRawStdin(List<int> data) {
    process?.stdin.add(data);
  }

  Future<void> dispose() async {
    await stdoutSub?.cancel();
    await stderrSub?.cancel();
    process?.kill();
    process = null;
    outputBuffer.clear();
  }
}

class ProcessManager {
  static const _logName = 'ProcessManager';
  final Map<String, PilotProcess> _processes = {};
  final Dio _dio;

  ProcessManager()
      : _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  bool get isDebugMode => kDebugMode;

  String _getExecutableDir() {
    return kDebugMode
        ? Directory.current.path
        : File(Platform.resolvedExecutable).parent.path;
  }

  String _getJavaExecutable() {
    if (kDebugMode) return 'java';
    final executableDir = _getExecutableDir();
    if (Platform.isWindows) {
      return path.join(executableDir, 'jdk', 'bin', 'java.exe');
    } else {
      return path.join(executableDir, 'jdk', 'bin', 'java');
    }
  }

  String _getAssetPath(String assetName) {
    if (kDebugMode) {
      return path.join(Directory.current.path, 'assets', assetName);
    } else {
      final String executableDir = File(Platform.resolvedExecutable).parent.path;
      return path.join(
        executableDir,
        'data',
        'flutter_assets',
        'assets',
        assetName,
      );
    }
  }

  String resolveAgentPath() {
    final exeName = Platform.isWindows ? 'stresspilot-agent.exe' : 'stresspilot-agent';
    return _getAssetPath('agent/$exeName');
  }

  String resolveAgentSourceDir() {
    return path.normalize(
      path.join(_getExecutableDir(), '..', 'stresspilot_agent'),
    );
  }

  PilotProcess? getProcess(String name) => _processes[name];

  Future<void> startBackend({bool attachLogs = true}) async {
    if (_processes.containsKey('backend')) {
      AppLogger.warning('Backend already running', name: _logName);
      return;
    }

    final jarPath = _getAssetPath('core/app.jar');
    final javaPath = _getJavaExecutable();
    final workingDir = _getExecutableDir();

    if (!await File(jarPath).exists()) {
      AppLogger.critical('JAR file not found at $jarPath', name: _logName);
      return;
    }

    try {
      final profile = kDebugMode ? 'dev' : 'prod';
      final process = await Process.start(
        javaPath,
        ['-jar', jarPath, '--spring.profiles.active=$profile'],
        workingDirectory: workingDir,
      );

      final pilotProcess = PilotProcess('backend');
      pilotProcess.process = process;
      _processes['backend'] = pilotProcess;

      _setupLogging(pilotProcess, attachLogs);

      AppLogger.info('Backend started (pid=${process.pid})', name: _logName);
      await _waitForHealth();
    } catch (e, st) {
      AppLogger.critical('Failed to start backend', name: _logName, error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> startAgent({bool pipeMode = false, bool pythonMode = false}) async {
    if (_processes.containsKey('agent')) {
      return;
    }

    Process? process;
    String? workingDir;

    if (pythonMode || kDebugMode) {
      final agentSourceDir = resolveAgentSourceDir();
      if (await Directory(agentSourceDir).exists()) {
        try {
          process = await Process.start(
            'powershell.exe',
            ['-NoProfile', '-Command', 'uv run python src/main.py ${pipeMode ? "--pipe" : ""}'],
            workingDirectory: agentSourceDir,
          );
          workingDir = agentSourceDir;
        } catch (e) {
          AppLogger.warning('Failed to start via uv run, trying executable...', name: _logName);
        }
      }
    }

    if (process == null) {
      final agentPath = resolveAgentPath();

      if (!await File(agentPath).exists()) {
        AppLogger.error('Agent executable not found at $agentPath', name: _logName);
        return;
      }

      try {
        final List<String> args = pipeMode ? ['--pipe'] : [];
        process = await Process.start(agentPath, args);
        workingDir = path.dirname(agentPath);
      } catch (e) {
        AppLogger.error('Failed to start agent executable', name: _logName, error: e);
        rethrow;
      }
    }

    final pilotProcess = PilotProcess('agent');
    pilotProcess.process = process;
    _processes['agent'] = pilotProcess;

    _setupLogging(pilotProcess, true);
    AppLogger.info('Agent started (pid=${process.pid}) in $workingDir', name: _logName);
  }

  Future<void> stopAgent() async {
    await stopProcess('agent');
  }

  void _setupLogging(PilotProcess p, bool attach) {
    if (!attach) return;

    final stdoutBroadcast = p.process!.stdout.asBroadcastStream();
    final stderrBroadcast = p.process!.stderr.asBroadcastStream();

    stdoutBroadcast.listen((data) {
      p.addRawOutput(data);
    });

    stderrBroadcast.listen((data) {
      p.addRawOutput(data);
    });

    p.stdoutSub = stdoutBroadcast
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      p.addOutput(line);
      AppLogger.info(line.trim(), name: '${p.name}.stdout');
    });

    p.stderrSub = stderrBroadcast
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      p.addOutput(line);
      AppLogger.error(line.trim(), name: '${p.name}.stderr');
    });
  }

  Future<void> stopProcess(String name) async {
    final p = _processes.remove(name);
    if (p != null) {
      AppLogger.info('Stopping process: $name', name: _logName);
      await p.dispose();
    }
  }

  Future<void> _waitForHealth() async {
    const int maxAttempts = 20;
    for (int i = 0; i < maxAttempts; i++) {
      try {
        final resp = await _dio.get('/api/v1/utilities/session');
        if (resp.statusCode == 200) return;
      } catch (_) {}
      await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
    }
    AppLogger.error('Backend health check failed', name: _logName);
  }

  Future<void> forceKill() async {
    for (var name in _processes.keys.toList()) {
      await stopProcess(name);
    }

    try {
      if (Platform.isWindows) {
        final result = await Process.run('cmd', ['/c', 'netstat -ano | findstr :52000']);
        for (var line in result.stdout.toString().split('\n')) {
          if (line.contains('LISTENING')) {
            final pid = line.trim().split(RegExp(r'\s+')).last;
            await Process.run('taskkill', ['/F', '/PID', pid, '/T']);
          }
        }
      }
    } catch (_) {}
  }
}
