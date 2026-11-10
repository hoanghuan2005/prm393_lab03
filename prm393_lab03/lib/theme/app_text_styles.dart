import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_semantic_colors.dart';

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
  /// Typography token that inherits the surrounding foreground (e.g. a button).
  /// Explicit semantic colours can still be supplied with copyWith.
  TextStyle get withInheritedColor => TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    letterSpacing: letterSpacing,
  );

  TextStyle themed(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.brightness == Brightness.light) return this;
    final colors = AppSemanticColors.fromTheme(theme);
    final c = color;
    if (c == AppColors.textPrimary || c == AppColors.onPrimary) {
      return copyWith(color: colors.textPrimary);
    }
    if (c == AppColors.textBody) {
      return copyWith(color: colors.textBody);
    }
    if (c == AppColors.textSecondary) {
      return copyWith(color: colors.textSecondary);
    }
    if (c == AppColors.textHint) {
      return copyWith(color: colors.hint);
    }
    if (c == AppColors.accentNeutral) {
      return copyWith(color: colors.accent);
    }
    return this;
  }
}
