import 'package:flutter/material.dart';

abstract class AppColors {
  // Dark palette — higher contrast than before
  static const darkBackground = Color(0xFF0C0C0E);
  static const darkSurface    = Color(0xFF18181B);  // was 131315 (+visible)
  static const darkElevated   = Color(0xFF27272A);  // was 1C1C1F (+visible)
  static const darkBorder     = Color(0xFF3F3F46);  // was 27272A (2× brighter)
  static const darkBorderSubtle = Color(0xFF27272A); // for very subtle dividers

  // Light palette
  static const lightBackground = Color(0xFFF8F8FA);
  static const lightSurface    = Color(0xFFFFFFFF);
  static const lightElevated   = Color(0xFFF4F4F5);
  static const lightBorder     = Color(0xFFE4E4E7);

  // Accent — emerald green
  static const accent      = Color(0xFF10B981);
  static const accentHover  = Color(0xFF34D399);
  static const accentActive = Color(0xFF059669);
  static const accentGlow   = Color(0xFF10B981); // for box-shadow alpha usage
  static const accentLight  = Color(0xFF059669);
  static const accentLightHover = Color(0xFF10B981);

  // Text — dark mode (improved readability)
  static const textPrimary   = Color(0xFFFAFAFA);
  static const textSecondary = Color(0xFFA1A1AA);  // was 71717A — much brighter
  static const textMuted     = Color(0xFF71717A);  // was 52525B
  static const textLight     = Color(0xFF09090B);

  // Semantic
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
  static const r8  = Radius.circular(8);
  static const r12 = Radius.circular(12);
  static const r16 = Radius.circular(16);

  static const br4  = BorderRadius.all(r4);
  static const br8  = BorderRadius.all(r8);
  static const br12 = BorderRadius.all(r12);
  static const br16 = BorderRadius.all(r16);
}

abstract class AppTypography {
  static const _family = 'JetBrains Mono';

  static const caption = TextStyle(fontFamily: _family, fontSize: 12, fontWeight: FontWeight.w400);
  static const body    = TextStyle(fontFamily: _family, fontSize: 13, fontWeight: FontWeight.w400);
  static const bodyLg  = TextStyle(fontFamily: _family, fontSize: 14, fontWeight: FontWeight.w400);
  static const heading = TextStyle(fontFamily: _family, fontSize: 16, fontWeight: FontWeight.w600);
  static const title   = TextStyle(fontFamily: _family, fontSize: 20, fontWeight: FontWeight.w700);
  static const label   = TextStyle(fontFamily: _family, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8);
}
