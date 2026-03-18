import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:path/path.dart' as p;
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/config/settings_manager.dart';
import 'package:stress_pilot/core/system/logger.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';

class ThemeManager with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ShadThemeData? _currentShadTheme;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;
  ShadThemeData? get currentShadTheme => _currentShadTheme;

  Future<void> initialize() async {
    final settingsManager = getIt<SettingsManager>();
    if (!settingsManager.isInitialized) {
      await settingsManager.initialize();
    }

    final themeName = settingsManager.getString('workbench.colorTheme', defaultValue: 'dark');
    _themeMode = themeName.toLowerCase() == 'light' ? ThemeMode.light : ThemeMode.dark;

    await _loadCustomTheme(themeName);

    settingsManager.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    final newTheme = getIt<SettingsManager>().getString('workbench.colorTheme', defaultValue: 'dark');
    final newMode = newTheme.toLowerCase() == 'light' ? ThemeMode.light : ThemeMode.dark;

    if (newMode != _themeMode) {
      _themeMode = newMode;
      _loadCustomTheme(newTheme).then((_) => notifyListeners());
    }
  }

  Future<void> _loadCustomTheme(String themeName) async {
    try {
      final String home = Platform.environment['HOME'] ??
                          Platform.environment['USERPROFILE'] ??
                          '/';
      final file = File(p.join(home, '.pilot', 'client', 'themes', '$themeName.json'));

      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content);
        _currentShadTheme = _parseShadTheme(json);
      } else {
        _currentShadTheme = null;
      }
    } catch (e) {
      AppLogger.warning('Failed to load custom theme: $e');
      _currentShadTheme = null;
    }
  }

  ShadThemeData? _parseShadTheme(Map<String, dynamic> json) {
    try {
      final colors = json['colors'] as Map<String, dynamic>? ?? {};

      Color parseColor(String hexKey, Color fallback) {
        if (!colors.containsKey(hexKey)) return fallback;
        final hex = (colors[hexKey] as String).replaceAll('#', '');
        if (hex.length == 6) {
          return Color(int.parse('FF$hex', radix: 16));
        }
        if (hex.length == 8) {
          return Color(int.parse(hex, radix: 16));
        }
        return fallback;
      }

      final colorScheme = _themeMode == ThemeMode.dark
          ? const ShadZincColorScheme.dark(
              background: AppColors.darkBackground,
              foreground: AppColors.textPrimary,
              card: AppColors.darkSurface,
              cardForeground: AppColors.textPrimary,
              popover: AppColors.darkSurface,
              popoverForeground: AppColors.textPrimary,
              primary: AppColors.darkGreenStart,
              primaryForeground: Colors.white,
              secondary: AppColors.darkElevated,
              secondaryForeground: AppColors.textPrimary,
              muted: AppColors.darkElevated,
              mutedForeground: AppColors.textSecondary,
              accent: AppColors.darkElevated,
              accentForeground: AppColors.textPrimary,
              destructive: AppColors.error,
              destructiveForeground: Colors.white,
              border: AppColors.darkBorder,
              input: AppColors.darkBorder,
              ring: AppColors.darkGreenStart,
            )
          : const ShadZincColorScheme.light(
              background: AppColors.lightBackground,
              foreground: AppColors.textLight,
              card: AppColors.lightSurface,
              cardForeground: AppColors.textLight,
              popover: AppColors.lightSurface,
              popoverForeground: AppColors.textLight,
              primary: AppColors.lightGreenStart,
              primaryForeground: Colors.white,
              secondary: AppColors.lightElevated,
              secondaryForeground: AppColors.textLight,
              muted: AppColors.lightElevated,
              mutedForeground: AppColors.textLightSecondary,
              accent: AppColors.lightElevated,
              accentForeground: AppColors.textLight,
              destructive: AppColors.error,
              destructiveForeground: Colors.white,
              border: AppColors.lightBorder,
              input: AppColors.lightBorder,
              ring: AppColors.lightGreenStart,
            );

      return ShadThemeData(
        brightness: _themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light,
        colorScheme: ShadColorScheme(
          background: parseColor('background', colorScheme.background),
          foreground: parseColor('foreground', colorScheme.foreground),
          card: parseColor('card', colorScheme.card),
          cardForeground: parseColor('cardForeground', colorScheme.cardForeground),
          popover: parseColor('popover', colorScheme.popover),
          popoverForeground: parseColor('popoverForeground', colorScheme.popoverForeground),
          primary: parseColor('primary', colorScheme.primary),
          primaryForeground: parseColor('primaryForeground', colorScheme.primaryForeground),
          secondary: parseColor('secondary', colorScheme.secondary),
          secondaryForeground: parseColor('secondaryForeground', colorScheme.secondaryForeground),
          muted: parseColor('muted', colorScheme.muted),
          mutedForeground: parseColor('mutedForeground', colorScheme.mutedForeground),
          accent: parseColor('accent', colorScheme.accent),
          accentForeground: parseColor('accentForeground', colorScheme.accentForeground),
          destructive: parseColor('destructive', colorScheme.destructive),
          destructiveForeground: parseColor('destructiveForeground', colorScheme.destructiveForeground),
          border: parseColor('border', colorScheme.border),
          input: parseColor('input', colorScheme.input),
          ring: parseColor('ring', colorScheme.ring),
          selection: parseColor('selection', colorScheme.selection),
        ),
      );
    } catch (e) {
      AppLogger.warning('Failed parsing dynamic theme data: $e');
      return null;
    }
  }

  Future<void> toggleTheme() async {
    final nextTheme = isDark ? 'light' : 'dark';
    await getIt<SettingsManager>().setString('workbench.colorTheme', nextTheme);
  }
}
