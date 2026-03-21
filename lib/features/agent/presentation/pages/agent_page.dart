import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/system/process_manager.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';

class AgentPage extends StatefulWidget {
  const AgentPage({super.key});

  @override
  State<AgentPage> createState() => _AgentPageState();
}

class _AgentPageState extends State<AgentPage> {
  final ScrollController _scrollController = ScrollController();
  final List<String> _logs = [];
  bool _isStarting = true;

  @override
  void initState() {
    super.initState();
    _startAgent();
  }

  Future<void> _startAgent() async {
    final pm = getIt<ProcessManager>();
    try {
      await pm.startAgent(pipeMode: true);
      final agent = pm.getProcess('agent');
      if (agent != null) {
        agent.output.listen((data) {
          if (mounted) {
            setState(() {
              _logs.add(data);
              _isStarting = false;
            });
            _scrollToBottom();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _logs.add('Error starting agent: $e');
          _isStarting = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    getIt<ProcessManager>().stopProcess('agent');
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // Header
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: surface,
              border: Border(bottom: BorderSide(color: border)),
            ),
            child: Row(
              children: [
                PilotButton.ghost(
                  onPressed: () => Navigator.pop(context),
                  icon: LucideIcons.chevronLeft,
                  label: 'Back',
                ),
                const SizedBox(width: 16),
                const Icon(LucideIcons.sparkles, size: 20, color: AppColors.darkGreenStart),
                const SizedBox(width: 12),
                Text(
                  'StressPilot AI Agent',
                  style: ShadTheme.of(context).textTheme.h4,
                ),
                const Spacer(),
                if (_isStarting)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.darkGreenStart),
                  ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black, // Always black for terminal feel
                borderRadius: AppRadius.br12,
                border: Border.all(color: border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: AppRadius.br12,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return _buildLogLine(log);
                  },
                ),
              ),
            ),
          ),
          
          // Input placeholder (since it's JSON mode/watch for now)
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Agent is running in sync mode. Interaction is managed by the StressPilot core.',
              style: ShadTheme.of(context).textTheme.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogLine(String line) {
    // Try to detect JSON for pretty printing
    bool _ = line.trim().startsWith('{') || line.trim().startsWith('[');
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        line,
        style: const TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 13,
          color: Color(0xFFE2E8F0),
        ),
      ),
    );
  }
}
