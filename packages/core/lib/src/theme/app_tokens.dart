import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The design tokens for the current brightness: the light tokens exactly as
/// they are, or their `dark*` counterparts from [AppColors] in a dark theme.
/// Widgets shared by the app and the web admin read colours through this, so
/// one component works in both modes.
class AppTokens {
  final bool isDark;

  const AppTokens._(this.isDark);

  factory AppTokens.of(BuildContext context) =>
      AppTokens._(Theme.of(context).brightness == Brightness.dark);

  Color get background =>
      isDark ? AppColors.darkBackground : AppColors.background;
  Color get surface => isDark ? AppColors.darkCardSurface : AppColors.surface;
  Color get surfaceMuted =>
      isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceVariant;
  Color get divider => isDark ? AppColors.darkBorder : AppColors.divider;
  Color get outline => isDark ? AppColors.darkOutline : AppColors.outline;

  Color get textPrimary =>
      isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color get textBody => isDark ? AppColors.darkTextBody : AppColors.textBody;
  Color get textSecondary =>
      isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get textHint => isDark ? AppColors.darkTextHint : AppColors.textHint;

  Color get primaryContainer =>
      isDark ? AppColors.darkPrimaryContainer : AppColors.primaryContainer;
  Color get onPrimaryContainer =>
      isDark ? AppColors.darkPrimaryContainerText : AppColors.onPrimary;

  Color get successContainer =>
      isDark ? AppColors.darkSuccessContainer : AppColors.successContainer;
  Color get onSuccessContainer =>
      isDark ? AppColors.darkOnSuccessContainer : AppColors.onSuccessContainer;
  Color get errorContainer =>
      isDark ? AppColors.darkErrorContainer : AppColors.errorContainer;
  Color get onErrorContainer =>
      isDark ? AppColors.darkOnErrorContainer : AppColors.onErrorContainer;
  Color get infoContainer =>
      isDark ? AppColors.darkInfoContainer : AppColors.infoContainer;
  Color get onInfoContainer =>
      isDark ? AppColors.darkOnInfoContainer : AppColors.onInfoContainer;
  Color get warningContainer =>
      isDark ? AppColors.darkPrimaryContainer : AppColors.aiContainer;
  Color get onWarningContainer =>
      isDark ? AppColors.darkPrimaryContainerText : AppColors.onAiContainer;

  /// An [AppTextStyles] style recoloured for this brightness (light: unchanged)
  TextStyle text(TextStyle style) {
    if (!isDark) return style;
    final secondary = style.color == AppColors.textSecondary;
    return style.copyWith(
      color: secondary
          ? AppColors.darkTextSecondary
          : AppColors.darkTextPrimary,
    );
  }
}
