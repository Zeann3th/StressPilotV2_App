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
  late double _panelHeight;

  @override
  void initState() {
    super.initState();
    _panelHeight = widget.initialPanelHeight;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: widget.body),
        if (widget.isOpen) ...[
          // Drag handle
          MouseRegion(
            cursor: SystemMouseCursors.resizeRow,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  _panelHeight = (_panelHeight - details.delta.dy)
                      .clamp(widget.minPanelHeight, widget.maxPanelHeight);
                });
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
            height: _panelHeight,
            child: widget.panel,
          ),
        ],
      ],
    );
  }
}
