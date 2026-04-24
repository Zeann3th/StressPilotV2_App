// lib/core/themes/pilot_colors.dart
import 'package:flutter/material.dart';

class PilotColors {
  final Color background;
  final Color surface;
  final Color elevated;
  final Color activeItem;
  final Color hoverItem;
  final Color accent;
  final Color accentHover;
  final Color accentActive;
  final Color border;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color error;
  final Color methodGet;
  final Color methodPost;
  final Color methodPut;
  final Color methodDelete;
  final Color methodPatch;

  const PilotColors({
    required this.background,
    required this.surface,
    required this.elevated,
    required this.activeItem,
    required this.hoverItem,
    required this.accent,
    required this.accentHover,
    required this.accentActive,
    required this.border,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.error,
    required this.methodGet,
    required this.methodPost,
    required this.methodPut,
    required this.methodDelete,
    required this.methodPatch,
  });

  // Convenience aliases
  Color get textMuted => textDisabled;
  Color get success => methodGet;
  Color get warning => methodPut;
  Color get info => methodPost;
}
