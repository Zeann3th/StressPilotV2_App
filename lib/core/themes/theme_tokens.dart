import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/themes/theme_manager.dart';
import 'package:stress_pilot/core/themes/pilot_theme.dart';

abstract class AppColors {
  // Base Colors (Fallbacks for DARK)
  static const _fallbackBackground = Color(0xFF1E1F28);
  static const _fallbackSidebar    = Color(0xFF22232D);
  static const _fallbackElevated   = Color(0xFF2A2B36);
  static const _fallbackActive     = Color(0xFF2E3044);
  static const _fallbackHover      = Color(0xFF272838);
  static const _fallbackAccent     = Color(0xFF5B9BD5);
  static const _fallbackText       = Color(0xFFD4D4D6);
  static const _fallbackSecondary  = Color(0xFF757580);
  static const _fallbackDisabled   = Color(0xFF45454E);

  // Private helper to get current theme
  static PilotTheme get _theme => getIt<ThemeManager>().currentTheme;

  // Dynamic Getters with Context-Aware Fallbacks
  static Color get baseBackground    => _theme.getColor('background',    _theme.isDark ? _fallbackBackground : AppColorsLight.baseBackground);
  static Color get sidebarBackground => _theme.getColor('surface',       _theme.isDark ? _fallbackSidebar    : AppColorsLight.sidebarBackground);
  static Color get elevatedSurface   => _theme.getColor('elevated',      _theme.isDark ? _fallbackElevated   : AppColorsLight.elevatedSurface);
  static Color get activeItem        => _theme.getColor('activeItem',    _theme.isDark ? _fallbackActive     : AppColorsLight.activeItem);
  static Color get hoverItem         => _theme.getColor('hoverItem',     _theme.isDark ? _fallbackHover      : AppColorsLight.hoverItem);
  static Color get accent            => _theme.getColor('accent',        _theme.isDark ? _fallbackAccent     : AppColorsLight.accent);
  static Color get accentHover       => _theme.getColor('accentHover',   accent.withValues(alpha: 0.85));
  static Color get accentActive      => _theme.getColor('accentActive',  accent.withValues(alpha: 0.7));

  static Color get border            => _theme.getColor('border',        _theme.isDark ? const Color(0x14FFFFFF) : const Color(0x1F000000));
  static Color get divider           => _theme.getColor('divider',       _theme.isDark ? const Color(0x0FFFFFFF) : const Color(0x14000000));

  static Color get textPrimary       => _theme.getColor('textPrimary',   _theme.isDark ? _fallbackText       : AppColorsLight.textPrimary);
  static Color get textSecondary     => _theme.getColor('textSecondary', _theme.isDark ? _fallbackSecondary  : AppColorsLight.textSecondary);
  static Color get textDisabled      => _theme.getColor('textDisabled',  _theme.isDark ? _fallbackDisabled   : AppColorsLight.textDisabled);
  static Color get textMuted         => textDisabled;

  static Color get methodGet         => _theme.getColor('success',       const Color(0xFF57A64A));
  static Color get methodPost        => _theme.getColor('info',          _theme.isDark ? const Color(0xFF4B8FD4) : AppColorsLight.methodPost);
  static Color get methodPut         => _theme.getColor('warning',       const Color(0xFFC8A84B));
  static Color get methodDelete      => _theme.getColor('methodDelete',  const Color(0xFFC25151));
  static Color get methodPatch       => _theme.getColor('methodPatch',   const Color(0xFF8B68D4));

  static Color get error             => _theme.getColor('error',         const Color(0xFFD2504B));
  static Color get success           => methodGet;
  static Color get warning           => methodPut;
  static Color get info              => methodPost;

  // Legacy mappings for backward compatibility
  static Color get background => baseBackground;
  static Color get surface    => sidebarBackground;
  static Color get elevated   => elevatedSurface;
  static Color get borderCol  => border;
  static Color get primary    => textPrimary;
  static Color get secondary  => textSecondary;
  static Color get muted      => textDisabled;
  static Color get accentColor => accent;
}

abstract class AppGradients {
  static LinearGradient green([bool? isDark]) {
    final color = AppColors.accent;
    return LinearGradient(
      colors: [color, color.withValues(alpha: 0.8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

abstract class AppColorsLight {
  static const baseBackground    = Color(0xFFFFFFFF);
  static const sidebarBackground = Color(0xFFF7F8FA);
  static const elevatedSurface   = Color(0xFFFFFFFF);
  static const activeItem        = Color(0xFFE4E6ED);
  static const hoverItem         = Color(0xFFF0F1F5);
  static const accent            = Color(0xFF3574F0);
  static const accentHover       = Color(0xFF4B85F2);
  static const border            = Color(0x1F000000);
  static const divider           = Color(0x14000000);
  static const textPrimary       = Color(0xFF19191C);
  static const textSecondary     = Color(0xFF70727A);
  static const textDisabled      = Color(0xFFAAAAAA);
  static const accentActive      = Color(0xFF2E68E0);

  static const methodGet    = Color(0xFF57A64A);
  static const methodPost   = Color(0xFF3574F0);
  static const methodPut    = Color(0xFFC8A84B);
  static const methodDelete = Color(0xFFC25151);
  static const methodPatch  = Color(0xFF8B68D4);
  static const error        = Color(0xFFD2504B);
  static const success      = methodGet;
  static const warning      = methodPut;
  static const info         = methodPost;
}

abstract class AppDurations {
  static const micro  = Duration(milliseconds: 100);
  static const short  = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 200);
}

abstract class AppShadows {
  static List<BoxShadow> get panel => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  static List<BoxShadow> get subtle => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];
}

abstract class AppRadius {
  static const r4  = Radius.circular(4);
  static const r6  = Radius.circular(6);
  static const r8  = Radius.circular(8);
  static const r10 = Radius.circular(10);
  static const r12 = Radius.circular(12);
  static const r16 = Radius.circular(16);

  static const br4  = BorderRadius.all(r4);
  static const br6  = BorderRadius.all(r6);
  static const br8  = BorderRadius.all(r8);
  static const br10 = BorderRadius.all(r10);
  static const br12 = BorderRadius.all(r12);
  static const br16 = BorderRadius.all(r16);
}

abstract class AppSpacing {
  static const xs   = 4.0;
  static const sm   = 8.0;
  static const md   = 12.0;
  static const lg   = 16.0;
  static const xl   = 24.0;
  static const xxl  = 32.0;

  static const sidebarRowHeight = 32.0;
  static const tabBarHeight     = 36.0;
  static const navBarHeight      = 40.0;
  static const fieldHeight      = 32.0;

  static const pagePadding = EdgeInsets.all(16.0);
  static const sectionGap  = SizedBox(height: 12.0);
  static const itemGap     = SizedBox(height: 8.0);
}

abstract class AppTypography {
  static const _mono = 'JetBrains Mono';

  static TextStyle get caption => GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static TextStyle get body    => GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textPrimary);
  static TextStyle get bodyMd  => GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
  static TextStyle get bodyLg  => GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
  static TextStyle get heading => GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static TextStyle get title   => GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static TextStyle get label   => GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.3, color: AppColors.textSecondary);

  static TextStyle get codeSm   => TextStyle(fontFamily: _mono, fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textPrimary);
  static TextStyle get code     => TextStyle(fontFamily: _mono, fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textPrimary);
  static TextStyle get codePath => TextStyle(fontFamily: _mono, fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
}
