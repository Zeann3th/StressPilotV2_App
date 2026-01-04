import 'dart:async';
import 'dart:convert';

import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:stress_pilot/core/config/app_config.dart';
import 'package:stress_pilot/core/system/logger.dart';
import 'package:stress_pilot/features/results/domain/models/request_log.dart';

class ResultsRepository {
  StompClient? _client;
  final _logStreamController = StreamController<List<RequestLog>>.broadcast();

  Stream<List<RequestLog>> get logStream => _logStreamController.stream;

  void connect() {
    if (_client != null && _client!.connected) return;

    
    final wsUrl =
        '${AppConfig.apiBaseUrl.replaceFirst('http', 'ws')}/ws/websocket';

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

  void disconnect() {
    _client?.deactivate();
    _client = null;
  }

  void dispose() {
    disconnect();
    _logStreamController.close();
  }
}
