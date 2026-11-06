import 'package:flutter/material.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

/// Lab 2 tokens from packages/core → ThemeData of the wide-screen web admin,
/// light or dark (the dark values are the `dark*` tokens of [AppColors]).
/// Screens read colours, text styles and spacing from here or [AppTokens].
ThemeData buildAdminTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final surface = dark ? AppColors.darkCardSurface : AppColors.surface;
  final background = dark ? AppColors.darkBackground : AppColors.background;
  final textPrimary = dark ? AppColors.darkTextPrimary : AppColors.textPrimary;
  final textSecondary = dark
      ? AppColors.darkTextSecondary
      : AppColors.textSecondary;
  final divider = dark ? AppColors.darkBorder : AppColors.divider;
  final outline = dark ? AppColors.darkOutline : AppColors.outline;
  final muted = dark ? AppColors.darkSurfaceMuted : AppColors.surfaceVariant;

  TextStyle recolor(TextStyle s) => dark
      ? s.copyWith(
          color: s.color == AppColors.textSecondary
              ? AppColors.darkTextSecondary
              : AppColors.darkTextPrimary,
        )
      : s;

  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
      ).copyWith(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: dark
            ? AppColors.darkPrimaryContainer
            : AppColors.primaryContainer,
        onPrimaryContainer: dark
            ? AppColors.darkPrimaryContainerText
            : AppColors.onPrimary,
        secondary: dark ? AppColors.darkAccentNeutral : AppColors.accentNeutral,
        tertiary: dark ? AppColors.darkAccentNeutral : AppColors.accentNeutral,
        surface: surface,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        surfaceContainerHighest: muted,
        error: AppColors.error,
        onError: AppColors.textOnDark,
        outline: outline,
        outlineVariant: divider,
      );

  final textTheme = TextTheme(
    displayLarge: recolor(AppTextStyles.displayLarge),
    displayMedium: recolor(AppTextStyles.displayMedium),
    headlineLarge: recolor(AppTextStyles.headlineLarge),
    headlineMedium: recolor(AppTextStyles.headlineMedium),
    titleLarge: recolor(AppTextStyles.titleLarge),
    titleMedium: recolor(AppTextStyles.titleMedium),
    bodyLarge: recolor(AppTextStyles.bodyLarge),
    bodyMedium: recolor(AppTextStyles.bodyMedium),
    labelLarge: recolor(AppTextStyles.labelLarge),
    labelMedium: recolor(AppTextStyles.labelMedium),
    labelSmall: recolor(AppTextStyles.caption),
  );

  final fieldBorder = OutlineInputBorder(
    borderRadius: AppDimens.borderMedium,
    borderSide: BorderSide(color: outline),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    canvasColor: surface,
    dividerColor: divider,
    textTheme: textTheme,
    iconTheme: IconThemeData(color: textSecondary),
    cardTheme: CardThemeData(
      color: surface,
      elevation: AppDimens.elevationNone,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppDimens.borderLarge,
        side: BorderSide(color: divider),
      ),
    ),
    dividerTheme: DividerThemeData(color: divider, space: 1, thickness: 1),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: surface,
      indicatorColor: AppColors.primary,
      selectedIconTheme: const IconThemeData(color: AppColors.onPrimary),
      unselectedIconTheme: IconThemeData(color: textSecondary),
      selectedLabelTextStyle: textTheme.labelLarge,
      unselectedLabelTextStyle: textTheme.labelLarge?.copyWith(
        color: textSecondary,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: AppColors.primary,
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? AppColors.onPrimary
              : textSecondary,
        ),
      ),
      labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? AppColors.darkSurfaceMuted : AppColors.surface,
      hintStyle: AppTextStyles.bodyMedium.copyWith(
        color: dark ? AppColors.darkTextHint : AppColors.textHint,
      ),
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
      backgroundColor: surface,
      selectedColor: dark
          ? AppColors.darkPrimaryContainer
          : AppColors.primaryContainer,
      checkmarkColor: textPrimary,
      side: BorderSide(color: outline),
      labelStyle: textTheme.labelLarge,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space8),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(borderRadius: AppDimens.borderXLarge),
      titleTextStyle: textTheme.headlineMedium,
      contentTextStyle: textTheme.bodyMedium,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: surface,
      textStyle: textTheme.bodyLarge,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      width: 560,
      backgroundColor: dark
          ? AppColors.darkSurfaceVariant
          : AppColors.textPrimary,
      contentTextStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textOnDark,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: textPrimary,
        minimumSize: const Size(0, AppDimens.minTouchTarget),
        textStyle: AppTextStyles.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: textSecondary,
        minimumSize: const Size(
          AppDimens.minTouchTarget,
          AppDimens.minTouchTarget,
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? AppColors.primary : muted,
      ),
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.onPrimary
            : (dark ? AppColors.darkTextHint : AppColors.textHint),
      ),
    ),
  );
}
