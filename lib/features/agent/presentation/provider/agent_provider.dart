import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/agent_message.dart';
import '../../domain/repositories/agent_repository.dart';

const _uuid = Uuid();

class AgentProvider extends ChangeNotifier {
  final AgentRepository _repository;
  StreamSubscription? _eventSub;

  AgentProvider(this._repository) {
    _eventSub = _repository.events.listen(_handleEvent);
  }

  AgentState get state => _repository.currentState;

  String? _currentThreadId;
  String get currentThreadId =>
      _currentThreadId ?? 't-${_uuid.v4().substring(0, 8)}';

  final List<AgentMessage> _messages = [];
  List<AgentMessage> get messages => List.unmodifiable(_messages);

  List<ToolCall> _pendingToolCalls = [];
  List<ToolCall> get pendingToolCalls => List.unmodifiable(_pendingToolCalls);

  bool get isReady => state == AgentState.ready;
  bool get isThinking => state == AgentState.thinking;
  bool get isPendingApproval => state == AgentState.pendingApproval;

  void _handleEvent(AgentEvent event) {
    if (event is AgentStateEvent) {
      notifyListeners();
    } else if (event is AgentMessageEvent) {
      if (event.threadId != null) _currentThreadId = event.threadId;
      _upsertAgentMessage(event.content, event.status);
    } else if (event is AgentSystemEvent) {
      _addSystem(event.message, isError: event.isError);
    } else if (event is AgentToolCallEvent) {
      _currentThreadId = event.threadId;
      _pendingToolCalls = event.toolCalls;
      notifyListeners();
    }
  }

  Future<void> start() => _repository.start();

  Future<void> sendMessage(String text) async {
    if (!isReady) return;

    _currentThreadId ??= 't-${_uuid.v4().substring(0, 8)}';

    _messages.add(AgentMessage(
      id: _uuid.v4(),
      role: MessageRole.user,
      content: text,
      timestamp: DateTime.now(),
    ));
    notifyListeners();

    _upsertAgentMessage('', MessageStatus.thinking);
    _repository.sendMessage(text, currentThreadId);
  }

  Future<void> approve({bool approved = true, String feedback = ''}) async {
    if (!isPendingApproval) return;
    _repository.approve(
        threadId: currentThreadId, approved: approved, feedback: feedback);
  }

  void newSession() {
    _currentThreadId = 't-${_uuid.v4().substring(0, 8)}';
    _messages.clear();
    _pendingToolCalls = [];
    _addSystem('New session started');
    notifyListeners();
  }

  String? _thinkingMessageId;

  void _upsertAgentMessage(String content, MessageStatus status) {
    if (_thinkingMessageId != null) {
      final idx = _messages.indexWhere((m) => m.id == _thinkingMessageId);
      if (idx != -1) {
        if (status == MessageStatus.done && content.isEmpty) {
          _messages.removeAt(idx);
          _thinkingMessageId = null;
        } else {
          _messages[idx] =
              _messages[idx].copyWith(content: content, status: status);
          if (status == MessageStatus.done) _thinkingMessageId = null;
        }
        notifyListeners();
        return;
      }
    }

    if (content.isEmpty && status == MessageStatus.thinking) {
      final msg = AgentMessage(
        id: _uuid.v4(),
        role: MessageRole.agent,
        content: '',
        status: MessageStatus.thinking,
        timestamp: DateTime.now(),
      );
      _thinkingMessageId = msg.id;
      _messages.add(msg);
      notifyListeners();
      return;
    }

    if (content.isNotEmpty) {
      final msg = AgentMessage(
        id: _uuid.v4(),
        role: MessageRole.agent,
        content: content,
        status: status,
        timestamp: DateTime.now(),
      );
      if (status == MessageStatus.thinking) _thinkingMessageId = msg.id;
      _messages.add(msg);
      notifyListeners();
    }
  }

  void _addSystem(String content, {bool isError = false}) {
    _messages.add(AgentMessage(
      id: _uuid.v4(),
      role: MessageRole.system,
      content: content,
      status: isError ? MessageStatus.error : MessageStatus.done,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _repository.stop();
    super.dispose();
  }
}
