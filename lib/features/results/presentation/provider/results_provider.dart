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

  ResultsProvider(this._repository, this._flowService);

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

  void initialize(int flowId) async {
    _allLogs.clear();
    _filteredLogs.clear();
    _rpsBuckets.clear();
    _rtBuckets.clear();
    _resetMetrics();

    await _loadFlowDetails(flowId);

    _repository.connect();
    _subscription = _repository.logStream.listen(_onNewLogs);

    // This timer ensures the chart "slides" forward even if no new logs arrive
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateChartAndNotify();
    });
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
    _applyFilter(newLogsOnly: newLogs);
  }

  void _applyFilter({List<RequestLog>? newLogsOnly}) {
    List<RequestLog> processingLogs;

    if (newLogsOnly != null) {
      // Optimization: If we are just adding new logs and filter didn't change,
      // only process the new ones into the buckets.
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
      // Re-applying filter to all logs
      _rpsBuckets.clear();
      _rtBuckets.clear();
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
      // 1. Determine which second bucket this log belongs to
      DateTime timestamp;
      if (log.createdAt != null) {
        try {
          // Assuming UTC or generic ISO8601 string
          timestamp = DateTime.parse(log.createdAt!);
        } catch (e) {
          timestamp = DateTime.now();
        }
      } else {
        timestamp = DateTime.now();
      }

      final second = timestamp.millisecondsSinceEpoch ~/ 1000;

      // 2. Update RPS bucket
      _rpsBuckets[second] = (_rpsBuckets[second] ?? 0) + 1;

      // 3. Update Response Time bucket
      if (log.responseTime != null) {
        _rtBuckets
            .putIfAbsent(second, () => [])
            .add(log.responseTime!.toDouble());
      }
    }

    _recalculateTotals();
    _updateChartAndNotify();
  }

  void setEndpointFilter(int? endpointId) {
    if (_selectedEndpointId != endpointId) {
      _selectedEndpointId = endpointId;
      _applyFilter(); // Will clear buckets and re-process all filtered logs
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

    _rpsPoints.clear();
    _responseTimePoints.clear();

    // Generate a sliding window for the last 60 seconds
    for (int i = nowSecond - 60; i <= nowSecond; i++) {
      final double xValue = i * 1000.0;

      // Pull from buckets (even if they were updated "in the past" by a batch)
      final rps = (_rpsBuckets[i] ?? 0).toDouble();
      _rpsPoints.add(FlSpotData(x: xValue, y: rps));

      final latencies = _rtBuckets[i] ?? [];
      double avgRt = latencies.isEmpty
          ? 0
          : latencies.reduce((a, b) => a + b) / latencies.length;
      _responseTimePoints.add(FlSpotData(x: xValue, y: avgRt));
    }

    // Update the live RPS readout - use the current second's bucket
    // or you might prefer a rolling average of the last few seconds.
    // For now, let's use the last complete second (nowSecond - 1) to be stable,
    // or just the current accumulating second.
    _requestsPerSecond = (_rpsBuckets[nowSecond] ?? 0).toDouble();

    // Throttled notification for UI performance
    final now = DateTime.now();
    if (now.difference(_lastNotifyTime).inMilliseconds > 250) {
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
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _refreshTimer?.cancel();
    _repository.disconnect();
    super.dispose();
  }
}
