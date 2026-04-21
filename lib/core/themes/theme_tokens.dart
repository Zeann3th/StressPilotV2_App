import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/themes/theme_manager.dart';
import 'package:stress_pilot/core/themes/pilot_theme.dart';

abstract class AppColors {
  // Fleet Base Palette
  static const baseBackground    = Color(0xFF1E1F22);
  static const sidebarBackground = Color(0xFF23242A);
  static const elevatedSurface   = Color(0xFF2B2C33);
  static const activeItem        = Color(0xFF383A47);
  static const hoverItem         = Color(0xFF2E2F38);
  static const accent            = Color(0xFF7B68EE); // Muted Indigo
  static const accentHover       = Color(0xFF8B7BEE);
  
  static const border            = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const divider           = Color(0x0FFFFFFF); // rgba(255,255,255,0.06)

  static const textPrimary       = Color(0xFFDCD9D0);
  static const textSecondary     = Color(0xFF7E7C75);
  static const textDisabled      = Color(0xFF4A4845);

  // Method Badges
  static const methodGet         = Color(0xFF57A64A);
  static const methodPost        = Color(0xFF4B8FD4);
  static const methodPut         = Color(0xFFC8A84B);
  static const methodDelete      = Color(0xFFC25151);
  static const methodPatch       = Color(0xFF8B68D4);

  static const error             = Color(0xFFD2504B); // Muted Red

  static PilotTheme get _theme => getIt<ThemeManager>().currentTheme;

  static Color get background => baseBackground;
  static Color get surface => sidebarBackground;
  static Color get elevated => elevatedSurface;
  static Color get borderCol => border;

  static Color get primary => textPrimary;
  static Color get secondary => textSecondary;
  static Color get muted => textDisabled;

  static Color get accentColor => accent;
}

abstract class AppGradients {
  // Fleet uses solid colors, no gradients
}

abstract class AppDurations {
  static const micro  = Duration(milliseconds: 100);
  static const short  = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 200);
}

abstract class AppRadius {
  static const r4  = Radius.circular(4);
  static const r6  = Radius.circular(6);
  static const r8  = Radius.circular(8);

  static const br4  = BorderRadius.all(r4);
  static const br6  = BorderRadius.all(r6);
  static const br8  = BorderRadius.all(r8);
}

abstract class AppSpacing {
  static const xs   = 4.0;
  static const sm   = 8.0;
  static const md   = 12.0;
  static const lg   = 16.0;
  static const xl   = 24.0;
  static const xxl  = 32.0;

  // Fleet Density
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

  static TextStyle get caption  => TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static TextStyle get body     => TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textPrimary);
  static TextStyle get bodyMd   => TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
  static TextStyle get heading  => TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
  static TextStyle get label    => TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.2, color: AppColors.textSecondary);

  static TextStyle get codeSm   => TextStyle(fontFamily: _mono, fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textPrimary);
  static TextStyle get code     => TextStyle(fontFamily: _mono, fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textPrimary);
  static TextStyle get codePath => TextStyle(fontFamily: _mono, fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
}

