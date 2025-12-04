import 'package:flutter/material.dart';

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

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text('Change Setting?'),
          content: const Text(
            'This change will only be applied after the next app restart.\n\nDo you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (shouldSave == true) {
      await widget.onSave(newValue);
      if (mounted) {
        setState(() => _isEditing = false);
      }
    } else {
      _controller.text = widget.value;
      if (mounted) {
        setState(() => _isEditing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        color: _isHovered && !_isEditing
            ? colors.onSurface.withAlpha(10)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // KEY
            Expanded(
              flex: 4,
              child: SelectableText(
                widget.keyName,
                style: text.bodyMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 24),

            // VALUE (Editable)
            Expanded(
              flex: 6,
              child: _isEditing
                  ? Focus(
                      onFocusChange: (hasFocus) {
                        if (!hasFocus) _handleSubmission();
                      },
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        onSubmitted: (_) => _handleSubmission(),
                        style: text.bodySmall?.copyWith(
                          color: colors.onSurface,
                          fontFamily: 'monospace',
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(color: colors.onSurface),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(
                              color: colors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    )
                  : InkWell(
                      onTap: () => setState(() => _isEditing = true),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: widget.value.isEmpty
                              ? Border.all(color: colors.error.withAlpha(100))
                              : null,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.value.isEmpty ? 'Empty' : widget.value,
                          style: text.bodySmall?.copyWith(
                            color: widget.value.isEmpty
                                ? colors.error.withAlpha(150)
                                : colors.onSurface.withAlpha(200),
                            fontFamily: 'monospace',
                            fontStyle: widget.value.isEmpty
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
            ),

            SizedBox(
              width: 24,
              child: _isHovered && !_isEditing
                  ? Icon(
                      Icons.edit_outlined,
                      size: 14,
                      color: colors.onSurface.withAlpha(100),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
