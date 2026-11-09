import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Centralized Typography using 'Be Vietnam Pro'
/// Strictly complies with the >= 14sp body text accessibility rule
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get displayLarge => GoogleFonts.beVietnamPro(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static TextStyle get displayMedium => GoogleFonts.beVietnamPro(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get headlineLarge => GoogleFonts.beVietnamPro(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get headlineMedium => GoogleFonts.beVietnamPro(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  static TextStyle get titleLarge => GoogleFonts.beVietnamPro(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  static TextStyle get titleMedium => GoogleFonts.beVietnamPro(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static TextStyle get bodyLarge => GoogleFonts.beVietnamPro(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.45,
  );

  // Must be >= 14sp per Lab 2 accessibility checklist
  static TextStyle get bodyMedium => GoogleFonts.beVietnamPro(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  static TextStyle get labelLarge => GoogleFonts.beVietnamPro(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static TextStyle get labelMedium => GoogleFonts.beVietnamPro(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.35,
  );

  static TextStyle get caption => GoogleFonts.beVietnamPro(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );
}

/// [AppTextStyles] carry light-mode text colours, which are dark on dark surfaces.
/// `themed` keeps a style unchanged in light mode and, in dark mode, swaps those
/// colours for the theme's text colours. Styles with any other colour stay as they are.
extension ThemedTextStyle on TextStyle {
  TextStyle themed(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.brightness == Brightness.light) return this;
    final scheme = theme.colorScheme;
    final c = color;
    if (c == AppColors.textPrimary ||
        c == AppColors.textBody ||
        c == AppColors.onPrimary) {
      return copyWith(color: scheme.onSurface);
    }
    if (c == AppColors.textSecondary ||
        c == AppColors.textHint ||
        c == AppColors.accentNeutral) {
      return copyWith(color: scheme.onSurfaceVariant);
    }
    return this;
  }
}
