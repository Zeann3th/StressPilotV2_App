import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
import 'package:stress_pilot/features/endpoints/presentation/widgets/json_viewer.dart';

class EndpointEditorResponsePanel extends StatelessWidget {
  final Map<String, dynamic>? response;
  final bool showRaw;
  final bool isExecuting;
  final int elapsedMs;
  final int? statusCode;
  final int? responseTime;
  final bool? isSuccess;
  final VoidCallback onToggleRaw;
  final VoidCallback onClose;
  final double height;
  final ValueChanged<double> onHeightChanged;
  final bool showSearch;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final int currentSearchMatchIndex;
  final int totalMatchesCount;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchNext;
  final VoidCallback onSearchPrev;
  final VoidCallback onCloseSearch;

  const EndpointEditorResponsePanel({
    super.key,
    required this.response,
    required this.showRaw,
    required this.isExecuting,
    required this.elapsedMs,
    required this.statusCode,
    required this.responseTime,
    required this.isSuccess,
    required this.onToggleRaw,
    required this.onClose,
    required this.height,
    required this.onHeightChanged,
    required this.showSearch,
    required this.searchController,
    required this.searchFocusNode,
    required this.currentSearchMatchIndex,
    required this.totalMatchesCount,
    required this.onSearchChanged,
    required this.onSearchNext,
    required this.onSearchPrev,
    required this.onCloseSearch,
  });

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.baseBackground;
    final surface = AppColors.sidebarBackground;
    final border = AppColors.divider;
    final secondaryText = AppColors.textSecondary;
    final textColor = AppColors.textPrimary;

    return Column(
      children: [
        // Resize Handle
        MouseRegion(
          cursor: SystemMouseCursors.resizeRow,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: (d) => onHeightChanged(height - d.delta.dy),
            child: Container(
              height: 8,
              color: border.withValues(alpha: 0.1),
              alignment: Alignment.center,
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: border.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),

        SizedBox(
          height: height,
          child: Container(
            color: bg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Toolbar
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: surface,
                    border: Border(bottom: BorderSide(color: border.withValues(alpha: 0.1))),
                  ),
                  child: Row(
                    children: [
                      EditorTabButton(label: 'Response', active: !showRaw, onTap: onToggleRaw),
                      const SizedBox(width: 4),
                      EditorTabButton(label: 'Raw', active: showRaw, onTap: onToggleRaw),
                      const Spacer(),
                      if (isExecuting)
                        Text('$elapsedMs ms', style: AppTypography.codeSm.copyWith(color: secondaryText))
                      else if (statusCode != null) ...[
                        _StatusBadge(success: isSuccess ?? (statusCode! < 400), code: statusCode!),
                        const SizedBox(width: 10),
                        Text('$responseTime ms', style: AppTypography.codeSm.copyWith(color: secondaryText)),
                      ],
                      const SizedBox(width: 8),
                      EditorIconButton(
                        icon: LucideIcons.minus,
                        onTap: onClose,
                      ),
                    ],
                  ),
                ),

                if (showSearch)
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: surface,
                      border: Border(bottom: BorderSide(color: border.withValues(alpha: 0.1))),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.search, size: 14, color: secondaryText),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            focusNode: searchFocusNode,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'Find in response...',
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            style: TextStyle(fontSize: 13, color: textColor),
                            onChanged: onSearchChanged,
                            onSubmitted: (_) => onSearchNext(),
                          ),
                        ),
                        if (totalMatchesCount > 0) ...[
                          Text(
                            '${currentSearchMatchIndex + 1} / $totalMatchesCount',
                            style: TextStyle(fontSize: 11, color: secondaryText, fontFamily: 'JetBrains Mono'),
                          ),
                          const SizedBox(width: 8),
                          PilotButton.ghost(
                            icon: LucideIcons.chevronUp,
                            compact: true,
                            onPressed: onSearchPrev,
                          ),
                          PilotButton.ghost(
                            icon: LucideIcons.chevronDown,
                            compact: true,
                            onPressed: onSearchNext,
                          ),
                          const VerticalDivider(width: 16, indent: 8, endIndent: 8),
                        ],
                        EditorIconButton(
                          icon: LucideIcons.x,
                          compact: true,
                          onTap: onCloseSearch,
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  child: response == null
                      ? _EmptyState(secondaryText: secondaryText)
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: showRaw
                              ? SelectableText(
                                  _getRawResponse(response!),
                                  style: AppTypography.code.copyWith(fontSize: 12),
                                )
                              : JsonViewer(
                                  json: _getResponseData(response!),
                                  searchQuery: searchController.text,
                                  activeMatchIndex: currentSearchMatchIndex,
                                  onMatchesCountChanged: (_) {}, // Handled by parent if needed
                                ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getResponseData(Map<String, dynamic> r) {
    if (r.containsKey('error')) return {'error': r['error']};

    final outerData = r['data'];
    if (outerData is Map<String, dynamic>) {
      final innerData = outerData['data'];

      // If innerData is a Map, that's what we want (data.data)
      if (innerData is Map<String, dynamic>) return innerData;

      // Fallback: return outerData without metadata
      final cleaned = Map<String, dynamic>.from(outerData);
      cleaned.removeWhere((k, _) => const {
            'statusCode',
            'success',
            'responseTimeMs',
            'message',
            'rawResponse'
          }.contains(k));
      return cleaned;
    }
    return r;
  }

  String _getRawResponse(Map<String, dynamic> r) {
    try {
      return const JsonEncoder.withIndent('  ').convert(r);
    } catch (_) {
      return r.toString();
    }
  }
}

class EditorTabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const EditorTabButton({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? AppColors.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: active ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool success;
  final int code;

  const _StatusBadge({required this.success, required this.code});

  @override
  Widget build(BuildContext context) {
    final color = success ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        success ? 'SUCCESS ($code)' : 'FAILED ($code)',
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 0.5),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Color secondaryText;
  const _EmptyState({required this.secondaryText});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.send, size: 32, color: secondaryText.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text('Run endpoint to see results', style: TextStyle(color: secondaryText, fontSize: 13)),
        ],
      ),
    );
  }
}

class EditorIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool compact;

  const EditorIconButton({super.key, required this.icon, required this.onTap, this.compact = false});

  @override
  State<EditorIconButton> createState() => _EditorIconButtonState();
}

class _EditorIconButtonState extends State<EditorIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: EdgeInsets.all(widget.compact ? 4 : 6),
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.hoverItem : Colors.transparent,
            borderRadius: AppRadius.br4,
          ),
          child: Icon(
            widget.icon,
            size: 14,
            color: _isHovered ? AppColors.accent : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
