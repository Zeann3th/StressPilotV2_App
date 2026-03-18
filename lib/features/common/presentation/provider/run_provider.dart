import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stress_pilot/features/common/data/run_service.dart';
import 'package:stress_pilot/core/domain/entities/run.dart';

class RunProvider extends ChangeNotifier {
  final RunService _runService;

  Run? _activeRun;
  Timer? _statusTimer;

  RunProvider(this._runService);

  Run? get activeRun => _activeRun;

  bool get isRunning => _activeRun != null && (_activeRun!.status == 'RUNNING' || _activeRun!.status == 'STARTING');

  Future<void> checkRunStatus(int flowId) async {
    try {
      final lastRun = await _runService.getLastRun(flowId);
      if (lastRun.status == 'RUNNING' || lastRun.status == 'STARTING') {
        _activeRun = lastRun;
        _startPolling(flowId);
      } else {
        _activeRun = null;
        _stopPolling();
      }
      notifyListeners();
    } catch (_) {
      _activeRun = null;
      _stopPolling();
      notifyListeners();
    }
  }

  void _startPolling(int flowId) {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final lastRun = await _runService.getLastRun(flowId);
        if (lastRun.status != 'RUNNING' && lastRun.status != 'STARTING') {
          _activeRun = null;
          _stopPolling();
          notifyListeners();
        } else {
          _activeRun = lastRun;
          notifyListeners();
        }
      } catch (_) {
        _activeRun = null;
        _stopPolling();
        notifyListeners();
      }
    });
  }

  void _stopPolling() {
    _statusTimer?.cancel();
    _statusTimer = null;
  }

  Future<void> interruptActiveRun() async {
    if (_activeRun == null) return;
    try {
      await _runService.interruptRun(_activeRun!.id);
      _activeRun = null;
      _stopPolling();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> interruptRun(int runId) async {
    try {
      await _runService.interruptRun(runId);
      if (_activeRun?.id == runId) {
        _activeRun = null;
        _stopPolling();
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
