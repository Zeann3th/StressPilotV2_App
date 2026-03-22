import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stress_pilot/core/system/logger.dart';

class AppErrorBoundary extends StatefulWidget {
  final Widget child;
  const AppErrorBoundary({super.key, required this.child});

  static Future<void> saveCrashLog(Object error, StackTrace? stackTrace) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().toIso8601String();
      await prefs.setString('last_crash_error', error.toString());
      await prefs.setString('last_crash_stack', stackTrace?.toString() ?? '');
      await prefs.setString('last_crash_time', timestamp);
    } catch (_) {}
  }

  @override
  State<AppErrorBoundary> createState() => _AppErrorBoundaryState();
}

class _AppErrorBoundaryState extends State<AppErrorBoundary> {
  Object? _error;
  int _rebuildKey = 0;

  @override
  void initState() {
    super.initState();
  }

  void _recover() {
    AppLogger.info('Recovering from error — rebuilding app', name: 'ErrorBoundary');
    setState(() {
      _error = null;
      _rebuildKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      AppErrorBoundary.saveCrashLog(details.exception, details.stack);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _error == null) {
          setState(() {
            _error = details.exception;
          });
        }
      });
      return const SizedBox.shrink(); // Prevent the red screen of death
    };

    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF0D1117),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    _error.toString().length > 150
                        ? '${_error.toString().substring(0, 150)}...'
                        : _error.toString(),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _recover,
                  child: const Text('Recover & Continue'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return KeyedSubtree(
      key: ValueKey(_rebuildKey),
      child: widget.child,
    );
  }
}
