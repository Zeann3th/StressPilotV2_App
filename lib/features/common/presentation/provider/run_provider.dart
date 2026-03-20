import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stress_pilot/features/common/data/run_service.dart';
import 'package:stress_pilot/core/domain/entities/run.dart';

class RunProvider extends ChangeNotifier {
  final RunService _runService;

  Run? _activeRun;

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

  bool _isPolling = false;
  Duration _pollInterval = const Duration(seconds: 2);

  Future<void> _startPolling(int flowId) async {
    if (_isPolling) return;
    _isPolling = true;
    _pollInterval = const Duration(seconds: 2);
    
    while (_isPolling) {
      try {
        final lastRun = await _runService.getLastRun(flowId);
        if (lastRun.status != 'RUNNING' && lastRun.status != 'STARTING') {
          _activeRun = null;
          _stopPolling();
          notifyListeners();
          break;
        } else {
          _activeRun = lastRun;
          notifyListeners();
          
          // Use status as a factor for interval
          if (lastRun.status == 'STARTING') {
            _pollInterval = const Duration(seconds: 1);
          } else {
            // Check if run duration reached
            final created = lastRun.startedAt;
            final elapsed = DateTime.now().toUtc().difference(created.toUtc());
            if (elapsed.inSeconds >= lastRun.duration) {
              // Apply backoff as it should have finished
              _pollInterval = _pollInterval + const Duration(seconds: 1);
              if (_pollInterval > const Duration(seconds: 10)) {
                _pollInterval = const Duration(seconds: 10);
              }
            } else {
              _pollInterval = const Duration(seconds: 2);
            }
          }
        }
      } catch (_) {
        _activeRun = null;
        _stopPolling();
        notifyListeners();
        break;
      }
      
      await Future.delayed(_pollInterval);
    }
  }

  void _stopPolling() {
    _isPolling = false;
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
