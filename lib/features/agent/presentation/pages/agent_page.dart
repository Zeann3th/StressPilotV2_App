import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/agent/presentation/provider/agent_provider.dart';
import 'package:stress_pilot/features/agent/presentation/widgets/agent_header.dart';
import 'package:stress_pilot/features/agent/presentation/widgets/agent_input_bar.dart';
import 'package:stress_pilot/features/agent/presentation/widgets/agent_message_list.dart';
import 'package:stress_pilot/features/agent/presentation/widgets/agent_tool_dialog.dart';
import 'package:stress_pilot/features/shared/presentation/widgets/app_topbar.dart';

class AgentPage extends StatefulWidget {
  const AgentPage({super.key});

  @override
  State<AgentPage> createState() => _AgentPageState();
}

class _AgentPageState extends State<AgentPage> {
  late final AgentProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = getIt<AgentProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.start();
      _provider.addListener(_onProviderUpdate);
    });
  }

  void _onProviderUpdate() {
    // Show tool approval dialog when needed
    if (_provider.isPendingApproval && _provider.pendingToolCalls.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          AgentToolDialog.show(
            context,
            toolCalls: _provider.pendingToolCalls,
            onResult: (approved, feedback) {
              _provider.approve(approved: approved, feedback: feedback);
            },
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: bg,
        body: Column(
          children: [
            const AppTopBar(),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: AppRadius.br16,
                  border: Border.all(color: border.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.br16,
                  child: Consumer<AgentProvider>(
                    builder: (context, provider, _) => Column(
                      children: [
                        AgentHeader(
                          state: provider.state,
                          onBack: () => Navigator.of(context).pop(),
                          onNewSession: provider.newSession,
                        ),
                        Expanded(
                          child: AgentMessageList(messages: provider.messages),
                        ),
                        AgentInputBar(
                          enabled: provider.isReady,
                          onSend: provider.sendMessage,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
