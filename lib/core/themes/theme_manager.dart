import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:path/path.dart' as p;
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/system/settings_manager.dart';
import 'package:stress_pilot/core/system/logger.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/core/themes/pilot_theme.dart';
import 'package:stress_pilot/core/themes/pilot_colors.dart';

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

  ShadThemeData get darkShadTheme => _generateShadTheme(_fleetTheme);
  ShadThemeData get lightShadTheme => _generateShadTheme(_fleetLightTheme);

  PilotColors get pilotColors => _buildPilotColors(currentTheme);

  PilotColors _buildPilotColors(PilotTheme theme) {
    return PilotColors(
      background:    theme.getColor('background',    AppColors.baseBackground),
      surface:       theme.getColor('surface',       AppColors.sidebarBackground),
      elevated:      theme.getColor('elevated',      AppColors.elevatedSurface),
      activeItem:    theme.getColor('activeItem',    AppColors.activeItem),
      hoverItem:     theme.getColor('hoverItem',     AppColors.hoverItem),
      accent:        theme.getColor('accent',        AppColors.accent),
      accentHover:   theme.getColor('accentHover',   AppColors.accentHover),
      accentActive:  theme.getColor('accentActive',  AppColors.accentActive),
      border:        theme.getColor('border',        AppColors.border),
      divider:       theme.getColor('divider',       AppColors.divider),
      textPrimary:   theme.getColor('textPrimary',   AppColors.textPrimary),
      textSecondary: theme.getColor('textSecondary', AppColors.textSecondary),
      textDisabled:  theme.getColor('textDisabled',  AppColors.textDisabled),
      error:         theme.getColor('error',         AppColors.error),
      methodGet:     theme.getColor('success',       AppColors.methodGet),
      methodPost:    theme.getColor('info',          AppColors.methodPost),
      methodPut:     theme.getColor('warning',       AppColors.methodPut),
      methodDelete:  theme.getColor('methodDelete',  AppColors.methodDelete),
      methodPatch:   theme.getColor('methodPatch',   AppColors.methodPatch),
    );
  }

  static final _fleetTheme = PilotTheme(
    id: 'fleet',
    name: 'JetBrains Fleet',
    brightness: Brightness.dark,
    colors: {
      'background': const Color(0xFF1E1F28),
      'surface': const Color(0xFF22232D),
      'elevated': const Color(0xFF2A2B36),
      'activeItem': const Color(0xFF2E3044),
      'hoverItem': const Color(0xFF272838),
      'accent': const Color(0xFF5B9BD5),
      'textPrimary': const Color(0xFFD4D4D6),
      'textSecondary': const Color(0xFF757580),
      'textDisabled': const Color(0xFF45454E),
    },
  );

  static final _fleetLightTheme = PilotTheme(
    id: 'fleet-light',
    name: 'JetBrains Fleet Light',
    brightness: Brightness.light,
    colors: {
      'background': const Color(0xFFFFFFFF),
      'surface': const Color(0xFFF7F8FA),
      'elevated': const Color(0xFFFFFFFF),
      'activeItem': const Color(0xFFE4E6ED),
      'hoverItem': const Color(0xFFF0F1F5),
      'accent': const Color(0xFF3574F0),
      'textPrimary': const Color(0xFF19191C),
      'textSecondary': const Color(0xFF70727A),
      'textDisabled': const Color(0xFFAAAAAA),
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

  Future<void> reloadThemes() async {
    final currentThemeId = _currentTheme?.id;
    await loadAvailableThemes();
    
    if (currentThemeId != null) {
      final updated = _availableThemes.firstWhere(
        (t) => t.id == currentThemeId,
        orElse: () => _fleetTheme,
      );
      _currentTheme = updated;
      _currentShadTheme = _generateShadTheme(updated);
      notifyListeners();
    }
  }

  Future<void> loadAvailableThemes() async {
    _availableThemes.clear();
    _availableThemes.add(_fleetTheme);
    _availableThemes.add(_fleetLightTheme);

    // Load bundled asset themes
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifest = jsonDecode(manifestContent);
      final themeAssets = manifest.keys
          .where((k) => k.startsWith('assets/themes/') && k.endsWith('.json'))
          .toList();

      for (final assetPath in themeAssets) {
        try {
          final content = await rootBundle.loadString(assetPath);
          final json = jsonDecode(content);
          final id = p.basenameWithoutExtension(assetPath.split('/').last);
          _availableThemes.add(PilotTheme.fromJson(id, json));
        } catch (e) {
          AppLogger.warning('Failed to parse bundled theme $assetPath: $e');
        }
      }
    } catch (e) {
      AppLogger.warning('Failed to load bundled themes: $e');
    }

    // Load user filesystem themes
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
    final nextId = currentTheme.isDark ? 'fleet-light' : 'fleet';
    await setTheme(nextId);
  }
}
