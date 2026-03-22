import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/system/logger.dart';
import 'package:stress_pilot/core/system/process_manager.dart';
import '../../domain/models/agent_message.dart';
import '../../domain/repositories/agent_repository.dart';

class AgentRepositoryImpl implements AgentRepository {
  Process? _process;
  StreamSubscription? _stdoutSub;
  AgentState _state = AgentState.idle;

  final _eventController = StreamController<AgentEvent>.broadcast();

  @override
  Stream<AgentEvent> get events => _eventController.stream;

  @override
  AgentState get currentState => _state;

  @override
  Future<void> start() async {
    if (_state != AgentState.idle && _state != AgentState.error) return;

    _updateState(AgentState.starting);
    _emitSystem('Starting agent...');

    final pm = getIt<ProcessManager>();
    final agentPath = pm.resolveAgentPath();

    if (!File(agentPath).existsSync()) {
      AppLogger.critical('Agent not found: $agentPath', name: 'AgentRepository');
      _emitSystem('Agent executable not found at: $agentPath', isError: true);
      _updateState(AgentState.error);
      return;
    }

    try {
      _process = await Process.start(
        agentPath,
        ['--pipe'],
        environment: {
          ...Platform.environment,
          'FORCE_COLOR': '0',
        },
      );

      final completer = Completer<void>();

      _stdoutSub = _process!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
          AppLogger.debug('← $line', name: 'AgentRepository');
          _handleLine(line, completer);
        },
        onDone: () {
          AppLogger.warning('Agent process closed stdout', name: 'AgentRepository');
          if (!completer.isCompleted) completer.completeError('Process closed');
          _updateState(AgentState.error);
          _emitSystem('Agent disconnected', isError: true);
        },
      );

      _process!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        AppLogger.error('stderr: $line', name: 'AgentRepository');
      });

      await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Agent did not start in time'),
      );
    } catch (e, st) {
      AppLogger.critical('Failed to start agent', name: 'AgentRepository', error: e, stackTrace: st);
      _emitSystem('Failed to start: $e', isError: true);
      _updateState(AgentState.error);
    }
  }

  void _handleLine(String line, [Completer<void>? startCompleter]) {
    line = line.trim();
    if (line.isEmpty) return;

    Map<String, dynamic> json;
    try {
      json = jsonDecode(line);
    } catch (_) {
      AppLogger.debug('Non-JSON line: $line', name: 'AgentRepository');
      return;
    }

    final status = json['status'] as String? ?? '';

    switch (status) {
      case 'ready':
        _emitSystem('Agent ready');
        _updateState(AgentState.ready);
        startCompleter?.complete();

      case 'thinking':
        _updateState(AgentState.thinking);
        _eventController.add(AgentMessageEvent(content: '...', status: MessageStatus.thinking));

      case 'pending_tool_call':
        final calls = (json['tool_calls'] as List? ?? [])
            .map((t) => ToolCall.fromJson(Map<String, dynamic>.from(t)))
            .toList();
        final threadId = json['thread_id'] as String?;
        _updateState(AgentState.pendingApproval);
        _eventController.add(AgentToolCallEvent(calls, threadId ?? ''));

      case 'executing':
        _updateState(AgentState.thinking);

      case 'done':
        final reply = json['response'] as String? ?? '';
        final threadId = json['thread_id'] as String?;
        _eventController.add(AgentMessageEvent(content: reply, status: MessageStatus.done, threadId: threadId));
        _updateState(AgentState.ready);

      case 'error':
        final msg = json['message'] as String? ?? 'Unknown error';
        _emitSystem(msg, isError: true);
        _updateState(AgentState.ready);

      case 'ok':
        break;
    }
  }

  @override
  void sendMessage(String text, String threadId) {
    _send({
      'action': 'chat',
      'thread_id': threadId,
      'message': text,
    });
  }

  @override
  void approve({required String threadId, bool approved = true, String feedback = ''}) {
    _send({
      'action': 'approve',
      'thread_id': threadId,
      'approved': approved,
      if (feedback.isNotEmpty) 'feedback': feedback,
    });
  }

  @override
  void stop() {
    _stdoutSub?.cancel();
    _process?.kill();
    _updateState(AgentState.idle);
  }

  void _send(Map<String, dynamic> data) {
    final line = jsonEncode(data);
    AppLogger.debug('→ $line', name: 'AgentRepository');
    _process?.stdin.writeln(line);
  }

  void _updateState(AgentState s) {
    _state = s;
    _eventController.add(AgentStateEvent(s));
  }

  void _emitSystem(String msg, {bool isError = false}) {
    _eventController.add(AgentSystemEvent(msg, isError: isError));
  }
}
