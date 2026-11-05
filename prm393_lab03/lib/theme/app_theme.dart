import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_text_styles.dart';
import 'motive_colors.dart';

/// Centralized ThemeData for Why I Buy
/// Color palette synchronized with Admin Web Portal (Tailwind CSS)
/// Both platforms share the same brand identity: amber-400 primary + slate system
class AppTheme {
  AppTheme._();

  // ═══════════════════════════════════════════════════════════════════════════
  // LIGHT THEME
  // Web equivalent: hypothetical light mode (inverse of current dark portal)
  // ═══════════════════════════════════════════════════════════════════════════
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      // Primary: amber-400 brand
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimary,
      // Secondary: slate-900 (dark navy)
      secondary: AppColors.onPrimary,
      onSecondary: AppColors.textOnDark,
      secondaryContainer: AppColors.primaryContainer,
      onSecondaryContainer: AppColors.onPrimary,
      // Tertiary: neutral accent
      tertiary: AppColors.accentNeutral,
      onTertiary: AppColors.textOnDark,
      // Error: red-500
      error: AppColors.error,
      onError: AppColors.textOnDark,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      // Surface: white cards on slate-50 bg
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerHighest: AppColors.surfaceVariant,
      // Borders & outlines: slate-200/300
      outline: AppColors.outline,
      outlineVariant: AppColors.divider,
      // Inverse: dark overlay
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
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
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

  // ═══════════════════════════════════════════════════════════════════════════
  // DARK THEME
  // Exactly matches Admin Web Portal Tailwind dark palette:
  //   bg: slate-950 (#020617)  |  surface: slate-900 (#0F172A)
  //   cards: slate-900/80      |  border: slate-800 (#1E293B)
  //   text: slate-50/400       |  primary: amber-400 (#FBBF24)
  // ═══════════════════════════════════════════════════════════════════════════
  static ThemeData get darkTheme {
    // Web: bg-slate-950 → scaffold
    const darkBackground = AppColors.darkBackground; // #020617
    // Web: bg-slate-900/80 → cards, panels
    const darkSurface = AppColors.darkSurface; // #0F172A
    // Web: bg-slate-800 → variant containers
    const darkSurfaceVariant = AppColors.darkSurfaceVariant; // #1E293B
    // Web: border-slate-800
    const darkBorder = AppColors.darkBorder; // #1E293B
    // Web: text-white / text-slate-50
    const darkTextPrimary = AppColors.darkTextPrimary; // #F8FAFC
    // Web: text-slate-400
    const darkTextSecondary = AppColors.darkTextSecondary; // #94A3B8

    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      // Primary: amber-400 (same as web `bg-amber-400`, `text-amber-400`)
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      // Web: bg-amber-400/20 containers
      primaryContainer: AppColors.darkPrimaryContainer,
      onPrimaryContainer: AppColors.primary,
      // Secondary: light text
      secondary: darkTextPrimary,
      onSecondary: Color(0xFF0F172A),
      // Web: bg-slate-800/60 secondary containers
      secondaryContainer: Color(0xFF1E293B),
      onSecondaryContainer: darkTextPrimary,
      // Tertiary: muted blue-gray
      tertiary: AppColors.darkAccentNeutral,
      onTertiary: Color(0xFF0F172A),
      // Error: red-400 for dark (Web: `text-rose-400`)
      error: AppColors.errorLight, // #F87171
      onError: Color(0xFF450A0A),
      errorContainer: AppColors.darkErrorContainer,
      onErrorContainer: AppColors.darkOnErrorContainer, // red-300
      // Surface: slate-900 (matches Web `bg-slate-900/80`)
      surface: darkSurface,
      onSurface: darkTextPrimary,
      onSurfaceVariant: darkTextSecondary,
      // Variant: slate-800 (matches Web `bg-slate-800`)
      surfaceContainerHighest: darkSurfaceVariant,
      // Outline: slate-700 (Web: `border-slate-700`)
      outline: AppColors.darkOutline, // #334155
      // OutlineVariant: slate-800 (Web: `border-slate-800`)
      outlineVariant: darkBorder,
      // Inverse
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
        displayLarge: AppTextStyles.displayLarge.copyWith(
          color: darkTextPrimary,
        ),
        displayMedium: AppTextStyles.displayMedium.copyWith(
          color: darkTextPrimary,
        ),
        headlineLarge: AppTextStyles.headlineLarge.copyWith(
          color: darkTextPrimary,
        ),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(
          color: darkTextPrimary,
        ),
        titleLarge: AppTextStyles.titleLarge.copyWith(color: darkTextPrimary),
        titleMedium: AppTextStyles.titleMedium.copyWith(color: darkTextPrimary),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: darkTextPrimary),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: darkTextSecondary),
        labelLarge: AppTextStyles.labelLarge.copyWith(color: darkTextPrimary),
        labelMedium: AppTextStyles.labelMedium.copyWith(
          color: darkTextSecondary,
        ),
      ),

      // App Bar: slate-950 bg (Web: `bg-slate-900/60 backdrop-blur`)
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
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

      // Elevated Button: amber-400 bg (Web: `bg-amber-400 text-slate-950`)
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

      // Text Button: amber-400 text in dark mode
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // Progress Indicator
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

      // Outlined Button: slate-700 border (Web: `border-slate-700`)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkTextPrimary,
          minimumSize: const Size(double.infinity, AppDimens.minTouchTarget),
          side: const BorderSide(
            color: AppColors.darkOutline, // slate-700
            width: 1.5,
          ),
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

      // Input Decoration: slate-900 fill, slate-700 border
      // Web: `bg-slate-950/70 border-slate-700/80 focus:border-amber-400`
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppDimens.space16,
          vertical: AppDimens.space16,
        ),
        hintStyle: TextStyle(
          color: AppColors.darkTextHint, // slate-500
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: AppDimens.borderMedium,
          borderSide: BorderSide(color: AppColors.darkOutline), // slate-700
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimens.borderMedium,
          borderSide: BorderSide(color: darkBorder), // slate-800
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimens.borderMedium,
          borderSide: BorderSide(
            color: AppColors.primary, // amber-400 focus ring
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDimens.borderMedium,
          borderSide: BorderSide(color: AppColors.error),
        ),
      ),

      // Card: slate-900 bg, slate-800 border
      // Web: `bg-slate-900/80 border border-slate-800 rounded-2xl`
      cardTheme: const CardThemeData(
        color: darkSurface,
        elevation: AppDimens.elevationNone,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimens.borderLarge,
          side: BorderSide(color: darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Divider: slate-800
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
        space: 1,
      ),

      // Dialog: slate-900 bg
      dialogTheme: const DialogThemeData(
        backgroundColor: darkSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: AppDimens.borderLarge),
      ),

      // Bottom Sheet: slate-900 bg
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        modalBackgroundColor: darkSurface,
      ),

      // Navigation Bar (bottom nav): slate-900 bg, amber-400 selected
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary);
          }
          return const IconThemeData(color: AppColors.darkTextSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            color: AppColors.darkTextSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
      ),

      // Chip Theme: matches Web filter pills
      // Web: `bg-slate-800/80 text-slate-300 border border-slate-700/60`
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        selectedColor: AppColors.primary,
        side: BorderSide(color: AppColors.darkOutline, width: 0.5),
        labelStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppDimens.borderMedium),
      ),
    );
  }
}
