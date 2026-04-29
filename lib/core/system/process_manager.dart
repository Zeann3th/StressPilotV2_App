import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:stress_pilot/core/config/app_config.dart';
import 'package:stress_pilot/core/system/logger.dart';

final _kernel32 = Platform.isWindows ? DynamicLibrary.open('kernel32.dll') : null;

final _openProcess = _kernel32?.lookupFunction<
    IntPtr Function(Uint32, Bool, Uint32),
    int Function(int, bool, int)>('OpenProcess');

final _terminateProcess = _kernel32?.lookupFunction<
    Bool Function(IntPtr, Uint32),
    bool Function(int, int)>('TerminateProcess');

final _closeHandle = _kernel32?.lookupFunction<
    Bool Function(IntPtr),
    bool Function(int)>('CloseHandle');

void _winTerminatePid(int pid) {
  if (_openProcess == null || _terminateProcess == null || _closeHandle == null) return;
  final handle = _openProcess!(0x0001, false, pid);
  if (handle == 0) return;
  try {
    _terminateProcess!(handle, 1);
  } finally {
    _closeHandle!(handle);
  }
}

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

  static Future<int?> _getJavaVersion(String javaPath) async {
    try {
      final result = await Process.run(javaPath, ['-version'],
          stderrEncoding: const SystemEncoding());

      final output = result.stderr as String;

      final match = RegExp(r'version "(\d+)(\.\d+)?').firstMatch(output);
      if (match != null) {
        final versionStr = match.group(1)!;
        if (versionStr == '1') {

          final subVersion = match.group(2);
          if (subVersion != null && subVersion.startsWith('.8')) {
            return 8;
          }
        }
        return int.tryParse(versionStr);
      }
    } catch (_) {}
    return null;
  }

  String _getExecutableDir() {
    return kDebugMode
        ? Directory.current.path
        : File(Platform.resolvedExecutable).parent.path;
  }

  Future<String> _getJavaExecutable() async {
    if (kDebugMode) return 'java';

    try {
      return await _findBestSystemJava();
    } catch (e) {
      AppLogger.warning('Smart Java search failed: $e. Falling back to system "java" command.', name: _logName);
      return 'java';
    }
  }

  Future<String> _findBestSystemJava() async {
    const int targetVersion = 25;
    const int minVersion = 21;

    final List<String> candidates = [];
    if (Platform.isWindows) {
      candidates.addAll(_getWindowsJavaPaths());
    } else if (Platform.isLinux) {
      candidates.addAll(_getLinuxJavaPaths());
    } else if (Platform.isMacOS) {
      candidates.addAll(_getMacOSJavaPaths());
    }

    String? bestPath;
    int bestVersion = -1;

    for (final p in candidates) {
      if (!File(p).existsSync()) continue;
      final version = await _getJavaVersion(p);
      if (version == null) continue;

      if (version == targetVersion) {
        AppLogger.info('Found target Java $targetVersion at $p', name: _logName);
        return p;
      }

      if (version >= minVersion && version > bestVersion) {
        bestVersion = version;
        bestPath = p;
      }
    }

    if (bestPath != null) {
      AppLogger.info('Using best available Java ($bestVersion) at $bestPath', name: _logName);
      return bestPath;
    }

    throw Exception('No compatible Java version found (target: $targetVersion, minimum: $minVersion)');
  }

  List<String> _getWindowsJavaPaths() {
    final List<String> paths = [];
    final programFiles = Platform.environment['ProgramFiles'] ?? 'C:\\Program Files';
    final javaDir = Directory(path.join(programFiles, 'Java'));

    if (javaDir.existsSync()) {
      try {
        final jdks = javaDir.listSync().whereType<Directory>().toList();
        for (var jdk in jdks) {
          paths.add(path.join(jdk.path, 'bin', 'java.exe'));
        }
      } catch (_) {}
    }

    return paths;
  }

  List<String> _getLinuxJavaPaths() {
    final List<String> paths = ['/usr/bin/java', '/usr/local/bin/java'];
    final jvmDir = Directory('/usr/lib/jvm');

    if (jvmDir.existsSync()) {
      try {
        final jdks = jvmDir.listSync().whereType<Directory>().toList();
        for (var jdk in jdks) {
          paths.add(path.join(jdk.path, 'bin', 'java'));
        }
      } catch (_) {}
    }
    return paths;
  }

  List<String> _getMacOSJavaPaths() {
    final List<String> paths = ['/usr/bin/java', '/usr/local/bin/java'];
    final jvmDir = Directory('/Library/Java/JavaVirtualMachines');

    if (jvmDir.existsSync()) {
      try {
        final jdks = jvmDir.listSync().whereType<Directory>().toList();
        for (var jdk in jdks) {
          paths.add(path.join(jdk.path, 'Contents', 'Home', 'bin', 'java'));
        }
      } catch (_) {}
    }
    return paths;
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

  PilotProcess? getProcess(String name) => _processes[name];

  Future<void> _makeExecutable(String filePath) async {
    if (Platform.isWindows) return;
    if (!File(filePath).existsSync()) return;

    try {
      final result = await Process.run('chmod', ['+x', filePath]);
      if (result.exitCode != 0) {
        AppLogger.warning('Failed to make executable: $filePath (${result.stderr})', name: _logName);
      } else {
        AppLogger.info('Successfully made executable: $filePath', name: _logName);
      }
    } catch (e) {
      AppLogger.warning('Error while making executable: $filePath', name: _logName, error: e);
    }
  }

  Future<void> startBackend({
    bool attachLogs = true,
    void Function(int exitCode)? onExit,
  }) async {
    if (_processes.containsKey('backend')) {
      AppLogger.warning('Backend already running', name: _logName);
      return;
    }

    final jarPath = _getAssetPath('core/app.jar');
    final javaPath = await _getJavaExecutable();
    final workingDir = _getExecutableDir();

    AppLogger.info('Starting backend: java=$javaPath, jar=$jarPath', name: _logName);

    if (!await File(jarPath).exists()) {
      AppLogger.critical('JAR file not found at $jarPath', name: _logName);
      return;
    }

    if (!kDebugMode && !javaPath.contains(RegExp(r'java(\.exe)?$'))) {
      await _makeExecutable(javaPath);
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

      if (!kDebugMode) {
        process.stdout.transform(utf8.decoder).listen((data) {
          AppLogger.debug(data.trim(), name: 'backend.stdout');
        });
        process.stderr.transform(utf8.decoder).listen((data) {
          AppLogger.error(data.trim(), name: 'backend.stderr');
        });
        process.exitCode.then((code) async {
          AppLogger.error('Backend process exited with code: $code', name: _logName);
          _processes.remove('backend');
          if (onExit != null) {
            onExit(code);
          }
        });
      }

      _setupLogging(pilotProcess, attachLogs);

      AppLogger.info('Backend started (pid=${process.pid})', name: _logName);
      await _waitForHealth();
    } catch (e, st) {
      AppLogger.critical('Failed to start backend', name: _logName, error: e, stackTrace: st);
      rethrow;
    }
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
    const int maxAttempts = 30;

    for (int i = 0; i < maxAttempts; i++) {
      try {
        final resp = await _dio.get(
          '/api/v1/utilities/session',
          options: Options(
            sendTimeout: const Duration(seconds: 3),
            receiveTimeout: const Duration(seconds: 3),
            validateStatus: (_) => true,
          ),
        );
        if (resp.statusCode != null) {
          AppLogger.info('Backend up after ${i + 1} attempts (status: ${resp.statusCode})', name: _logName);
          return;
        }
      } catch (_) {}

      await Future.delayed(const Duration(seconds: 1));
    }
    AppLogger.error('Backend health check failed', name: _logName);
  }

  Future<void> forceKill() async {
    for (var name in _processes.keys.toList()) {
      final p = _processes.remove(name);
      p?.process?.kill();
    }

    try {
      if (Platform.isWindows) {

        final result = await Process.run('cmd', ['/c', 'netstat -ano | findstr :52000']);
        for (var line in result.stdout.toString().split('\n')) {
          if (line.contains('LISTENING')) {
            final pid = line.trim().split(RegExp(r'\s+')).last;
            if (pid.isNotEmpty) {
              await Process.run('taskkill', ['/F', '/PID', pid, '/T']);
            }
          }
        }

        await Process.run('powershell', [
          '-NoProfile',
          '-Command',
          'Get-CimInstance Win32_Process | Where-Object { \$_.CommandLine -like "*app.jar*" } | ForEach-Object { Stop-Process -Id \$_.ProcessId -Force }'
        ]);
      }
    } catch (_) {}
  }

  void brittleKill() {
    for (final name in _processes.keys.toList()) {
      final p = _processes[name];
      if (p == null || p.process == null) continue;
      final pid = p.process!.pid;
      try {
        if (Platform.isWindows) {
          _winTerminatePid(pid);
        } else {
          p.process!.kill(ProcessSignal.sigkill);
        }
      } catch (_) {}
    }
    _processes.clear();
  }
}
