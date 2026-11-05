import 'package:flutter/material.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

/// Lab 2 tokens from packages/core → ThemeData of the wide-screen web admin.
/// Screens read colours, text styles and spacing from here or the tokens, never hex values.
ThemeData buildAdminTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimary,
    secondary: AppColors.accentNeutral,
    tertiary: AppColors.accentNeutral,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    surfaceContainerHighest: AppColors.surfaceVariant,
    error: AppColors.error,
    onError: AppColors.textOnDark,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    outline: AppColors.outline,
    outlineVariant: AppColors.divider,
  );

  final textTheme = TextTheme(
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
    labelSmall: AppTextStyles.caption,
  );

  const fieldBorder = OutlineInputBorder(
    borderRadius: AppDimens.borderMedium,
    borderSide: BorderSide(color: AppColors.outline),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    dividerColor: AppColors.divider,
    textTheme: textTheme,
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      elevation: AppDimens.elevationNone,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppDimens.borderLarge,
        side: BorderSide(color: AppColors.border),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      space: 1,
      thickness: 1,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primary,
      selectedIconTheme: const IconThemeData(color: AppColors.onPrimary),
      unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary),
      selectedLabelTextStyle: AppTextStyles.labelLarge,
      unselectedLabelTextStyle: AppTextStyles.labelLarge.copyWith(
        color: AppColors.textSecondary,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primary,
      labelTextStyle: WidgetStatePropertyAll(AppTextStyles.labelMedium),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space16,
        vertical: AppDimens.space12,
      ),
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: const OutlineInputBorder(
        borderRadius: AppDimens.borderMedium,
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: AppDimens.borderMedium,
        borderSide: BorderSide(color: AppColors.error),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primaryContainer,
      checkmarkColor: AppColors.onPrimary,
      side: const BorderSide(color: AppColors.outline),
      labelStyle: AppTextStyles.labelLarge,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space8),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppDimens.borderXLarge),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      width: 560,
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textOnDark,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        minimumSize: const Size(0, AppDimens.minTouchTarget),
        textStyle: AppTextStyles.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(
          AppDimens.minTouchTarget,
          AppDimens.minTouchTarget,
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primary
            : AppColors.surfaceVariant,
      ),
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.onPrimary
            : AppColors.textHint,
      ),
    ),
  );
}
