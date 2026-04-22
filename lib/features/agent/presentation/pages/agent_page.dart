import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/shared/presentation/widgets/fleet_page_bar.dart';
import 'package:xterm/xterm.dart';
import '../provider/agent_provider.dart';

class AgentPage extends StatefulWidget {
  const AgentPage({super.key});

  @override
  State<AgentPage> createState() => _AgentPageState();
}

class _AgentPageState extends State<AgentPage> {
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AgentProvider>();
      provider.ensureStarted().then((_) {
        _requestFocus();
      });
    });
  }

  void _requestFocus() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted && focusNode.canRequestFocus) {
        focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AgentProvider>();
    final bg = AppColors.background;
    final textColor = AppColors.textPrimary;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          const FleetPageBar(title: 'Agent'),
          Expanded(
            child: ClipRect(
                child: Stack(
                  children: [

                    Positioned.fill(
                      child: Container(
                        color: const Color(0xFF0D1117),
                        child: provider.isLoading && !provider.isInitialized
                            ? const Center(child: CircularProgressIndicator())
                            : TerminalView(
                                provider.terminal,
                                theme: TerminalThemes.defaultDark(),
                                padding: const EdgeInsets.all(16),
                                focusNode: focusNode,
                                hardwareKeyboardOnly: true,
                              ),
                      ),
                    ),

                    Positioned(
                      top: 12,
                      left: 12,
                      child: PilotButton.ghost(
                        icon: Icons.arrow_back_rounded,
                        onPressed: () => Navigator.of(context).pop(),
                        backgroundOverride: Colors.transparent,
                        foregroundOverride: textColor.withValues(alpha: 0.6),
                      ),
                    ),

                    Positioned(
                      top: 12,
                      right: 12,
                      child: PilotButton.ghost(
                        icon: Icons.refresh_rounded,
                        onPressed: () async {
                          await provider.restart();
                          _requestFocus();
                        },
                        backgroundOverride: Colors.transparent,
                        foregroundOverride: textColor.withValues(alpha: 0.6),
                      ),
                    ),

                    if (provider.error != null)
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.red.withValues(alpha: 0.8),
                          child: Text(
                            'Error: ${provider.error}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ),
        ],
      ),
    );
  }
}

class TerminalThemes {
  static TerminalTheme defaultDark() {
    return TerminalTheme(
      cursor: Colors.white,
      selection: Colors.white.withValues(alpha: 0.3),
      foreground: Colors.white,
      background: const Color(0xFF0D1117),
      black: const Color(0xFF000000),
      red: const Color(0xFFCD3131),
      green: const Color(0xFF0DBC79),
      yellow: const Color(0xFFE5E510),
      blue: const Color(0xFF2472C8),
      magenta: const Color(0xFFBC3FBC),
      cyan: const Color(0xFF11A8CD),
      white: const Color(0xFFE5E5E5),
      brightBlack: const Color(0xFF666666),
      brightRed: const Color(0xFFF14C4C),
      brightGreen: const Color(0xFF23D18B),
      brightYellow: const Color(0xFFF5F543),
      brightBlue: const Color(0xFF3B8EEA),
      brightMagenta: const Color(0xFFD670D6),
      brightCyan: const Color(0xFF29B8DB),
      brightWhite: const Color(0xFFE5E5E5),
      searchHitBackground: const Color(0xFFFFFF00),
      searchHitBackgroundCurrent: const Color(0xFFFF9632),
      searchHitForeground: const Color(0xFF000000),
    );
  }
}
