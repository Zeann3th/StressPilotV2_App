import 'package:flutter/material.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';

class BottomPanelShell extends StatefulWidget {
  final Widget body;
  final Widget panel;
  final bool isOpen;
  final double minPanelHeight;
  final double maxPanelHeight;
  final double initialPanelHeight;

  const BottomPanelShell({
    super.key,
    required this.body,
    required this.panel,
    required this.isOpen,
    this.minPanelHeight = 120,
    this.maxPanelHeight = 600,
    this.initialPanelHeight = 280,
  });

  @override
  State<BottomPanelShell> createState() => _BottomPanelShellState();
}

class _BottomPanelShellState extends State<BottomPanelShell> {
  late final ValueNotifier<double> _panelHeight;

  @override
  void initState() {
    super.initState();
    _panelHeight = ValueNotifier(widget.initialPanelHeight);
  }

  @override
  void dispose() {
    _panelHeight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: widget.body),
        if (widget.isOpen) ...[
          ValueListenableBuilder<double>(
            valueListenable: _panelHeight,
            builder: (context, height, child) {
              return Column(
                children: [
                  // Drag handle
                  MouseRegion(
                    cursor: SystemMouseCursors.resizeRow,
                    child: GestureDetector(
                      onVerticalDragUpdate: (details) {
                        _panelHeight.value = (_panelHeight.value - details.delta.dy)
                            .clamp(widget.minPanelHeight, widget.maxPanelHeight);
                      },
                      child: Container(
                        height: 4,
                        color: Colors.transparent,
                        child: Center(
                          child: Container(height: 1, color: AppColors.divider),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: height,
                    child: widget.panel,
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}
