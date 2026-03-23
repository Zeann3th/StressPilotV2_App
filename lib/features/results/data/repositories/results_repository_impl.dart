import 'dart:async';
import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:stress_pilot/core/config/app_config.dart';
import 'package:stress_pilot/core/system/logger.dart';
import 'package:stress_pilot/core/system/session_manager.dart';
import '../../domain/models/request_log.dart';
import '../../domain/repositories/results_repository.dart';

class ResultsRepositoryImpl implements ResultsRepository {
  final SessionManager _sessionManager;
  StompClient? _client;
  final _logStreamController = StreamController<List<RequestLog>>.broadcast();

  ResultsRepositoryImpl(this._sessionManager);

  @override
  Stream<List<RequestLog>> get logStream => _logStreamController.stream;

  @override
  bool get isConnected => _client != null && _client!.connected;

  @override
  void connect() {
    if (_sessionManager.sessionId == null) {
      AppLogger.warning(
        'Cannot connect to WebSocket: No active session. App may not be ready.',
        name: 'ResultsRepository',
      );
      return;
    }

    if (_client != null && _client!.connected) return;

    final wsUrl =
        '${AppConfig.apiBaseUrl.replaceFirst('http', 'ws')}/ws/websocket';

    AppLogger.info('Connecting to WebSocket: $wsUrl', name: 'ResultsRepository');

    _client = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: _onConnect,
        onWebSocketError: (dynamic error) => AppLogger.error(
          'WebSocket Error: $error',
          name: 'ResultsRepository',
        ),
        onStompError: (d) => AppLogger.error(
          'Stomp Error: ${d.body}',
          name: 'ResultsRepository',
        ),
        onDisconnect: (f) => AppLogger.info(
          'Disconnected from WebSocket',
          name: 'ResultsRepository',
        ),
      ),
    );

    _client!.activate();
  }

  void _onConnect(StompFrame frame) {
    AppLogger.info('Connected to WebSocket', name: 'ResultsRepository');
    _client!.subscribe(
      destination: '/topic/logs',
      callback: (frame) {
        if (frame.body != null) {
          try {
            final List<dynamic> jsonList = jsonDecode(frame.body!);
            final logs = jsonList.map((e) => RequestLog.fromJson(e)).toList();
            _logStreamController.add(logs);
          } catch (e) {
            AppLogger.error(
              'Error parsing logs: $e',
              name: 'ResultsRepository',
            );
          }
        }
      },
    );
  }

  @override
  void disconnect() {
    _client?.deactivate();
    _client = null;
  }

  @override
  void dispose() {
    disconnect();
    _logStreamController.close();
  }
}
