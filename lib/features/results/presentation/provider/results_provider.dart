import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stress_pilot/features/projects/data/flow_service.dart';
import 'package:stress_pilot/features/results/data/results_repository.dart';
import 'package:stress_pilot/features/results/domain/models/request_log.dart';

class FlSpotData {
  final double x;
  final double y;
  FlSpotData({required this.x, required this.y});
}

class ResultsProvider extends ChangeNotifier {
  final ResultsRepository _repository;
  final FlowService _flowService;

  final List<RequestLog> _allLogs = [];
  List<RequestLog> _filteredLogs = [];
  final Map<int, String> _endpointNames = {};
  int? _selectedEndpointId;

  // Buckets for historical recalculation (Key is Unix Second)
  final Map<int, int> _rpsBuckets = {};
  final Map<int, List<double>> _rtBuckets = {};

  // UI Metrics
  double _requestsPerSecond = 0;
  double _avgResponseTime = 0;
  int _totalRequests = 0;
  int _errorCount = 0;

  // Chart Data
  final List<FlSpotData> _responseTimePoints = [];
  final List<FlSpotData> _rpsPoints = [];

  StreamSubscription? _subscription;
  Timer? _refreshTimer;
  DateTime _lastNotifyTime = DateTime.fromMillisecondsSinceEpoch(0);

  int? _currentRunId;

  // Track the last second we have successfully plotted
  int _lastPlottedSecond = -1;

  ResultsProvider(this._repository, this._flowService) {
    // Start listening immediately on creation (App Startup)
    _repository.connect();
    _subscription = _repository.logStream.listen(_onNewLogs);

    // Start the chart ticker immediately or wait for first log?
    // Better to have it running to clear old data if needed, but let's sync it with data presence.
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateChartAndNotify();
    });
  }

  // Getters
  List<RequestLog> get logs => _filteredLogs;
  Map<int, String> get endpointNames => _endpointNames;
  int? get selectedEndpointId => _selectedEndpointId;
  double get requestsPerSecond => _requestsPerSecond;
  double get avgResponseTime => _avgResponseTime;
  int get totalRequests => _totalRequests;
  int get errorCount => _errorCount;
  List<FlSpotData> get responseTimePoints => _responseTimePoints;
  List<FlSpotData> get rpsPoints => _rpsPoints;

  void setRun(int runId, int flowId, {bool isCompleted = false}) async {
    // If we are already tracking this run, don't reset.
    if (_currentRunId == runId) {
      if (isCompleted) {
        stopChart();
      }
      return;
    }

    _currentRunId = runId;

    // Reset Data for new run
    _allLogs.clear();
    _filteredLogs.clear();
    _rpsBuckets.clear();
    _rtBuckets.clear();
    _resetMetrics();
    _lastPlottedSecond = -1;

    await _loadFlowDetails(flowId);
    notifyListeners();

    if (isCompleted) {
      stopChart();
    } else {
      // Ensure timer is running if not completed
      if (_refreshTimer == null || !_refreshTimer!.isActive) {
        _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          _updateChartAndNotify();
        });
      }
    }
  }

  void stopChart() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    notifyListeners();
  }

  Future<void> _loadFlowDetails(int flowId) async {
    try {
      final flow = await _flowService.getFlowDetail(flowId);
      _endpointNames.clear();
      for (var step in flow.steps) {
        if (step.endpointId != null) {
          _endpointNames[step.endpointId!] = "Endpoint ${step.endpointId}";
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading flow details: $e");
    }
  }

  void _onNewLogs(List<RequestLog> newLogs) {
    _allLogs.addAll(newLogs);
    // Limit memory usage: keep last 50,000 logs
    if (_allLogs.length > 50000) {
      _allLogs.removeRange(0, _allLogs.length - 50000);
    }
    _applyFilter(newLogsOnly: newLogs);
  }

  void _applyFilter({List<RequestLog>? newLogsOnly}) {
    List<RequestLog> processingLogs;

    if (newLogsOnly != null) {
      if (_selectedEndpointId == null) {
        processingLogs = newLogsOnly;
        _filteredLogs.addAll(newLogsOnly);
      } else {
        processingLogs = newLogsOnly
            .where((l) => l.endpointId == _selectedEndpointId)
            .toList();
        _filteredLogs.addAll(processingLogs);
      }
    } else {
      // Re-apply filter to all logs - this might be heavy but necessary if filter changes
      // NOTE: This does NOT affect the persistent buckets for the chart unless we clear them.
      // But _rpsBuckets ARE the source of truth for the chart.
      // If we change filter, we MUST rebuild buckets.
      _rpsBuckets.clear();
      _rtBuckets.clear();
      _lastPlottedSecond = -1; // Force chart rebuild on filter change
      _rpsPoints.clear();
      _responseTimePoints.clear();

      if (_selectedEndpointId == null) {
        _filteredLogs = List.from(_allLogs);
      } else {
        _filteredLogs = _allLogs
            .where((l) => l.endpointId == _selectedEndpointId)
            .toList();
      }
      processingLogs = _filteredLogs;
    }

    for (var log in processingLogs) {
      DateTime timestamp;
      if (log.createdAt != null) {
        try {
          timestamp = DateTime.parse(log.createdAt!);
        } catch (e) {
          timestamp = DateTime.now();
        }
      } else {
        timestamp = DateTime.now();
      }

      final second = timestamp.millisecondsSinceEpoch ~/ 1000;

      // Update buckets
      _rpsBuckets[second] = (_rpsBuckets[second] ?? 0) + 1;

      if (log.responseTime != null) {
        _rtBuckets
            .putIfAbsent(second, () => [])
            .add(log.responseTime!.toDouble());
      }
    }

    _recalculateTotals();
    // Don't update chart here, let the timer do it for smoothness
    // unless it's a filter change (handled by clearing above)
  }

  void setEndpointFilter(int? endpointId) {
    if (_selectedEndpointId != endpointId) {
      _selectedEndpointId = endpointId;
      _applyFilter();
    }
  }

  void _recalculateTotals() {
    _totalRequests = _filteredLogs.length;
    _errorCount = _filteredLogs
        .where((l) => l.statusCode == null || l.statusCode! >= 400)
        .length;

    if (_totalRequests > 0) {
      final totalTime = _filteredLogs.fold(
        0.0,
        (sum, l) => sum + (l.responseTime ?? 0),
      );
      _avgResponseTime = totalTime / _totalRequests;
    } else {
      _avgResponseTime = 0;
    }
  }

  void _updateChartAndNotify() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final nowSecond = nowMs ~/ 1000;

    // Stability Fix: Only plot up to nowSecond - 1 (last fully completed second)
    final lastCompletedSecond = nowSecond - 1;

    // Initialize logic if fresh
    if (_lastPlottedSecond == -1) {
      _lastPlottedSecond = lastCompletedSecond - 61;
      // Start with empty or pre-filled? logic below handles fill
    }

    bool addedNewPoints = false;

    // Append new seconds (filling gaps)
    for (int s = _lastPlottedSecond + 1; s <= lastCompletedSecond; s++) {
      final double xValue = s * 1000.0;

      // Get finalized bucket data
      // Note: "The past is the past" - we take the value AS IS now and never update it again for the chart.
      final rps = (_rpsBuckets[s] ?? 0).toDouble();
      _rpsPoints.add(FlSpotData(x: xValue, y: rps));

      final latencies = _rtBuckets[s] ?? [];
      double avgRt = latencies.isEmpty
          ? 0
          : latencies.reduce((a, b) => a + b) / latencies.length;
      _responseTimePoints.add(FlSpotData(x: xValue, y: avgRt));

      _lastPlottedSecond = s;
      addedNewPoints = true;
    }

    // Remove old points (Performance + Sliding Effect)
    // Keep 60 seconds of history
    final cutoffX = (lastCompletedSecond - 60) * 1000.0;

    // Efficient removal from start only if needed (assuming ordered)
    // But removeWhere is safer for correctness
    _rpsPoints.removeWhere((p) => p.x < cutoffX);
    _responseTimePoints.removeWhere((p) => p.x < cutoffX);

    // Consistency Fix: Update live text to match the last plotted point
    _requestsPerSecond = (_rpsBuckets[lastCompletedSecond] ?? 0).toDouble();

    // Throttled notification
    final now = DateTime.now();
    if (addedNewPoints ||
        now.difference(_lastNotifyTime).inMilliseconds > 250) {
      _lastNotifyTime = now;
      notifyListeners();
      _cleanupOldBuckets(nowSecond);
    }
  }

  void _cleanupOldBuckets(int currentSecond) {
    // Keep a bit more than 60s just in case
    final cutoff = currentSecond - 120;
    _rpsBuckets.removeWhere((k, v) => k < cutoff);
    _rtBuckets.removeWhere((k, v) => k < cutoff);
  }

  void _resetMetrics() {
    _requestsPerSecond = 0;
    _avgResponseTime = 0;
    _totalRequests = 0;
    _errorCount = 0;
    _rpsPoints.clear();
    _responseTimePoints.clear();
    _lastPlottedSecond = -1;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _refreshTimer?.cancel();
    _repository.disconnect();
    super.dispose();
  }
}
