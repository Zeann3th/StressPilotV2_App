enum MessageRole { user, agent, system, tool }
enum MessageStatus { done, thinking, error }

class AgentMessage {
  final String id;
  final MessageRole role;
  final String content;
  final MessageStatus status;
  final DateTime timestamp;

  const AgentMessage({
    required this.id,
    required this.role,
    required this.content,
    this.status = MessageStatus.done,
    required this.timestamp,
  });

  AgentMessage copyWith({
    String? content,
    MessageStatus? status,
  }) {
    return AgentMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      status: status ?? this.status,
      timestamp: timestamp,
    );
  }
}

class ToolCall {
  final String id;
  final String name;
  final Map<String, dynamic> args;

  const ToolCall({
    required this.id,
    required this.name,
    required this.args,
  });

  factory ToolCall.fromJson(Map<String, dynamic> json) => ToolCall(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    args: Map<String, dynamic>.from(json['args'] ?? {}),
  );
}
