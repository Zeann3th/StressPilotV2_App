import 'dart:async';
import 'package:flutter/material.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:stress_pilot/features/results/domain/repositories/run_repository.dart';
import 'package:stress_pilot/features/results/domain/models/run.dart';

class RunProvider extends ChangeNotifier {
  final RunRepository _runRepository;

  final Set<String> _trackedRunIds = {};
  final Map<String, Run> _runningRuns = {};

  RunProvider(this._runRepository) {
    syncRunningRuns();
  }

  bool get isAnyRunRunning => _runningRuns.values.any((run) =>
  run.status == 'RUNNING' || run.status == 'STARTING');

  List<Run> get runningRuns => _runningRuns.values.toList();

  Future<void> trackRun(String runId) async {
    if (_trackedRunIds.contains(runId)) return;
    _trackedRunIds.add(runId);
    _startGlobalPolling();
  }

  Future<void> syncRunningRuns() async {
    try {
      final allRuns = await _runRepository.getRuns();
      final running = allRuns.where((run) =>
      run.status == 'RUNNING' || run.status == 'STARTING');

      for (var run in running) {
        if (!_trackedRunIds.contains(run.id)) {
          _trackedRunIds.add(run.id);
          _runningRuns[run.id] = run;
        }
      }
      if (_trackedRunIds.isNotEmpty) {
        _startGlobalPolling();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error syncing running runs: $e');
    }
  }

  bool _isPolling = false;

  void _startGlobalPolling() {
    if (_isPolling) return;
    _isPolling = true;
    _pollAllTrackedRuns();
  }

  Future<void> _pollAllTrackedRuns() async {
    while (_isPolling && _trackedRunIds.isNotEmpty) {
      final idsToPoll = List<String>.from(_trackedRunIds);
      for (final runId in idsToPoll) {
        try {
          final run = await _runRepository.getRun(runId);

          if (run.status == 'COMPLETED' || run.status == 'ABORTED') {
            _trackedRunIds.remove(runId);
            _runningRuns.remove(runId);

            final notification = LocalNotification(
              title: run.status == 'COMPLETED'
                  ? 'Stress Test Completed'
                  : 'Stress Test Aborted',
              body: 'Run #$runId for Flow #${run.flowId} has ${run.status.toLowerCase()}.',
            );
            notification.show();
          } else {
            _runningRuns[runId] = run;
          }
        } catch (e) {
          debugPrint('Error polling run $runId: $e');

          _trackedRunIds.remove(runId);
          _runningRuns.remove(runId);
        }
      }
      notifyListeners();
      await Future.delayed(const Duration(seconds: 2));
    }
    _isPolling = false;
  }

  void stopPolling() {
    _isPolling = false;
  }

  Future<void> interruptRun(String runId) async {
    try {
      await _runRepository.interruptRun(runId);
      _trackedRunIds.remove(runId);
      _runningRuns.remove(runId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  Future<void> checkRunStatus(int flowId) async {
    await syncRunningRuns();
  }
}
