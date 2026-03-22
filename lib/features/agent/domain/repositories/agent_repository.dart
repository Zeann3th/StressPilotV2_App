import '../models/agent_message.dart';

enum AgentState { idle, starting, ready, thinking, pendingApproval, error }

abstract class AgentRepository {
  Stream<AgentEvent> get events;
  AgentState get currentState;

  Future<void> start();
  void sendMessage(String text, String threadId);
  void approve({required String threadId, bool approved = true, String feedback = ''});
  void stop();
}

abstract class AgentEvent {}

class AgentStateEvent extends AgentEvent {
  final AgentState state;
  AgentStateEvent(this.state);
}

class AgentMessageEvent extends AgentEvent {
  final String content;
  final MessageStatus status;
  final String? threadId;
  AgentMessageEvent({required this.content, required this.status, this.threadId});
}

class AgentSystemEvent extends AgentEvent {
  final String message;
  final bool isError;
  AgentSystemEvent(this.message, {this.isError = false});
}

class AgentToolCallEvent extends AgentEvent {
  final List<ToolCall> toolCalls;
  final String threadId;
  AgentToolCallEvent(this.toolCalls, this.threadId);
}
