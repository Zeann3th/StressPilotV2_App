import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/system/process_manager.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/features/common/presentation/widgets/app_topbar.dart';
import 'dart:async';
import 'dart:convert';
import 'package:xterm/xterm.dart';

class AgentPage extends StatefulWidget {
  const AgentPage({super.key});

  @override
  State<AgentPage> createState() => _AgentPageState();
}

class _AgentPageState extends State<AgentPage> {
  final Terminal _terminal = Terminal(
    maxLines: 10000,
  );
  final TerminalController _terminalController = TerminalController();
  
  bool _isStarting = true;
  PilotProcess? _agentProcess;
  StreamSubscription? _outputSubscription;

  @override
  void initState() {
    super.initState();
    _startAgent();
    
    _terminal.onOutput = (data) {
      _agentProcess?.writeRawStdin(utf8.encode(data));
    };
  }

  Future<void> _startAgent() async {
    setState(() {
      _isStarting = true;
      _terminal.write('\x1b[1;32m[System] Starting agent...\x1b[0m\r\n');
    });

    final pm = getIt<ProcessManager>();
    try {
      await pm.startAgent(pipeMode: false);
      _agentProcess = pm.getProcess('agent');
      
      await _outputSubscription?.cancel();
      if (_agentProcess != null) {
        _outputSubscription = _agentProcess!.rawOutput.listen((data) {
          if (mounted) {
            setState(() {
              _terminal.write(utf8.decode(data, allowMalformed: true));
              _isStarting = false;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _terminal.write('\x1b[1;31m[Error] Failed to start agent: $e\x1b[0m\r\n');
          _isStarting = false;
        });
      }
    }
  }

  Future<void> _restartAgent() async {
    final pm = getIt<ProcessManager>();
    await pm.stopAgent();
    setState(() {
      _terminal.write('\r\n\x1b[1;33m[System] Restarting agent...\x1b[0m\r\n');
      _agentProcess = null;
    });
    await _startAgent();
  }

  @override
  void dispose() {
    _outputSubscription?.cancel();
    _terminalController.dispose();
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
                child: Column(
                  children: [
                    // Agent Toolbar/Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: border.withValues(alpha: 0.3))),
                      ),
                      child: Row(
                        children: [
                          PilotButton.ghost(
                            icon: LucideIcons.chevronLeft,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 8),
                          const Icon(LucideIcons.sparkles, size: 18, color: AppColors.darkGreenStart),
                          const SizedBox(width: 12),
                          Text(
                            'StressPilot AI Agent',
                            style: AppTypography.heading.copyWith(fontSize: 16),
                          ),
                          const Spacer(),
                          if (_isStarting)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.darkGreenStart),
                            )
                          else
                            InkWell(
                              onTap: _restartAgent,
                              borderRadius: AppRadius.br4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.darkGreenStart.withValues(alpha: 0.1),
                                  borderRadius: AppRadius.br4,
                                  border: Border.all(color: AppColors.darkGreenStart.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'ACTIVE',
                                      style: TextStyle(
                                        color: AppColors.darkGreenStart,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(LucideIcons.refreshCcw, size: 10, color: AppColors.darkGreenStart),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Terminal Content
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1117), // GitHub dark theme background
                          borderRadius: AppRadius.br12,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: ClipRRect(
                          borderRadius: AppRadius.br12,
                          child: TerminalView(
                            _terminal,
                            controller: _terminalController,
                            autofocus: true,
                            backgroundOpacity: 0,
                            padding: const EdgeInsets.all(16),
                            textStyle: const TerminalStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
