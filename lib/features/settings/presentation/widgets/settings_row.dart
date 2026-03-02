import 'package:flutter/material.dart';
import 'package:stress_pilot/core/design/tokens.dart';
import 'package:stress_pilot/core/design/components.dart';

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
    final textColor = isDark ? AppColors.textPrimary : AppColors.textLight;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (!_isEditing) setState(() => _isEditing = true);
        },
        child: AnimatedContainer(
          duration: AppDurations.micro,
          color: _isHovered && !_isEditing
              ? AppColors.accent.withValues(alpha: 0.04)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  widget.keyName.replaceAll('_', ' '),
                  style: AppTypography.body.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 6,
                child: _isEditing
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
                              style: AppTypography.body.copyWith(
                                color: widget.value.isEmpty
                                    ? AppColors.textMuted
                                    : AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                          if (_isHovered) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 14,
                              color: AppColors.textMuted,
                            ),
                          ],
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
