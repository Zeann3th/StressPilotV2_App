import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stress_pilot/features/projects/domain/repositories/flow_repository.dart';
import 'package:stress_pilot/features/results/data/results_repository.dart';
import 'package:stress_pilot/features/results/domain/models/request_log.dart';

class FlSpotData {
  final double x;
  final double y;
  FlSpotData({required this.x, required this.y});
}

class ResultsProvider extends ChangeNotifier {
  final ResultsRepository _repository;
  final FlowRepository _flowRepository;

  final List<RequestLog> _allLogs = [];
  List<RequestLog> _filteredLogs = [];
  final Map<int, String> _endpointNames = {};
  int? _selectedEndpointId;

  final Map<int, int> _rpsBuckets = {};
  final Map<int, List<double>> _rtBuckets = {};

  double _requestsPerSecond = 0;
  double _avgResponseTime = 0;
  int _totalRequests = 0;
  int _errorCount = 0;

  final List<FlSpotData> _responseTimePoints = [];
  final List<FlSpotData> _rpsPoints = [];

  StreamSubscription? _subscription;
  Timer? _refreshTimer;
  DateTime _lastNotifyTime = DateTime.fromMillisecondsSinceEpoch(0);

  int? _currentRunId;

  int _lastPlottedSecond = -1;

  ResultsProvider(this._repository, this._flowRepository) {

    _repository.connect();
    _subscription = _repository.logStream.listen(_onNewLogs);

    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateChartAndNotify();
    });
  }

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

    if (_currentRunId == runId) {
      if (isCompleted) {
        stopChart();
      }
      return;
    }

    _currentRunId = runId;

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
      final flow = await _flowRepository.getFlowDetail(flowId);
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

  double _totalResponseTime = 0;

  void _onNewLogs(List<RequestLog> newLogs) {
    _allLogs.addAll(newLogs);

    if (_allLogs.length > 50000) {
      _allLogs.removeRange(0, _allLogs.length - 50000);

      _applyFilter();
    } else {
      _applyFilter(newLogsOnly: newLogs);
    }
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
      _updateTotalsIncremental(processingLogs);
    } else {

      _rpsBuckets.clear();
      _rtBuckets.clear();
      _lastPlottedSecond = -1;
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
      _recalculateTotals();
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
      _rpsBuckets[second] = (_rpsBuckets[second] ?? 0) + 1;

      if (log.responseTime != null) {
        _rtBuckets
            .putIfAbsent(second, () => [])
            .add(log.responseTime!.toDouble());
      }
    }
  }

  void setEndpointFilter(int? endpointId) {
    if (_selectedEndpointId != endpointId) {
      _selectedEndpointId = endpointId;
      _applyFilter();
    }
  }

  void _updateTotalsIncremental(List<RequestLog> newFilteredLogs) {
    _totalRequests += newFilteredLogs.length;
    for (var l in newFilteredLogs) {
      if (l.statusCode == null || l.statusCode! >= 400) {
        _errorCount++;
      }
      _totalResponseTime += (l.responseTime ?? 0);
    }

    if (_totalRequests > 0) {
      _avgResponseTime = _totalResponseTime / _totalRequests;
    } else {
      _avgResponseTime = 0;
    }
  }

  void _recalculateTotals() {
    _totalRequests = _filteredLogs.length;
    _errorCount = 0;
    _totalResponseTime = 0;

    for (var l in _filteredLogs) {
      if (l.statusCode == null || l.statusCode! >= 400) {
        _errorCount++;
      }
      _totalResponseTime += (l.responseTime ?? 0);
    }

    if (_totalRequests > 0) {
      _avgResponseTime = _totalResponseTime / _totalRequests;
    } else {
      _avgResponseTime = 0;
    }
  }

  void _updateChartAndNotify() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final nowSecond = nowMs ~/ 1000;

    final lastCompletedSecond = nowSecond - 1;

    if (_lastPlottedSecond == -1) {
      _lastPlottedSecond = lastCompletedSecond - 61;

    }

    bool addedNewPoints = false;

    for (int s = _lastPlottedSecond + 1; s <= lastCompletedSecond; s++) {
      final double xValue = s * 1000.0;

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

    final cutoffX = (lastCompletedSecond - 60) * 1000.0;

    _rpsPoints.removeWhere((p) => p.x < cutoffX);
    _responseTimePoints.removeWhere((p) => p.x < cutoffX);

    _requestsPerSecond = (_rpsBuckets[lastCompletedSecond] ?? 0).toDouble();

    final now = DateTime.now();
    if (addedNewPoints ||
        now.difference(_lastNotifyTime).inMilliseconds > 250) {
      _lastNotifyTime = now;
      notifyListeners();
      _cleanupOldBuckets(nowSecond);
    }
  }

  void _cleanupOldBuckets(int currentSecond) {

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
