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

  static bool enabled = kDebugMode;

  static LogLevel minimumLevel = LogLevel.debug;

  static void debug(
      String message, {
        String? name,
        Object? error,
        StackTrace? stackTrace,
      }) {
    _log(
      message,
      level: LogLevel.debug,
      name: name,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void info(
      String message, {
        String? name,
        Object? error,
        StackTrace? stackTrace,
      }) {
    _log(
      message,
      level: LogLevel.info,
      name: name,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void warning(
      String message, {
        String? name,
        Object? error,
        StackTrace? stackTrace,
      }) {
    _log(
      message,
      level: LogLevel.warning,
      name: name,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void error(
      String message, {
        String? name,
        Object? error,
        StackTrace? stackTrace,
      }) {
    _log(
      message,
      level: LogLevel.error,
      name: name,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void critical(
      String message, {
        String? name,
        Object? error,
        StackTrace? stackTrace,
      }) {
    _log(
      message,
      level: LogLevel.critical,
      name: name,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void _log(
      String message, {
        required LogLevel level,
        String? name,
        Object? error,
        StackTrace? stackTrace,
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

    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      final prefix = _getLevelPrefix(level);
      print('[$timestamp] $prefix [$logName] $message');
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