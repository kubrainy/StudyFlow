import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tipografi ölçeği (DESIGN.md → Typography).
/// letterSpacing değerleri "em" → px'e çevrilmiştir (fontSize * em).
abstract final class AppTextStyles {
  static TextStyle _jakarta(
    double size,
    FontWeight weight,
    double lineHeight,
    double letterSpacingEm,
  ) => GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: weight,
    height: lineHeight / size,
    letterSpacing: size * letterSpacingEm,
    color: AppColors.textPrimary,
  );

  static TextStyle _mono(
    double size,
    FontWeight weight,
    double lineHeight,
    double letterSpacingEm,
  ) => GoogleFonts.jetBrainsMono(
    fontSize: size,
    fontWeight: weight,
    height: lineHeight / size,
    letterSpacing: size * letterSpacingEm,
    color: AppColors.textPrimary,
  );

  // Plus Jakarta Sans
  static final headlineXl = _jakarta(40, FontWeight.w800, 48, -0.03);
  static final headlineXlMobile = _jakarta(32, FontWeight.w800, 40, -0.025);
  static final headlineLg = _jakarta(28, FontWeight.w700, 36, -0.02);
  static final headlineMd = _jakarta(22, FontWeight.w700, 28, -0.015);
  static final titleMd = _jakarta(18, FontWeight.w600, 24, -0.01);
  static final bodyLg = _jakarta(16, FontWeight.w400, 24, 0);
  static final bodyMd = _jakarta(14, FontWeight.w400, 20, 0);
  static final bodySm = _jakarta(12, FontWeight.w500, 16, 0.01);

  // JetBrains Mono
  static final timerDisplay = _mono(56, FontWeight.w700, 64, -0.04);
  static final timerDisplayMobile = _mono(44, FontWeight.w700, 52, -0.03);
  static final statMono = _mono(14, FontWeight.w600, 18, -0.01);

  /// Büyük harf mikro etiket; metni çağıran tarafta `toUpperCase()` ile verin.
  static final labelCaps = _mono(
    11,
    FontWeight.w600,
    14,
    0.06,
  ).copyWith(color: AppColors.textSecondary);

  /// Material TextTheme eşlemesi.
  static TextTheme get textTheme => TextTheme(
    headlineLarge: headlineXl,
    headlineMedium: headlineLg,
    headlineSmall: headlineMd,
    titleMedium: titleMd,
    bodyLarge: bodyLg,
    bodyMedium: bodyMd,
    bodySmall: bodySm.copyWith(color: AppColors.textSecondary),
    labelSmall: labelCaps,
  );
}
