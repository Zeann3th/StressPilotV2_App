import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:path/path.dart' as p;
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/system/settings_manager.dart';
import 'package:stress_pilot/core/system/logger.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/themes/pilot_theme.dart';

class ThemeManager with ChangeNotifier {
  static const String _defaultThemeId = 'fleet';

  final List<PilotTheme> _availableThemes = [];
  PilotTheme? _currentTheme;
  ShadThemeData? _currentShadTheme;

  List<PilotTheme> get availableThemes => List.unmodifiable(_availableThemes);
  PilotTheme get currentTheme => _currentTheme ?? _fleetTheme;
  ThemeMode get themeMode => currentTheme.isDark ? ThemeMode.dark : ThemeMode.light;
  bool get isDark => currentTheme.isDark;
  ShadThemeData? get currentShadTheme => _currentShadTheme;

  static const _fleetTheme = PilotTheme(
    id: 'fleet',
    name: 'JetBrains Fleet',
    brightness: Brightness.dark,
    colors: {
      'background': AppColors.baseBackground,
      'surface': AppColors.sidebarBackground,
      'elevated': AppColors.elevatedSurface,
      'border': AppColors.border,
      'textPrimary': AppColors.textPrimary,
      'textSecondary': AppColors.textSecondary,
      'accent': AppColors.accent,
      'success': AppColors.methodGet,
      'error': AppColors.error,
    },
  );

  Future<void> initialize() async {
    final settingsManager = getIt<SettingsManager>();
    if (!settingsManager.isInitialized) {
      await settingsManager.initialize();
    }

    await loadAvailableThemes();

    final themeId = settingsManager.getString('workbench.colorTheme', defaultValue: _defaultThemeId);
    await setTheme(themeId);

    settingsManager.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    final newThemeId = getIt<SettingsManager>().getString('workbench.colorTheme', defaultValue: _defaultThemeId);
    if (newThemeId != currentTheme.id) {
      setTheme(newThemeId);
    }
  }

  Future<void> loadAvailableThemes() async {
    _availableThemes.clear();
    _availableThemes.add(_fleetTheme);

    try {
      final String home = Platform.environment['HOME'] ??
                          Platform.environment['USERPROFILE'] ??
                          '/';
      final themesDir = Directory(p.join(home, '.pilot', 'client', 'themes'));

      if (await themesDir.exists()) {
        final files = themesDir.listSync().where((e) => e is File && e.path.endsWith('.json'));
        for (var entity in files) {
          try {
            final file = entity as File;
            final content = await file.readAsString();
            final json = jsonDecode(content);
            final id = p.basenameWithoutExtension(file.path);
            _availableThemes.add(PilotTheme.fromJson(id, json));
          } catch (e) {
            AppLogger.warning('Failed to parse theme file ${entity.path}: $e');
          }
        }
      }
    } catch (e) {
      AppLogger.warning('Failed to load external themes: $e');
    }
    notifyListeners();
  }

  Future<void> setTheme(String themeId) async {
    final theme = _availableThemes.firstWhere(
      (t) => t.id == themeId,
      orElse: () => _fleetTheme,
    );

    _currentTheme = theme;
    _currentShadTheme = _generateShadTheme(theme);

    final settingsManager = getIt<SettingsManager>();
    if (settingsManager.getString('workbench.colorTheme') != themeId) {
      await settingsManager.setString('workbench.colorTheme', themeId);
    }

    notifyListeners();
  }

  ShadThemeData _generateShadTheme(PilotTheme theme) {
    final isDark = theme.isDark;

    final background = theme.getColor('background', AppColors.baseBackground);
    final foreground = theme.getColor('textPrimary', AppColors.textPrimary);
    final card = theme.getColor('surface', AppColors.sidebarBackground);
    final border = theme.getColor('border', AppColors.border);
    final primary = theme.getColor('accent', AppColors.accent);
    final elevated = theme.getColor('elevated', AppColors.elevatedSurface);
    final textSecondary = theme.getColor('textSecondary', AppColors.textSecondary);

    final colorScheme = isDark
        ? ShadZincColorScheme.dark(
      background: background,
      foreground: foreground,
      card: card,
      cardForeground: foreground,
      popover: elevated,
      popoverForeground: foreground,
      primary: primary,
      primaryForeground: foreground,
      secondary: elevated,
      secondaryForeground: foreground,
      muted: elevated,
      mutedForeground: textSecondary,
      accent: AppColors.activeItem,
      accentForeground: foreground,
      destructive: theme.getColor('error', AppColors.error),
      destructiveForeground: foreground,
      border: border,
      input: border,
      ring: primary,
    )
        : ShadZincColorScheme.light(
      background: background,
      foreground: foreground,
      card: card,
      cardForeground: foreground,
      popover: elevated,
      popoverForeground: foreground,
      primary: primary,
      primaryForeground: foreground,
      secondary: elevated,
      secondaryForeground: foreground,
      muted: elevated,
      mutedForeground: textSecondary,
      accent: AppColors.activeItem,
      accentForeground: foreground,
      destructive: theme.getColor('error', AppColors.error),
      destructiveForeground: foreground,
      border: border,
      input: border,
      ring: primary,
    );

    return ShadThemeData(
      brightness: theme.brightness,
      colorScheme: colorScheme,
    );
  }

  Future<void> toggleTheme() async {
    // Fleet doesn't have a light mode in this spec
  }
}

