import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stress_pilot/features/projects/data/flow_service.dart';
import 'package:stress_pilot/features/results/data/results_repository.dart';
import 'package:stress_pilot/features/results/domain/models/request_log.dart';

class ResultsProvider extends ChangeNotifier {
  final ResultsRepository _repository;
  final FlowService _flowService;

  final List<RequestLog> _allLogs = [];
  List<RequestLog> _filteredLogs = [];

  // Metadata
  int? _currentFlowId;
  final Map<int, String> _endpointNames = {};

  // Filter
  int? _selectedEndpointId;

  // Metrics
  double _requestsPerSecond = 0;
  double _avgResponseTime = 0;
  int _totalRequests = 0;
  int _errorCount = 0;

  // Chart Data (Simplified for now)
  final List<FlSpotData> _responseTimePoints = [];
  final List<FlSpotData> _rpsPoints = [];

  StreamSubscription? _subscription;
  Timer? _metricsTimer;

  ResultsProvider(this._repository, this._flowService);

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
    _currentFlowId = flowId;
    _allLogs.clear();
    _filteredLogs.clear();
    _responseTimePoints.clear();
    _rpsPoints.clear();
    _resetMetrics();

    await _loadFlowDetails(flowId);

    _repository.connect();
    _subscription = _repository.logStream.listen(_onNewLogs);

    // Start a timer to calculate RPS every second
    _metricsTimer = Timer.periodic(const Duration(seconds: 1), _calculateRPS);
  }

  Future<void> _loadFlowDetails(int flowId) async {
    try {
      final flow = await _flowService.getFlowDetail(flowId);
      _endpointNames.clear();
      // We need to fetch endpoints to get names, but FlowDetail only has steps with endpointId.
      // Ideally we should fetch endpoints for the project or just use ID for now.
      // Or we can infer from steps if steps contain endpoint info?
      // FlowStepDTO has endpointId.
      // We might need to fetch endpoints separately or just show ID.
      // For now, let's just map ID to "Endpoint $id" if we can't get names easily without another API call.
      // Actually, let's try to be smart. The user said "call flow detail first to get the flow steps and endpoint id".
      // FlowDetail response usually contains steps.

      // If we want names, we might need to fetch endpoints.
      // Let's assume we just show IDs for now or "Endpoint X".
      // Wait, the user said "filter by api".

      // Let's just store IDs found in steps.
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
    // Filter logs for current flow/run if possible.
    // Since we don't have runId easily, we just take all incoming logs as "realtime".

    _allLogs.addAll(newLogs);
    _applyFilter();

    // Update metrics based on new logs
    for (var log in newLogs) {
      if (_selectedEndpointId != null && log.endpointId != _selectedEndpointId) {
        continue;
      }

      _totalRequests++;
      if (log.statusCode == null || log.statusCode! >= 400) {
        _errorCount++;
      }

      // Add to response time chart
      // We use totalRequests as X axis for simplicity or timestamp
      _responseTimePoints.add(
        FlSpotData(
          x: DateTime.now().millisecondsSinceEpoch.toDouble(),
          y: log.responseTime?.toDouble() ?? 0,
        ),
      );
    }

    // Keep chart points manageable
    if (_responseTimePoints.length > 100) {
      _responseTimePoints.removeRange(0, _responseTimePoints.length - 100);
    }

    notifyListeners();
  }

  void setEndpointFilter(int? endpointId) {
    _selectedEndpointId = endpointId;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_selectedEndpointId == null) {
      _filteredLogs = List.from(_allLogs);
    } else {
      _filteredLogs = _allLogs
          .where((l) => l.endpointId == _selectedEndpointId)
          .toList();
    }
    _recalculateMetrics();
  }

  void _recalculateMetrics() {
    _totalRequests = _filteredLogs.length;
    _errorCount = _filteredLogs
        .where((l) => l.statusCode == null || l.statusCode! >= 400)
        .length;
    if (_totalRequests > 0) {
      final totalTime = _filteredLogs.fold(
        0,
        (sum, l) => sum + (l.responseTime ?? 0),
      );
      _avgResponseTime = totalTime / _totalRequests;
    } else {
      _avgResponseTime = 0;
    }
  }

  void _calculateRPS(Timer timer) {
    // Simple RPS: Count logs in last second
    // In a real app, we'd use timestamps from logs.
    // Here we just check how many logs arrived since last tick?
    // Or better: use a sliding window.

    // For simplicity:
    // We can't easily calculate exact RPS without timestamps in logs relative to now.
    // Let's just assume the logs arriving are "now".
    // But _onNewLogs adds them.

    // Let's use a counter that resets every second.
    // But that's handled in _onNewLogs? No.

    // Let's just use the chart data.
    // Actually, let's just mock it or calculate from _filteredLogs timestamps if available.
    // RequestLog has createdAt (String).

    // Let's try to parse createdAt.
    // Assuming ISO8601.

    final now = DateTime.now();
    final oneSecondAgo = now.subtract(const Duration(seconds: 1));

    int count = 0;
    // Optimization: iterate backwards
    for (int i = _filteredLogs.length - 1; i >= 0; i--) {
      final log = _filteredLogs[i];
      if (log.createdAt != null) {
        try {
          final created = DateTime.parse(log.createdAt!);
          if (created.isAfter(oneSecondAgo)) {
            count++;
          } else {
            // Assuming logs are ordered, we can break
            // But they might not be strictly ordered by createdAt if async
            // break;
          }
        } catch (_) {}
      }
    }

    _requestsPerSecond = count.toDouble();
    _rpsPoints.add(
      FlSpotData(
        x: now.millisecondsSinceEpoch.toDouble(),
        y: _requestsPerSecond,
      ),
    );

    if (_rpsPoints.length > 60) {
      _rpsPoints.removeAt(0);
    }

    notifyListeners();
  }

  void _resetMetrics() {
    _requestsPerSecond = 0;
    _avgResponseTime = 0;
    _totalRequests = 0;
    _errorCount = 0;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _metricsTimer?.cancel();
    _repository.disconnect();
    super.dispose();
  }
}

class FlSpotData {
  final double x;
  final double y;
  FlSpotData({required this.x, required this.y});
}
