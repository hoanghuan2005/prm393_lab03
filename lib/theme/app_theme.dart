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

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.onPrimary,
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // Loaders / progress bars
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.onPrimary,
        linearTrackColor: AppColors.surfaceVariant,
        circularTrackColor: Colors.transparent,
      ),

      // Text cursor & selection handles
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
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppDimens.space16,
          vertical: AppDimens.space16,
        ),
        hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: AppDimens.borderMedium,
          borderSide: BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimens.borderMedium,
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimens.borderMedium,
          borderSide: BorderSide(color: AppColors.onPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
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

  static ThemeData get darkTheme {
    const darkBackground = Color(0xFF101318);
    const darkSurface = Color(0xFF1B202A);
    const darkSurfaceVariant = Color(0xFF252D3C);
    const darkBorder = Color(0xFF293241);
    const darkTextPrimary = Color(0xFFF1F5F9);
    const darkTextSecondary = Color(0xFF94A3B8);

    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: Color(0xFF2C2706),
      onPrimaryContainer: AppColors.primary,
      secondary: darkTextPrimary,
      onSecondary: Color(0xFF0F172A),
      secondaryContainer: Color(0xFF232A38),
      onSecondaryContainer: darkTextPrimary,
      tertiary: Color(0xFF93B5CE),
      onTertiary: Color(0xFF0F172A),
      error: Color(0xFFF87171),
      onError: Color(0xFF450A0A),
      errorContainer: Color(0xFF451A1A),
      onErrorContainer: Color(0xFFFCA5A5),
      surface: darkSurface,
      onSurface: darkTextPrimary,
      onSurfaceVariant: darkTextSecondary,
      surfaceContainerHighest: darkSurfaceVariant,
      outline: Color(0xFF3B4659),
      outlineVariant: darkBorder,
      inverseSurface: darkTextPrimary,
      onInverseSurface: Color(0xFF0F172A),
      inversePrimary: Color(0xFFD4B800),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBackground,
      fontFamily: 'Be Vietnam Pro',
      extensions: const [MotiveColors.dark],

      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(color: darkTextPrimary),
        displayMedium: AppTextStyles.displayMedium.copyWith(color: darkTextPrimary),
        headlineLarge: AppTextStyles.headlineLarge.copyWith(color: darkTextPrimary),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(color: darkTextPrimary),
        titleLarge: AppTextStyles.titleLarge.copyWith(color: darkTextPrimary),
        titleMedium: AppTextStyles.titleMedium.copyWith(color: darkTextPrimary),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: darkTextPrimary),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: darkTextSecondary),
        labelLarge: AppTextStyles.labelLarge.copyWith(color: darkTextPrimary),
        labelMedium: AppTextStyles.labelMedium.copyWith(color: darkTextSecondary),
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkTextPrimary,
        elevation: AppDimens.elevationNone,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: darkTextPrimary,
          fontFamily: 'Be Vietnam Pro',
        ),
        iconTheme: IconThemeData(color: darkTextPrimary),
      ),

      // Elevated Button Theme
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

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: darkSurfaceVariant,
        circularTrackColor: Colors.transparent,
      ),

      // Text cursor & selection handles
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionHandleColor: AppColors.primary,
        selectionColor: AppColors.primary.withValues(alpha: 0.3),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkTextPrimary,
          minimumSize: const Size(double.infinity, AppDimens.minTouchTarget),
          side: const BorderSide(color: Color(0xFF3B4659), width: 1.5),
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
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppDimens.space16,
          vertical: AppDimens.space16,
        ),
        hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: AppDimens.borderMedium,
          borderSide: BorderSide(color: Color(0xFF3B4659)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimens.borderMedium,
          borderSide: BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimens.borderMedium,
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDimens.borderMedium,
          borderSide: BorderSide(color: AppColors.error),
        ),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        color: darkSurface,
        elevation: AppDimens.elevationNone,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimens.borderLarge,
          side: BorderSide(color: darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
        space: 1,
      ),

      // Dialog Theme
      dialogTheme: const DialogThemeData(
        backgroundColor: darkSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: AppDimens.borderLarge),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        modalBackgroundColor: darkSurface,
      ),
    );
  }
}
