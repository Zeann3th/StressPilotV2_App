import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/system/logger.dart';
import 'package:stress_pilot/core/system/process_manager.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/common/presentation/widgets/app_topbar.dart';
import 'package:xterm/xterm.dart';

class AgentPage extends StatefulWidget {
  const AgentPage({super.key});

  @override
  State<AgentPage> createState() => _AgentPageState();
}

class _AgentPageState extends State<AgentPage> with RouteAware {
  final terminal = Terminal(maxLines: 10000);
  final terminalController = TerminalController();

  Pty? pty;
  bool _isStarting = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && !_initialized) {
          _initialized = true;
          _initPty();
        }
      });
    });
  }

  void _initPty() {
    if (!mounted) return;
    setState(() => _isStarting = true);

    final pm = getIt<ProcessManager>();
    final executable = pm.resolveAgentPath();

    // ✅ Check if file actually exists first
    final file = File(executable);
    if (!file.existsSync()) {
      AppLogger.critical('Agent exe not found at: $executable', name: 'AgentPage');
      terminal.write('\x1b[1;31m[Error] Agent not found at:\x1b[0m\r\n$executable\r\n');
      if (mounted) setState(() => _isStarting = false);
      return;
    }

    AppLogger.info('Agent exe found at: $executable', name: 'AgentPage');

    try {
      pty = Pty.start(
        executable,
        columns: terminal.viewWidth,
        rows: terminal.viewHeight,
        environment: {
          'TERM': 'xterm-256color',
          'COLORTERM': 'truecolor',
          'FORCE_COLOR': '3',
        },
      );

      pty!.output.listen((data) {
        terminal.write(String.fromCharCodes(data));
      });

      pty!.exitCode.then((code) {
        AppLogger.warning('PTY exited: $code', name: 'AgentPage');
        if (mounted) {
          terminal.write('\r\n\x1b[1;31m[System] Process exited (code: $code)\x1b[0m\r\n');
        }
      });

      terminal.onOutput = (data) {
        pty?.write(const Utf8Encoder().convert(data));
      };

      terminal.onResize = (w, h, pw, ph) {
        pty?.resize(h, w);
      };

      if (mounted) setState(() => _isStarting = false);
    } catch (e, st) {
      AppLogger.critical('Failed to start PTY', name: 'AgentPage', error: e, stackTrace: st);
      if (mounted) {
        terminal.write('\x1b[1;31m[Error] $e\x1b[0m\r\n');
        setState(() => _isStarting = false);
      }
    }
  }

  void _restart() {
    pty?.kill();
    pty = null;
    _initialized = false;
    terminal.write('\r\n\x1b[1;33m[System] Restarting...\x1b[0m\r\n');
    _initialized = true;
    _initPty();
  }

  @override
  void dispose() {
    pty?.kill();
    pty = null;
    terminalController.dispose();
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

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: border.withValues(alpha: 0.3)),
                        ),
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
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.darkGreenStart,
                              ),
                            )
                          else
                            InkWell(
                              onTap: _restart,
                              borderRadius: AppRadius.br4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.darkGreenStart.withValues(alpha: 0.1),
                                  borderRadius: AppRadius.br4,
                                  border: Border.all(
                                    color: AppColors.darkGreenStart.withValues(alpha: 0.2),
                                  ),
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

                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1117),
                          borderRadius: AppRadius.br12,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: ClipRRect(
                          borderRadius: AppRadius.br12,
                          child: Stack(
                            children: [

                              TerminalView(
                                terminal,
                                controller: terminalController,
                                autofocus: true,
                                hardwareKeyboardOnly: true,
                                backgroundOpacity: 0,
                                padding: const EdgeInsets.all(16),
                                textStyle: const TerminalStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 13,
                                ),
                              ),

                              if (_isStarting)
                                const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.darkGreenStart,
                                  ),
                                ),
                            ],
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
