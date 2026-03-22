import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:stress_pilot/core/system/logger.dart';

enum ServiceHealth { healthy, degraded, dead }

class ServiceState {
  final String name;
  final ServiceHealth health;
  final DateTime lastHealthy;
  final int failureCount;
  final String? lastError;

  const ServiceState({
    required this.name,
    required this.health,
    required this.lastHealthy,
    this.failureCount = 0,
    this.lastError,
  });

  ServiceState copyWith({
    ServiceHealth? health,
    DateTime? lastHealthy,
    int? failureCount,
    String? lastError,
  }) => ServiceState(
    name: name,
    health: health ?? this.health,
    lastHealthy: lastHealthy ?? this.lastHealthy,
    failureCount: failureCount ?? this.failureCount,
    lastError: lastError ?? this.lastError,
  );
}

typedef RecoveryCallback = Future<void> Function();

class AppStateManager extends ChangeNotifier {
  static const _tag = 'AppStateManager';

  final Map<String, ServiceState> _services = {};
  final Map<String, RecoveryCallback> _recoveryCallbacks = {};
  final Map<String, Timer?> _recoveryTimers = {};

  void register(String name, RecoveryCallback onRecover) {
    _services[name] = ServiceState(
      name: name,
      health: ServiceHealth.healthy,
      lastHealthy: DateTime.now(),
    );
    _recoveryCallbacks[name] = onRecover;
    AppLogger.info('Registered service: $name', name: _tag);
  }

  void markHealthy(String name) {
    final current = _services[name];
    if (current == null) return;

    if (current.health != ServiceHealth.healthy) {
      AppLogger.info('$name recovered to healthy', name: _tag);
    }

    _services[name] = current.copyWith(
      health: ServiceHealth.healthy,
      lastHealthy: DateTime.now(),
      failureCount: 0,
      lastError: null,
    );
    _cancelRecovery(name);
    notifyListeners();
  }

  void markFailed(String name, {String? error, bool fatal = false}) {
    final current = _services[name];
    if (current == null) return;

    final failures = current.failureCount + 1;
    final health = fatal || failures >= 5
        ? ServiceHealth.dead
        : ServiceHealth.degraded;

    AppLogger.warning(
      '$name failed ($failures times): $error',
      name: _tag,
    );

    _services[name] = current.copyWith(
      health: health,
      failureCount: failures,
      lastError: error,
    );

    notifyListeners();

    if (health != ServiceHealth.dead) {
      _scheduleRecovery(name, failures);
    }
  }

  Future<void> recover(String name) async {
    final callback = _recoveryCallbacks[name];
    if (callback == null) return;

    AppLogger.info('Recovering $name...', name: _tag);
    try {
      await callback();
      markHealthy(name);
    } catch (e) {
      markFailed(name, error: e.toString());
    }
  }

  Future<void> recoverAll() async {
    for (final name in _services.keys) {
      final s = _services[name]!;
      if (s.health != ServiceHealth.healthy) {
        await recover(name);
      }
    }
  }

  ServiceHealth healthOf(String name) =>
      _services[name]?.health ?? ServiceHealth.dead;

  List<ServiceState> get unhealthyServices => _services.values
      .where((s) => s.health != ServiceHealth.healthy)
      .toList();

  bool get allHealthy => unhealthyServices.isEmpty;

  void _scheduleRecovery(String name, int failureCount) {
    _cancelRecovery(name);

    final delay = Duration(
      seconds: (2 * (1 << failureCount.clamp(0, 4))).clamp(2, 30),
    );

    AppLogger.info(
      'Scheduling $name recovery in ${delay.inSeconds}s',
      name: _tag,
    );

    _recoveryTimers[name] = Timer(delay, () => recover(name));
  }

  void _cancelRecovery(String name) {
    _recoveryTimers[name]?.cancel();
    _recoveryTimers[name] = null;
  }

  @override
  void dispose() {
    for (final t in _recoveryTimers.values) {
      t?.cancel();
    }
    super.dispose();
  }
}
