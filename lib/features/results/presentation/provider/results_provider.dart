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

  
  final Map<int, String> _endpointNames = {};

  
  int? _selectedEndpointId;

  
  double _requestsPerSecond = 0;
  double _avgResponseTime = 0;
  int _totalRequests = 0;
  int _errorCount = 0;

  
  final List<FlSpotData> _responseTimePoints = [];
  final List<FlSpotData> _rpsPoints = [];

  int _logsSinceLastTick = 0;
  double _responseSumSinceLastTick = 0;
  DateTime _lastNotifyTime = DateTime.fromMillisecondsSinceEpoch(0);
  double _totalResponseTimeSum = 0;

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
    _allLogs.clear();
    _filteredLogs.clear();
    _responseTimePoints.clear();
    _rpsPoints.clear();
    _resetMetrics();
    _totalResponseTimeSum = 0;

    await _loadFlowDetails(flowId);

    _repository.connect();
    _subscription = _repository.logStream.listen(_onNewLogs);

    
    _metricsTimer = Timer.periodic(
      const Duration(seconds: 1),
      _calculateMetricsTick,
    );
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
    debugPrint("[Performance] Received batch of ${newLogs.length} logs");

    _allLogs.addAll(newLogs);

    
    final matchingLogs = _selectedEndpointId == null
        ? newLogs
        : newLogs.where((l) => l.endpointId == _selectedEndpointId).toList();

    if (matchingLogs.isEmpty) return;

    _filteredLogs.addAll(matchingLogs);

    for (var log in matchingLogs) {
      _totalRequests++;
      _logsSinceLastTick++;

      if (log.statusCode == null || log.statusCode! >= 400) {
        _errorCount++;
      }

      if (log.responseTime != null) {
        final rt = log.responseTime!.toDouble();
        _totalResponseTimeSum += rt;
        _responseSumSinceLastTick += rt;
      }
    }

    
    if (_totalRequests > 0) {
      _avgResponseTime = _totalResponseTimeSum / _totalRequests;
    }

    
    if (_responseTimePoints.length > 100) {
      _responseTimePoints.removeRange(0, _responseTimePoints.length - 100);
    }

    
    final now = DateTime.now();
    if (now.difference(_lastNotifyTime).inMilliseconds > 250) {
      _lastNotifyTime = now;
      notifyListeners();
    }
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

    _totalResponseTimeSum = 0;
    if (_totalRequests > 0) {
      _totalResponseTimeSum = _filteredLogs.fold(
        0.0,
        (sum, l) => sum + (l.responseTime ?? 0),
      );
      _avgResponseTime = _totalResponseTimeSum / _totalRequests;
    } else {
      _avgResponseTime = 0;
    }
  }

  void _calculateMetricsTick(Timer timer) {
    
    _requestsPerSecond = _logsSinceLastTick.toDouble();

    
    double avgRtForTick = 0;
    if (_logsSinceLastTick > 0) {
      avgRtForTick = _responseSumSinceLastTick / _logsSinceLastTick;
    }

    
    _logsSinceLastTick = 0;
    _responseSumSinceLastTick = 0;

    final nowMs = DateTime.now().millisecondsSinceEpoch.toDouble();

    
    _rpsPoints.add(FlSpotData(x: nowMs, y: _requestsPerSecond));
    if (_rpsPoints.length > 60) _rpsPoints.removeAt(0);

    
    _responseTimePoints.add(FlSpotData(x: nowMs, y: avgRtForTick));
    if (_responseTimePoints.length > 60) _responseTimePoints.removeAt(0);

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
