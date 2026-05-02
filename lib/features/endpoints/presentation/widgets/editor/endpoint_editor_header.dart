import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/themes/components/components.dart';

class EndpointEditorHeader extends StatelessWidget {
  final String method;
  final TextEditingController urlController;
  final ValueChanged<String?> onMethodChanged;
  final ValueChanged<String> onUrlChanged;
  final VoidCallback onExportCurl;
  final VoidCallback onSave;

  const EndpointEditorHeader({
    super.key,
    required this.method,
    required this.urlController,
    required this.onMethodChanged,
    required this.onUrlChanged,
    required this.onExportCurl,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.baseBackground,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 56, // Slightly taller for Fleet feel
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _MethodDropdown(
                  value: method,
                  onChanged: onMethodChanged,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _UrlField(
                    controller: urlController,
                    onChanged: onUrlChanged,
                  ),
                ),
                const SizedBox(width: 16),
                PilotButton.ghost(
                  icon: LucideIcons.code,
                  onPressed: onExportCurl,
                  compact: true,
                  tooltip: 'Export to cURL',
                ),
                const SizedBox(width: 8),
                PilotButton.ghost(
                  icon: LucideIcons.save,
                  onPressed: onSave,
                  compact: true,
                  tooltip: 'Save Endpoint',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const _MethodDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final accentColor = AppColors.accent;
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        dropdownColor: AppColors.elevatedSurface,
        icon: Icon(LucideIcons.chevronDown, size: 12, color: AppColors.textSecondary),
        items: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'].map((m) {
          final methodColor = {
            'GET': const Color(0xFF10B981),
            'POST': const Color(0xFF3B82F6),
            'PUT': const Color(0xFFF59E0B),
            'DELETE': const Color(0xFFEF4444),
            'PATCH': const Color(0xFF8B5CF6),
          }[m] ?? accentColor;
          return DropdownMenuItem(
            value: m,
            child: Text(m, style: TextStyle(color: methodColor, fontSize: 13, fontWeight: FontWeight.w700))
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _UrlField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  const _UrlField({required this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sidebarBackground,
        borderRadius: AppRadius.br4,
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTypography.code.copyWith(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'https://api.example.com/v1/resource',
          hintStyle: AppTypography.code.copyWith(color: AppColors.textDisabled, fontSize: 13),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }
}
