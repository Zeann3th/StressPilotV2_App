import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/themes/theme_manager.dart';
import 'package:stress_pilot/core/themes/pilot_theme.dart';

abstract class AppColors {

  static const lightBackground  = Color(0xFFFFFFFF);
  static const lightSurface     = Color(0xFFF9FAFB);
  static const lightElevated    = Color(0xFFF3F4F6);
  static const lightBorder      = Color(0xFFE5E7EB);

  static const darkBackground   = Color(0xFF0D1117);
  static const darkSurface      = Color(0xFF161B22);
  static const darkElevated     = Color(0xFF21262D);
  static const darkBorder       = Color(0xFF30363D);

  static const lightGreenStart  = Color(0xFF10B981);
  static const darkGreenStart   = Color(0xFF047857);

  static const error   = Color(0xFFF85149);
  static const warning = Color(0xFFD29922);
  static const success = Color(0xFF238636);
  static const info    = Color(0xFF2F81F7);

  static PilotTheme get _theme => getIt<ThemeManager>().currentTheme;

  static Color get background => _theme.getColor('background', _theme.isDark ? darkBackground : lightBackground);
  static Color get surface => _theme.getColor('surface', _theme.isDark ? darkSurface : lightSurface);
  static Color get elevated => _theme.getColor('elevated', _theme.isDark ? darkElevated : lightElevated);
  static Color get border => _theme.getColor('border', _theme.isDark ? darkBorder : lightBorder);

  static Color get textPrimary => _theme.getColor('textPrimary', _theme.isDark ? const Color(0xFFF0F6FC) : const Color(0xFF111827));
  static Color get textSecondary => _theme.getColor('textSecondary', _theme.isDark ? const Color(0xFF8B949E) : const Color(0xFF4B5563));
  static Color get textMuted => _theme.getColor('textMuted', _theme.isDark ? const Color(0xFF484F58) : const Color(0xFF9CA3AF));

  static Color get accent => _theme.getColor('accent', _theme.isDark ? darkGreenStart : lightGreenStart);
  static Color get accentHover => accent.withValues(alpha: 0.85);
  static Color get accentActive => accent.withValues(alpha: 0.7);

  static Color get darkGreenStartVal => darkGreenStart;
  static Color get lightGreenStartVal => lightGreenStart;

  static const textLight        = Color(0xFF111827);
  static const textLightSecondary = Color(0xFF4B5563);
}

abstract class AppGradients {
  static LinearGradient green(bool isDark) {
    final accent = isDark ? AppColors.darkGreenStart : AppColors.lightGreenStart;
    final theme = getIt<ThemeManager>().currentTheme;
    final color = theme.getColor('accent', accent);

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color,
        color.withValues(alpha: 0.8),
      ],
    );
  }

  static LinearGradient surface(bool isDark) {
    final theme = getIt<ThemeManager>().currentTheme;
    final surface = theme.getColor('surface', isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final elevated = theme.getColor('elevated', isDark ? AppColors.darkElevated : AppColors.lightElevated);

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [surface, elevated],
    );
  }
}
abstract class AppDurations {
  static const micro  = Duration(milliseconds: 150);
  static const short  = Duration(milliseconds: 200);
  static const medium = Duration(milliseconds: 250);
  static const long   = Duration(milliseconds: 300);
}

abstract class AppRadius {
  static const r4  = Radius.circular(4);
  static const r6  = Radius.circular(6);
  static const r8  = Radius.circular(8);
  static const r12 = Radius.circular(12);
  static const r16 = Radius.circular(16);

  static const br4  = BorderRadius.all(r4);
  static const br6  = BorderRadius.all(r6);
  static const br8  = BorderRadius.all(r8);
  static const br12 = BorderRadius.all(r12);
  static const br16 = BorderRadius.all(r16);
}

abstract class AppSpacing {
  static const xs   = 6.0;
  static const sm   = 12.0;
  static const md   = 20.0;
  static const lg   = 32.0;
  static const xl   = 40.0;
  static const xxl  = 60.0;

  static const pagePadding = EdgeInsets.all(32.0);
  static const cardPadding = EdgeInsets.all(24.0);
  static const sectionGap  = SizedBox(height: 32.0);
  static const itemGap     = SizedBox(height: 16.0);
}

abstract class AppTypography {
  static String get _family => GoogleFonts.ibmPlexSans().fontFamily!;
  static const _mono = 'JetBrains Mono';

  static TextStyle get caption  => TextStyle(fontFamily: _family, fontSize: 13, fontWeight: FontWeight.w400, height: 1.5, color: AppColors.textSecondary);
  static TextStyle get body     => TextStyle(fontFamily: _family, fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, color: AppColors.textPrimary);
  static TextStyle get bodyLg   => TextStyle(fontFamily: _family, fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: AppColors.textPrimary);
  static TextStyle get heading  => TextStyle(fontFamily: _family, fontSize: 18, fontWeight: FontWeight.w600, height: 1.4, color: AppColors.textPrimary);
  static TextStyle get title    => TextStyle(fontFamily: _family, fontSize: 24, fontWeight: FontWeight.w700, height: 1.3, color: AppColors.textPrimary);
  static TextStyle get label    => TextStyle(fontFamily: _family, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.6, height: 1.5, color: AppColors.textSecondary);

  static TextStyle get codeSm  => TextStyle(fontFamily: _mono, fontSize: 13, fontWeight: FontWeight.w400, height: 1.6, color: AppColors.textPrimary);
  static TextStyle get code    => TextStyle(fontFamily: _mono, fontSize: 14, fontWeight: FontWeight.w400, height: 1.6, color: AppColors.textPrimary);
}
