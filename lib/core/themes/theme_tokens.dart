import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppColors {
  // Light Mode (Light & Noir)
  static const lightBackground  = Color(0xFFFFFFFF);
  static const lightSurface     = Color(0xFFF9FAFB);
  static const lightElevated    = Color(0xFFF3F4F6);
  static const lightBorder      = Color(0xFFE5E7EB);
  static const lightBorderSubtle = Color(0xFFF3F4F6);
  
  // Dark Mode (Noir/IDE style)
  static const darkBackground   = Color(0xFF0D1117);
  static const darkSurface      = Color(0xFF161B22);
  static const darkElevated     = Color(0xFF21262D);
  static const darkBorder       = Color(0xFF30363D);
  static const darkBorderSubtle = Color(0xFF21262D);

  // Accents (Green Gradient components)
  static const lightGreenStart  = Color(0xFF10B981);
  static const lightGreenEnd    = Color(0xFF059669);
  static const darkGreenStart   = Color(0xFF047857);
  static const darkGreenEnd     = Color(0xFF064E3B);

  // Text Colors
  static const textPrimary      = Color(0xFFF0F6FC); // Dark mode default
  static const textSecondary    = Color(0xFF8B949E);
  static const textMuted        = Color(0xFF484F58);
  
  static const textLight        = Color(0xFF111827); // Light mode default
  static const textLightSecondary = Color(0xFF4B5563);
  static const textLightMuted   = Color(0xFF9CA3AF);

  // Semantic
  static const error   = Color(0xFFF85149);
  static const warning = Color(0xFFD29922);
  static const success = Color(0xFF238636);
  static const info    = Color(0xFF2F81F7);

  // Backward compatibility constants
  static const accent       = darkGreenStart;
  static const accentHover  = Color(0xFF059669);
  static const accentActive = Color(0xFF064E3B);
}

abstract class AppGradients {
  static LinearGradient green(bool isDark) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: isDark 
      ? [AppColors.darkGreenStart, AppColors.darkGreenEnd]
      : [AppColors.lightGreenStart, AppColors.lightGreenEnd],
  );

  static LinearGradient surface(bool isDark) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: isDark
      ? [AppColors.darkSurface, AppColors.darkElevated]
      : [AppColors.lightSurface, AppColors.lightElevated],
  );
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

  static TextStyle get caption  => TextStyle(fontFamily: _family, fontSize: 13, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get body     => TextStyle(fontFamily: _family, fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get bodyLg   => TextStyle(fontFamily: _family, fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get heading  => TextStyle(fontFamily: _family, fontSize: 18, fontWeight: FontWeight.w600, height: 1.4);
  static TextStyle get title    => TextStyle(fontFamily: _family, fontSize: 24, fontWeight: FontWeight.w700, height: 1.3);
  static TextStyle get label    => TextStyle(fontFamily: _family, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.6, height: 1.5);

  static const codeSm  = TextStyle(fontFamily: _mono, fontSize: 13, fontWeight: FontWeight.w400, height: 1.6);
  static const code    = TextStyle(fontFamily: _mono, fontSize: 14, fontWeight: FontWeight.w400, height: 1.6);
}
