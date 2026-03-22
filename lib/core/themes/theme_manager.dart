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
  static const String _defaultThemeId = 'dark';

  final List<PilotTheme> _availableThemes = [];
  PilotTheme? _currentTheme;
  ShadThemeData? _currentShadTheme;

  List<PilotTheme> get availableThemes => List.unmodifiable(_availableThemes);
  PilotTheme get currentTheme => _currentTheme ?? _fallbackDark;
  ThemeMode get themeMode => currentTheme.isDark ? ThemeMode.dark : ThemeMode.light;
  bool get isDark => currentTheme.isDark;
  ShadThemeData? get currentShadTheme => _currentShadTheme;

  static const _fallbackDark = PilotTheme(
    id: 'dark',
    name: 'Dark Forest (Default)',
    brightness: Brightness.dark,
    colors: {
      'background': AppColors.darkBackground,
      'surface': AppColors.darkSurface,
      'elevated': AppColors.darkElevated,
      'border': AppColors.darkBorder,
      'textPrimary': Color(0xFFF0F6FC),
      'textSecondary': Color(0xFF8B949E),
      'accent': AppColors.darkGreenStart,
      'success': AppColors.success,
      'error': AppColors.error,
    },
  );

  static const _fallbackLight = PilotTheme(
    id: 'light',
    name: 'Light (Default)',
    brightness: Brightness.light,
    colors: {
      'background': AppColors.lightBackground,
      'surface': AppColors.lightSurface,
      'elevated': AppColors.lightElevated,
      'border': AppColors.lightBorder,
      'textPrimary': Color(0xFF111827),
      'textSecondary': Color(0xFF4B5563),
      'accent': AppColors.lightGreenStart,
      'success': AppColors.success,
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
    _availableThemes.add(_fallbackDark);
    _availableThemes.add(_fallbackLight);

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
      orElse: () => _fallbackDark,
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

    final background = theme.getColor('background', isDark ? AppColors.darkBackground : AppColors.lightBackground);
    final foreground = theme.getColor('textPrimary', isDark ? const Color(0xFFF0F6FC) : const Color(0xFF111827));
    final card = theme.getColor('surface', isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final border = theme.getColor('border', isDark ? AppColors.darkBorder : AppColors.lightBorder);
    final primary = theme.getColor('accent', isDark ? AppColors.darkGreenStart : AppColors.lightGreenStart);
    final elevated = theme.getColor('elevated', isDark ? AppColors.darkElevated : AppColors.lightElevated);
    final textSecondary = theme.getColor('textSecondary', isDark ? const Color(0xFF8B949E) : const Color(0xFF4B5563));

    final colorScheme = isDark
        ? ShadZincColorScheme.dark(
      background: background,
      foreground: foreground,
      card: card,
      cardForeground: foreground,
      popover: card,
      popoverForeground: foreground,
      primary: primary,
      primaryForeground: Colors.white,
      secondary: elevated,
      secondaryForeground: foreground,
      muted: elevated,
      mutedForeground: textSecondary,
      accent: elevated,
      accentForeground: foreground,
      destructive: theme.getColor('error', AppColors.error),
      destructiveForeground: Colors.white,
      border: border,
      input: border,
      ring: primary,
    )
        : ShadZincColorScheme.light(
      background: background,
      foreground: foreground,
      card: card,
      cardForeground: foreground,
      popover: card,
      popoverForeground: foreground,
      primary: primary,
      primaryForeground: Colors.white,
      secondary: elevated,
      secondaryForeground: foreground,
      muted: elevated,
      mutedForeground: textSecondary,
      accent: elevated,
      accentForeground: foreground,
      destructive: theme.getColor('error', AppColors.error),
      destructiveForeground: Colors.white,
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
    final nextThemeId = isDark ? 'light' : 'dark';
    await setTheme(nextThemeId);
  }
}
