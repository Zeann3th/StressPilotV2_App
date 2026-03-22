import 'package:flutter/material.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/themes/components/components.dart';

class SettingsRow extends StatefulWidget {
  final String keyName;
  final String value;
  final Future<void> Function(String newValue) onSave;

  const SettingsRow({
    super.key,
    required this.keyName,
    required this.value,
    required this.onSave,
  });

  @override
  State<SettingsRow> createState() => _SettingsRowState();
}

class _SettingsRowState extends State<SettingsRow> {
  bool _isEditing = false;
  late TextEditingController _controller;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant SettingsRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_isEditing) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSubmission() async {
    final newValue = _controller.text.trim();

    if (newValue == widget.value) {
      setState(() => _isEditing = false);
      return;
    }

    final shouldSave = await PilotDialog.show<bool>(
      context: context,
      title: 'Change Setting?',
      content: Text(
        'This change will only be applied after the next app restart.',
        style: AppTypography.body.copyWith(color: AppColors.textSecondary),
      ),
      actions: [
        PilotButton.ghost(
          label: 'Cancel',
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
        ),
        PilotButton.primary(
          label: 'Confirm',
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
        ),
      ],
    );

    if (shouldSave == true) {
      await widget.onSave(newValue);
      if (mounted) setState(() => _isEditing = false);
    } else {
      _controller.text = widget.value;
      if (mounted) setState(() => _isEditing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppColors.textPrimary;

    final isBool = widget.value.toLowerCase() == 'true' || widget.value.toLowerCase() == 'false';
    final boolValue = widget.value.toLowerCase() == 'true';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: isBool ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!isBool && !_isEditing) setState(() => _isEditing = true);
        },
        child: AnimatedContainer(
          duration: AppDurations.micro,
          color: _isHovered && !_isEditing && !isBool
              ? (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02))
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.keyName.replaceAll('_', ' '),
                      style: AppTypography.body.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'System Configuration',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 5,
                child: isBool
                    ? Align(
                        alignment: Alignment.centerRight,
                        child: Switch(
                          value: boolValue,
                          activeThumbColor: AppColors.accent,
                          activeTrackColor: AppColors.accent.withValues(alpha: 0.2),
                          onChanged: (val) => widget.onSave(val.toString()),
                        ),
                      )
                    : _isEditing
                        ? Focus(
                            onFocusChange: (hasFocus) {
                              if (!hasFocus) _handleSubmission();
                            },
                            child: PilotInput(
                              controller: _controller,
                              autofocus: true,
                              onSubmitted: (_) => _handleSubmission(),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Flexible(
                                child: Text(
                                  widget.value.isEmpty ? 'Not set' : widget.value,
                                  style: AppTypography.codeSm.copyWith(
                                    color: widget.value.isEmpty
                                        ? AppColors.textMuted
                                        : AppColors.accent,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.edit_rounded,
                                size: 14,
                                color: _isHovered ? AppColors.textSecondary : Colors.transparent,
                              ),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
