import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppColors {
  static const lightBackground  = Color(0xFFF9FAFB);
  static const lightSurface     = Color(0xFFFFFFFF);
  static const lightElevated    = Color(0xFFF3F4F6);
  static const lightBorder      = Color(0xFFE5E7EB);
  static const lightBorderSubtle = Color(0xFFF3F4F6);

  static const darkBackground   = Color(0xFF1E1F22);
  static const darkSurface      = Color(0xFF2B2D30);
  static const darkElevated     = Color(0xFF393B40);
  static const darkBorder       = Color(0xFF4E5157);
  static const darkBorderSubtle = Color(0xFF393B40);

  static const accent           = Color(0xFF10B981);
  static const accentHover      = Color(0xFF34D399);
  static const accentActive     = Color(0xFF059669);
  static const accentGlow       = Color(0xFF10B981);
  static const accentLight      = Color(0xFF059669);
  static const accentLightHover = Color(0xFF10B981);

  static const textPrimary      = Color(0xFFDFE1E5);
  static const textSecondary    = Color(0xFFA8ADBA);
  static const textMuted        = Color(0xFF6F737A);
  static const textLight        = Color(0xFF1F2937);
  static const textLightSecondary = Color(0xFF6B7280);

  static const error   = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const success = Color(0xFF10B981);
}

abstract class AppDurations {
  static const micro  = Duration(milliseconds: 120);
  static const short  = Duration(milliseconds: 200);
  static const medium = Duration(milliseconds: 300);
  static const long   = Duration(milliseconds: 450);
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
  static const xs   = 4.0;
  static const sm   = 8.0;
  static const md   = 16.0;
  static const lg   = 24.0;
  static const xl   = 32.0;
  static const xxl  = 48.0;

  static const pagePadding = EdgeInsets.all(24.0);
  static const cardPadding = EdgeInsets.all(20.0);
  static const sectionGap  = SizedBox(height: 24.0);
  static const itemGap     = SizedBox(height: 12.0);
}

abstract class AppTypography {
  static String get _family => GoogleFonts.montserrat().fontFamily!;
  static const _mono = 'JetBrains Mono';

  static TextStyle get caption  => TextStyle(fontFamily: _family, fontSize: 12, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get body     => TextStyle(fontFamily: _family, fontSize: 13, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get bodyLg   => TextStyle(fontFamily: _family, fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get heading  => TextStyle(fontFamily: _family, fontSize: 16, fontWeight: FontWeight.w600, height: 1.4);
  static TextStyle get title    => TextStyle(fontFamily: _family, fontSize: 20, fontWeight: FontWeight.w700, height: 1.3);
  static TextStyle get label    => TextStyle(fontFamily: _family, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6, height: 1.5);

  static const codeSm  = TextStyle(fontFamily: _mono, fontSize: 12, fontWeight: FontWeight.w400, height: 1.6);
  static const code    = TextStyle(fontFamily: _mono, fontSize: 13, fontWeight: FontWeight.w400, height: 1.6);
}
