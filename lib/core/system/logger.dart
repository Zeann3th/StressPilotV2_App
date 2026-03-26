import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

enum LogLevel {
  debug(0),
  info(400),
  warning(800),
  error(900),
  critical(1000);

  const LogLevel(this.value);
  final int value;
}

class AppLogger {
  static const String _defaultName = 'StressPilot';
  static final Map<String, IOSink> _fileSinks = {};

  static bool enabled = true;

  static LogLevel minimumLevel = kDebugMode ? LogLevel.debug : LogLevel.info;

  static void debug(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
    String? filePath,
  }) {
    _log(
      message,
      level: LogLevel.debug,
      name: name,
      error: error,
      stackTrace: stackTrace,
      filePath: filePath,
    );
  }

  static void info(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
    String? filePath,
  }) {
    _log(
      message,
      level: LogLevel.info,
      name: name,
      error: error,
      stackTrace: stackTrace,
      filePath: filePath,
    );
  }

  static void warning(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
    String? filePath,
  }) {
    _log(
      message,
      level: LogLevel.warning,
      name: name,
      error: error,
      stackTrace: stackTrace,
      filePath: filePath,
    );
  }

  static void error(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
    String? filePath,
  }) {
    _log(
      message,
      level: LogLevel.error,
      name: name,
      error: error,
      stackTrace: stackTrace,
      filePath: filePath,
    );
  }

  static void critical(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
    String? filePath,
  }) {
    _log(
      message,
      level: LogLevel.critical,
      name: name,
      error: error,
      stackTrace: stackTrace,
      filePath: filePath,
    );
  }

  static Future<void> _logToFile(String filePath, String message) async {
    try {
      IOSink? sink = _fileSinks[filePath];
      if (sink == null) {
        final file = File(filePath);
        if (!await file.parent.exists()) {
          await file.parent.create(recursive: true);
        }
        sink = file.openWrite(mode: FileMode.append);
        _fileSinks[filePath] = sink;
      }
      sink.writeln('[${DateTime.now().toIso8601String()}] $message');
    } catch (e) {
      // Fallback to print if file logging fails to avoid recursion
      print('Failed to log to file $filePath: $e');
    }
  }

  static void _log(
    String message, {
    required LogLevel level,
    String? name,
    Object? error,
    StackTrace? stackTrace,
    String? filePath,
  }) {
    if (!enabled || level.value < minimumLevel.value) return;

    final logName = name ?? _defaultName;

    developer.log(
      message,
      time: DateTime.now(),
      level: level.value,
      name: logName,
      error: error,
      stackTrace: stackTrace,
    );

    final timestamp = DateTime.now().toIso8601String();
    final prefix = _getLevelPrefix(level);
    final formattedMessage = '$prefix [$logName] $message';

    if (filePath != null) {
      _logToFile(filePath, formattedMessage);
      if (error != null) _logToFile(filePath, '  Error: $error');
      if (stackTrace != null) _logToFile(filePath, '  Stack: $stackTrace');
    }

    if (kDebugMode) {
      print('[$timestamp] $formattedMessage');
      if (error != null) {
        print('  Error: $error');
      }
      if (stackTrace != null) {
        print('  Stack: $stackTrace');
      }
    }
  }

  static String _getLevelPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.critical:
        return 'CRIT';
    }
  }

  static Future<void> dispose() async {
    for (final sink in _fileSinks.values) {
      await sink.flush();
      await sink.close();
    }
    _fileSinks.clear();
  }

  static Future<T> measure<T>(
      String operation,
      Future<T> Function() function, {
        String? name,
      }) async {
    final stopwatch = Stopwatch()..start();
    info('Starting: $operation', name: name);

    try {
      final result = await function();
      stopwatch.stop();
      info(
        'Completed: $operation in ${stopwatch.elapsedMilliseconds}ms',
        name: name,
      );
      return result;
    } catch (e, st) {
      stopwatch.stop();
      error(
        'Failed: $operation after ${stopwatch.elapsedMilliseconds}ms',
        name: name,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
