import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_text_styles.dart';
import 'motive_colors.dart';

/// Centralized ThemeData for Why I Buy
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimary,
      secondary: AppColors.onPrimary,
      onSecondary: AppColors.textOnDark,
      secondaryContainer: AppColors.primaryContainer,
      onSecondaryContainer: AppColors.onPrimary,
      tertiary: AppColors.accentNeutral,
      onTertiary: AppColors.textOnDark,
      error: AppColors.error,
      onError: AppColors.textOnDark,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerHighest: AppColors.surfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.divider,
      inverseSurface: AppColors.onPrimary,
      onInverseSurface: AppColors.textOnDark,
      inversePrimary: AppColors.primary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Be Vietnam Pro',
      extensions: const [MotiveColors.light],

      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: AppDimens.elevationNone,
        centerTitle: false,
        titleTextStyle: AppTextStyles.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      // Elevated Button Theme (Min 48dp height for accessibility)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(double.infinity, AppDimens.minTouchTarget),
          shape: const RoundedRectangleBorder(
            borderRadius: AppDimens.borderPill,
          ),
          elevation: AppDimens.elevationNone,
          textStyle: AppTextStyles.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space24,
            vertical: AppDimens.space12,
          ),
        ),
      ),

      // Text Button Theme: primary (yellow) text on white fails WCAG AA, use onPrimary
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.onPrimary,
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // Loaders / progress bars on white: navy indicator, grey track
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.onPrimary,
        linearTrackColor: AppColors.surfaceVariant,
        circularTrackColor: Colors.transparent,
      ),

      // Text cursor & selection handles (default would be yellow on white)
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.onPrimary,
        selectionHandleColor: AppColors.onPrimary,
        selectionColor: AppColors.primary.withValues(alpha: 0.4),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(double.infinity, AppDimens.minTouchTarget),
          side: const BorderSide(color: AppColors.outline, width: 1.5),
          shape: const RoundedRectangleBorder(
            borderRadius: AppDimens.borderPill,
          ),
          textStyle: AppTextStyles.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space24,
            vertical: AppDimens.space12,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space16,
          vertical: AppDimens.space16,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
        border: const OutlineInputBorder(
          borderRadius: AppDimens.borderMedium,
          borderSide: BorderSide(color: AppColors.outline),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppDimens.borderMedium,
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppDimens.borderMedium,
          borderSide: BorderSide(color: AppColors.onPrimary, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppDimens.borderMedium,
          borderSide: BorderSide(color: AppColors.error),
        ),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: AppDimens.elevationNone,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimens.borderLarge,
          side: BorderSide(color: AppColors.divider, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
