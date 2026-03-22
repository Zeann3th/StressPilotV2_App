import 'package:flutter/material.dart';
import 'package:stress_pilot/features/agent/domain/models/agent_message.dart';
import 'package:stress_pilot/features/agent/presentation/widgets/agent_message_bubble.dart';

class AgentMessageList extends StatefulWidget {
  final List<AgentMessage> messages;

  const AgentMessageList({super.key, required this.messages});

  @override
  State<AgentMessageList> createState() => _AgentMessageListState();
}

class _AgentMessageListState extends State<AgentMessageList> {
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(AgentMessageList old) {
    super.didUpdateWidget(old);
    if (widget.messages.length != old.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: widget.messages.length,
      itemBuilder: (_, i) => AgentMessageBubble(message: widget.messages[i]),
    );
  }
}
