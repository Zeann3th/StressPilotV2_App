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
          backgroundColor: colors.surface,
          surfaceTintColor: colors.surfaceTint,
          title: const Text('Change Setting?'),
          content: const Text(
            'This change will only be applied after the next app restart.',
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
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (!_isEditing) setState(() => _isEditing = true);
        },
        child: Container(
          color: _isHovered
              ? colors.primary.withOpacity(0.05)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  widget.keyName.replaceAll('_', ' '),
                  style: text.bodyMedium?.copyWith(
                    color: colors.onSurface,
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
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          onSubmitted: (_) => _handleSubmission(),
                          style: text.bodyMedium?.copyWith(
                            color: colors.onSurface,
                            fontFamily: 'JetBrains Mono',
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: colors.surfaceContainerHighest
                                .withOpacity(0.5),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              widget.value.isEmpty ? 'Not Set' : widget.value,
                              style: text.bodyMedium?.copyWith(
                                color: widget.value.isEmpty
                                    ? colors.onSurfaceVariant.withOpacity(0.7)
                                    : colors.onSurfaceVariant,
                                fontFamily: 'JetBrains Mono',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                          if (_isHovered) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: colors.onSurfaceVariant.withOpacity(0.5),
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
