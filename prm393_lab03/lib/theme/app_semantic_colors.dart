import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Colours by purpose. Light values preserve the pre-migration UI exactly.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color linkedAccountAccent;
  final Color linkedAccountText;
  final Color inputEnabledBorder;
  final Color cardSurface;
  final Color cardBorder;
  final Color mutedSurface;
  final Color background;
  final Color divider;
  final Color inputBorder;
  final Color textPrimary;
  final Color textBody;
  final Color textSecondary;
  final Color hint;
  final Color accent;
  final Color navInactive;
  final Color emphasis;
  final Color primaryContainer;
  final Color primaryContainerBorder;
  final Color onPrimaryContainer;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color infoContainer;
  final Color onInfoContainer;
  final Color infoText;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color aiContainer;
  final Color onAiContainer;
  final Color aiAccent;
  final Color success;
  final Color error;
  final Color info;
  final Color warning;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color chartLine;
  final Color chartBand;
  final Color chartLowest;
  final Color selectedChip;
  final Color onSelectedChip;
  final Color aiBody;
  final Color mutedText;
  final Color snackbarSuccess;
  final Color onSnackbarSuccess;
  final Color shopeeBrand;
  final Color lazadaBrand;
  final Color shopeeButton;
  final Color lazadaButton;
  final Color onBrandButton;
  final Color savingsText;
  final Color budgetActionBorder;
  final Color onboardingGradientStart;
  final Color onboardingGradientEnd;
  final Color illustrationSurface;
  final Color illustrationInset;
  final Color illustrationBadge;
  final Color illustrationBadgeBorder;
  final Color onboardingBorder;
  final Color comparisonSurface;
  final Color comparisonHint;
  final Color switchTrack;
  final Color secondaryActionBorder;
  final Color secondaryActionText;
  final Color subtleText;
  final Color appBarSurface;
  final Color budgetCardShadow;
  final Color summaryCardShadow;
  final Color illustrationShadow;
  final Color illustrationBadgeShadow;
  final Color budgetCardShadow5;
  final Color previewShadow;
  final Color segmentShadow;

  final Color statusOverlay;

  final Color insightOverlay;

  final Color brandShadow;

  final Color photoStatusContainer;

  final Color onStatusFill;

  final Color notificationBadge;

  final Color onNotificationBadge;

  final Color brandText;

  final Color slotMorning;

  final Color slotNoon;

  final Color slotEvening;

  final Color slotNight;

  final Color chartStrong;

  final Color statusNeutral;

  final Color captionText;

  final Color chartGuide;

  final Color chartSelection;

  const AppSemanticColors({
    required this.linkedAccountAccent,
    required this.linkedAccountText,
    required this.chartSelection,
    required this.chartGuide,
    required this.captionText,
    required this.inputEnabledBorder,
    required this.statusNeutral,
    required this.chartStrong,
    required this.slotNight,
    required this.slotEvening,
    required this.slotNoon,
    required this.slotMorning,
    required this.brandText,
    required this.onNotificationBadge,
    required this.notificationBadge,
    required this.onStatusFill,
    required this.photoStatusContainer,
    required this.brandShadow,
    required this.insightOverlay,
    required this.statusOverlay,
    required this.cardSurface,
    required this.cardBorder,
    required this.mutedSurface,
    required this.background,
    required this.divider,
    required this.inputBorder,
    required this.textPrimary,
    required this.textBody,
    required this.textSecondary,
    required this.hint,
    required this.accent,
    required this.navInactive,
    required this.emphasis,
    required this.primaryContainer,
    required this.primaryContainerBorder,
    required this.onPrimaryContainer,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.infoText,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.aiContainer,
    required this.onAiContainer,
    required this.aiAccent,
    required this.success,
    required this.error,
    required this.info,
    required this.warning,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.chartLine,
    required this.chartBand,
    required this.chartLowest,
    required this.selectedChip,
    required this.onSelectedChip,
    required this.aiBody,
    required this.mutedText,
    required this.snackbarSuccess,
    required this.onSnackbarSuccess,
    required this.shopeeBrand,
    required this.lazadaBrand,
    required this.shopeeButton,
    required this.lazadaButton,
    required this.onBrandButton,
    required this.savingsText,
    required this.budgetActionBorder,
    required this.onboardingGradientStart,
    required this.onboardingGradientEnd,
    required this.illustrationSurface,
    required this.illustrationInset,
    required this.illustrationBadge,
    required this.illustrationBadgeBorder,
    required this.onboardingBorder,
    required this.comparisonSurface,
    required this.comparisonHint,
    required this.switchTrack,
    required this.secondaryActionBorder,
    required this.secondaryActionText,
    required this.subtleText,
    required this.appBarSurface,
    required this.budgetCardShadow,
    required this.summaryCardShadow,
    required this.illustrationShadow,
    required this.illustrationBadgeShadow,
    required this.budgetCardShadow5,
    required this.previewShadow,
    required this.segmentShadow,
  });

  static final light = AppSemanticColors(
    linkedAccountAccent: Colors.green,
    linkedAccountText: Colors.green.shade800,
    chartSelection: AppColors.textPrimary.withValues(alpha: 0.35),
    chartGuide: AppColors.textSecondary.withValues(alpha: 0.5),
    captionText: AppColors.textSecondary.withValues(alpha: 0.8),
    inputEnabledBorder: AppColors.divider,
    statusNeutral: AppColors.accentNeutral,
    chartStrong: AppColors.chartStrong,
    slotNight: AppColors.slotNight,
    slotEvening: AppColors.slotEvening,
    slotNoon: AppColors.slotNoon,
    slotMorning: AppColors.slotMorning,
    brandText: AppColors.primary,
    onNotificationBadge: AppColors.textOnDark,
    notificationBadge: AppColors.error,
    onStatusFill: AppColors.textOnDark,
    photoStatusContainer: AppColors.successContainer,
    brandShadow: Colors.black.withValues(alpha: 0.05),
    insightOverlay: Colors.black.withValues(alpha: 0.1),
    statusOverlay: Colors.black.withValues(alpha: 0.1),
    cardSurface: AppColors.surface,
    cardBorder: AppColors.border,
    mutedSurface: AppColors.surfaceVariant,
    background: AppColors.background,
    divider: AppColors.divider,
    inputBorder: AppColors.outline,
    textPrimary: AppColors.textPrimary,
    textBody: AppColors.textBody,
    textSecondary: AppColors.textSecondary,
    hint: AppColors.textHint,
    accent: AppColors.accentNeutral,
    navInactive: AppColors.navInactive,
    emphasis: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    primaryContainerBorder: AppColors.primary.withValues(alpha: 0.5),
    onPrimaryContainer: AppColors.onPrimary,
    successContainer: AppColors.successContainer,
    onSuccessContainer: AppColors.onSuccessContainer,
    infoContainer: AppColors.infoContainer,
    onInfoContainer: AppColors.onInfoContainer,
    infoText: AppColors.infoText,
    warningContainer: const Color(0xFFFEF3C7),
    onWarningContainer: const Color(0xFF92400E),
    aiContainer: AppColors.aiContainer,
    onAiContainer: AppColors.onAiContainer,
    aiAccent: AppColors.aiAccent,
    success: AppColors.success,
    error: AppColors.error,
    info: AppColors.info,
    warning: AppColors.warning,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    chartLine: AppColors.purple,
    chartBand: AppColors.purple.withValues(alpha: 0.2),
    chartLowest: AppColors.onSuccessContainer,
    selectedChip: AppColors.onPrimary,
    onSelectedChip: AppColors.textOnDark,
    aiBody: AppColors.textBody,
    mutedText: AppColors.accentNeutral,
    snackbarSuccess: AppColors.success,
    onSnackbarSuccess: AppColors.textOnDark,
    shopeeBrand: const Color(0xFFEE4D2D),
    lazadaBrand: const Color(0xFF0F146D),
    shopeeButton: const Color(0xFFEE4D2D),
    lazadaButton: const Color(0xFF0F146D),
    onBrandButton: AppColors.textOnDark,
    savingsText: const Color(0xFF047857),
    budgetActionBorder: const Color(0xFFEAB308),
    onboardingGradientStart: const Color(0xFFFFF3B0),
    onboardingGradientEnd: const Color(0xFFF1F6F2),
    illustrationSurface: AppColors.surface,
    illustrationInset: const Color(0xFFE8F1ED),
    illustrationBadge: const Color(0xFF263B1E),
    illustrationBadgeBorder: const Color(0xFFE6F1EC),
    onboardingBorder: const Color(0xFFE8EDF2),
    comparisonSurface: AppColors.onPrimary,
    comparisonHint: const Color(0xFF94A3B8),
    switchTrack: AppColors.onPrimary,
    secondaryActionBorder: AppColors.outline,
    secondaryActionText: AppColors.textSecondary,
    subtleText: AppColors.textSecondary.withValues(alpha: 0.7),
    appBarSurface: AppColors.surface,
    budgetCardShadow: Colors.black.withValues(alpha: 0.03),
    summaryCardShadow: Colors.black.withValues(alpha: 0.02),
    illustrationShadow: Colors.black.withValues(alpha: 0.08),
    illustrationBadgeShadow: Colors.black.withValues(alpha: 0.1),
    budgetCardShadow5: Colors.black.withValues(alpha: 0.035),
    previewShadow: Colors.black.withValues(alpha: 0.04),
    segmentShadow: Colors.black.withValues(alpha: 0.06),
  );

  static final dark = AppSemanticColors(
    linkedAccountAccent: AppColors.darkOnSuccessContainer,
    linkedAccountText: AppColors.darkOnSuccessContainer,
    chartSelection: AppColors.darkOutline,
    chartGuide: AppColors.darkOutline,
    captionText: AppColors.darkTextSecondary,
    inputEnabledBorder: AppColors.darkOutline,
    statusNeutral: AppColors.darkTextSecondary,
    chartStrong: AppColors.darkTextBody,
    slotNight: const Color(0xFFBCBFFF),
    slotEvening: AppColors.darkPrimaryText,
    slotNoon: AppColors.darkOnSuccessContainer,
    slotMorning: AppColors.darkOnInfoContainer,
    brandText: AppColors.darkPrimaryText,
    onNotificationBadge: AppColors.darkOnErrorContainer,
    notificationBadge: AppColors.darkErrorContainer,
    onStatusFill: AppColors.onPrimary,
    photoStatusContainer: AppColors.darkSurfaceMuted,
    brandShadow: Colors.black.withValues(alpha: 0.08),
    insightOverlay: Colors.black.withValues(alpha: 0.2),
    statusOverlay: Colors.black.withValues(alpha: 0.15),
    cardSurface: AppColors.darkSurface,
    cardBorder: AppColors.darkBorder,
    mutedSurface: AppColors.darkSurfaceMuted,
    background: AppColors.darkBackground,
    divider: AppColors.darkBorder,
    inputBorder: AppColors.darkOutline,
    textPrimary: AppColors.darkTextPrimary,
    textBody: AppColors.darkTextBody,
    textSecondary: AppColors.darkTextSecondary,
    hint: AppColors.darkTextHint,
    accent: AppColors.darkAccentNeutral,
    navInactive: AppColors.darkNavInactive,
    emphasis: AppColors.darkPrimaryText,
    primaryContainer: AppColors.darkPrimaryContainer,
    primaryContainerBorder: AppColors.darkPrimaryContainerOutline,
    onPrimaryContainer: AppColors.darkPrimaryContainerText,
    successContainer: AppColors.darkSuccessContainer,
    onSuccessContainer: AppColors.darkOnSuccessContainer,
    infoContainer: AppColors.darkInfoContainer,
    onInfoContainer: AppColors.darkOnInfoContainer,
    infoText: AppColors.infoLight,
    warningContainer: const Color(0xFF45320C),
    onWarningContainer: const Color(0xFFFCD68A),
    aiContainer: AppColors.darkPrimaryContainer,
    onAiContainer: AppColors.darkPrimaryContainerText,
    aiAccent: AppColors.darkPrimaryText,
    success: AppColors.darkOnSuccessContainer,
    error: AppColors.darkOnErrorContainer,
    info: AppColors.infoLight,
    warning: const Color(0xFFFCD68A),
    errorContainer: AppColors.darkErrorContainer,
    onErrorContainer: AppColors.darkOnErrorContainer,
    chartLine: AppColors.purpleLight,
    chartBand: AppColors.purpleLight.withValues(alpha: 0.2),
    chartLowest: AppColors.successLight,
    selectedChip: AppColors.primary,
    onSelectedChip: AppColors.onPrimary,
    aiBody: AppColors.darkPrimaryContainerText,
    mutedText: AppColors.darkTextBody,
    snackbarSuccess: AppColors.darkSuccessContainer,
    onSnackbarSuccess: AppColors.darkOnSuccessContainer,
    shopeeBrand: const Color(0xFFFFAA93),
    lazadaBrand: const Color(0xFFBCBFFF),
    shopeeButton: const Color(0xFFEE4D2D),
    lazadaButton: const Color(0xFF0F146D),
    onBrandButton: AppColors.onPrimary,
    savingsText: AppColors.darkOnSuccessContainer,
    budgetActionBorder: AppColors.darkBorder,
    onboardingGradientStart: AppColors.darkPrimaryContainer,
    onboardingGradientEnd: AppColors.darkSurface,
    illustrationSurface: AppColors.darkSurfaceMuted,
    illustrationInset: const Color(0xFF263B31),
    illustrationBadge: AppColors.primary,
    illustrationBadgeBorder: AppColors.darkSurfaceMuted,
    onboardingBorder: AppColors.darkBorder,
    comparisonSurface: AppColors.darkSurfaceMuted,
    comparisonHint: AppColors.darkTextSecondary,
    switchTrack: AppColors.darkPrimaryContainerOutline,
    secondaryActionBorder: AppColors.darkOutline,
    secondaryActionText: AppColors.darkTextBody,
    subtleText: AppColors.darkTextSecondary,
    appBarSurface: AppColors.darkBackground,
    budgetCardShadow: Colors.black.withValues(alpha: 0.2),
    summaryCardShadow: Colors.black.withValues(alpha: 0.2),
    illustrationShadow: Colors.black.withValues(alpha: 0.3),
    illustrationBadgeShadow: Colors.black.withValues(alpha: 0.2),
    budgetCardShadow5: Colors.black.withValues(alpha: 0.16),
    previewShadow: Colors.black.withValues(alpha: 0.3),
    segmentShadow: Colors.black.withValues(alpha: 0.3),
  );

  static AppSemanticColors of(BuildContext context) =>
      fromTheme(Theme.of(context));

  static AppSemanticColors fromTheme(ThemeData theme) =>
      theme.extension<AppSemanticColors>() ??
      (theme.brightness == Brightness.dark ? dark : light);

  @override
  AppSemanticColors copyWith({
    Color? linkedAccountAccent,
    Color? linkedAccountText,
    Color? chartSelection,
    Color? chartGuide,
    Color? captionText,
    Color? inputEnabledBorder,
    Color? statusNeutral,
    Color? chartStrong,
    Color? slotNight,
    Color? slotEvening,
    Color? slotNoon,
    Color? slotMorning,
    Color? brandText,
    Color? onNotificationBadge,
    Color? notificationBadge,
    Color? onStatusFill,
    Color? photoStatusContainer,
    Color? brandShadow,
    Color? insightOverlay,
    Color? statusOverlay,
    Color? cardSurface,
    Color? cardBorder,
    Color? mutedSurface,
    Color? background,
    Color? divider,
    Color? inputBorder,
    Color? textPrimary,
    Color? textBody,
    Color? textSecondary,
    Color? hint,
    Color? accent,
    Color? navInactive,
    Color? emphasis,
    Color? primaryContainer,
    Color? primaryContainerBorder,
    Color? onPrimaryContainer,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? infoText,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? aiContainer,
    Color? onAiContainer,
    Color? aiAccent,
    Color? success,
    Color? error,
    Color? info,
    Color? warning,
    Color? errorContainer,
    Color? onErrorContainer,
    Color? chartLine,
    Color? chartBand,
    Color? chartLowest,
    Color? selectedChip,
    Color? onSelectedChip,
    Color? aiBody,
    Color? mutedText,
    Color? snackbarSuccess,
    Color? onSnackbarSuccess,
    Color? shopeeBrand,
    Color? lazadaBrand,
    Color? shopeeButton,
    Color? lazadaButton,
    Color? onBrandButton,
    Color? savingsText,
    Color? budgetActionBorder,
    Color? onboardingGradientStart,
    Color? onboardingGradientEnd,
    Color? illustrationSurface,
    Color? illustrationInset,
    Color? illustrationBadge,
    Color? illustrationBadgeBorder,
    Color? onboardingBorder,
    Color? comparisonSurface,
    Color? comparisonHint,
    Color? switchTrack,
    Color? secondaryActionBorder,
    Color? secondaryActionText,
    Color? subtleText,
    Color? appBarSurface,
    Color? budgetCardShadow,
    Color? summaryCardShadow,
    Color? illustrationShadow,
    Color? illustrationBadgeShadow,
    Color? budgetCardShadow5,
    Color? previewShadow,
    Color? segmentShadow,
  }) => AppSemanticColors(
    linkedAccountAccent: linkedAccountAccent ?? this.linkedAccountAccent,
    linkedAccountText: linkedAccountText ?? this.linkedAccountText,
    chartSelection: chartSelection ?? this.chartSelection,
    chartGuide: chartGuide ?? this.chartGuide,
    captionText: captionText ?? this.captionText,
    inputEnabledBorder: inputEnabledBorder ?? this.inputEnabledBorder,
    statusNeutral: statusNeutral ?? this.statusNeutral,
    chartStrong: chartStrong ?? this.chartStrong,
    slotNight: slotNight ?? this.slotNight,
    slotEvening: slotEvening ?? this.slotEvening,
    slotNoon: slotNoon ?? this.slotNoon,
    slotMorning: slotMorning ?? this.slotMorning,
    brandText: brandText ?? this.brandText,
    onNotificationBadge: onNotificationBadge ?? this.onNotificationBadge,
    notificationBadge: notificationBadge ?? this.notificationBadge,
    onStatusFill: onStatusFill ?? this.onStatusFill,
    photoStatusContainer: photoStatusContainer ?? this.photoStatusContainer,
    brandShadow: brandShadow ?? this.brandShadow,
    insightOverlay: insightOverlay ?? this.insightOverlay,
    statusOverlay: statusOverlay ?? this.statusOverlay,
    cardSurface: cardSurface ?? this.cardSurface,
    cardBorder: cardBorder ?? this.cardBorder,
    mutedSurface: mutedSurface ?? this.mutedSurface,
    background: background ?? this.background,
    divider: divider ?? this.divider,
    inputBorder: inputBorder ?? this.inputBorder,
    textPrimary: textPrimary ?? this.textPrimary,
    textBody: textBody ?? this.textBody,
    textSecondary: textSecondary ?? this.textSecondary,
    hint: hint ?? this.hint,
    accent: accent ?? this.accent,
    navInactive: navInactive ?? this.navInactive,
    emphasis: emphasis ?? this.emphasis,
    primaryContainer: primaryContainer ?? this.primaryContainer,
    primaryContainerBorder:
        primaryContainerBorder ?? this.primaryContainerBorder,
    onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
    successContainer: successContainer ?? this.successContainer,
    onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
    infoContainer: infoContainer ?? this.infoContainer,
    onInfoContainer: onInfoContainer ?? this.onInfoContainer,
    infoText: infoText ?? this.infoText,
    warningContainer: warningContainer ?? this.warningContainer,
    onWarningContainer: onWarningContainer ?? this.onWarningContainer,
    aiContainer: aiContainer ?? this.aiContainer,
    onAiContainer: onAiContainer ?? this.onAiContainer,
    aiAccent: aiAccent ?? this.aiAccent,
    success: success ?? this.success,
    error: error ?? this.error,
    info: info ?? this.info,
    warning: warning ?? this.warning,
    errorContainer: errorContainer ?? this.errorContainer,
    onErrorContainer: onErrorContainer ?? this.onErrorContainer,
    chartLine: chartLine ?? this.chartLine,
    chartBand: chartBand ?? this.chartBand,
    chartLowest: chartLowest ?? this.chartLowest,
    selectedChip: selectedChip ?? this.selectedChip,
    onSelectedChip: onSelectedChip ?? this.onSelectedChip,
    aiBody: aiBody ?? this.aiBody,
    mutedText: mutedText ?? this.mutedText,
    snackbarSuccess: snackbarSuccess ?? this.snackbarSuccess,
    onSnackbarSuccess: onSnackbarSuccess ?? this.onSnackbarSuccess,
    shopeeBrand: shopeeBrand ?? this.shopeeBrand,
    lazadaBrand: lazadaBrand ?? this.lazadaBrand,
    shopeeButton: shopeeButton ?? this.shopeeButton,
    lazadaButton: lazadaButton ?? this.lazadaButton,
    onBrandButton: onBrandButton ?? this.onBrandButton,
    savingsText: savingsText ?? this.savingsText,
    budgetActionBorder: budgetActionBorder ?? this.budgetActionBorder,
    onboardingGradientStart:
        onboardingGradientStart ?? this.onboardingGradientStart,
    onboardingGradientEnd: onboardingGradientEnd ?? this.onboardingGradientEnd,
    illustrationSurface: illustrationSurface ?? this.illustrationSurface,
    illustrationInset: illustrationInset ?? this.illustrationInset,
    illustrationBadge: illustrationBadge ?? this.illustrationBadge,
    illustrationBadgeBorder:
        illustrationBadgeBorder ?? this.illustrationBadgeBorder,
    onboardingBorder: onboardingBorder ?? this.onboardingBorder,
    comparisonSurface: comparisonSurface ?? this.comparisonSurface,
    comparisonHint: comparisonHint ?? this.comparisonHint,
    switchTrack: switchTrack ?? this.switchTrack,
    secondaryActionBorder: secondaryActionBorder ?? this.secondaryActionBorder,
    secondaryActionText: secondaryActionText ?? this.secondaryActionText,
    subtleText: subtleText ?? this.subtleText,
    appBarSurface: appBarSurface ?? this.appBarSurface,
    budgetCardShadow: budgetCardShadow ?? this.budgetCardShadow,
    summaryCardShadow: summaryCardShadow ?? this.summaryCardShadow,
    illustrationShadow: illustrationShadow ?? this.illustrationShadow,
    illustrationBadgeShadow:
        illustrationBadgeShadow ?? this.illustrationBadgeShadow,
    budgetCardShadow5: budgetCardShadow5 ?? this.budgetCardShadow5,
    previewShadow: previewShadow ?? this.previewShadow,
    segmentShadow: segmentShadow ?? this.segmentShadow,
  );

  @override
  AppSemanticColors lerp(covariant AppSemanticColors? other, double t) {
    if (other == null) return this;
    return AppSemanticColors(
      linkedAccountAccent: Color.lerp(
        linkedAccountAccent,
        other.linkedAccountAccent,
        t,
      )!,
      linkedAccountText: Color.lerp(
        linkedAccountText,
        other.linkedAccountText,
        t,
      )!,
      chartSelection: Color.lerp(chartSelection, other.chartSelection, t)!,
      chartGuide: Color.lerp(chartGuide, other.chartGuide, t)!,
      captionText: Color.lerp(captionText, other.captionText, t)!,
      inputEnabledBorder: Color.lerp(
        inputEnabledBorder,
        other.inputEnabledBorder,
        t,
      )!,
      statusNeutral: Color.lerp(statusNeutral, other.statusNeutral, t)!,
      chartStrong: Color.lerp(chartStrong, other.chartStrong, t)!,
      slotNight: Color.lerp(slotNight, other.slotNight, t)!,
      slotEvening: Color.lerp(slotEvening, other.slotEvening, t)!,
      slotNoon: Color.lerp(slotNoon, other.slotNoon, t)!,
      slotMorning: Color.lerp(slotMorning, other.slotMorning, t)!,
      brandText: Color.lerp(brandText, other.brandText, t)!,
      onNotificationBadge: Color.lerp(
        onNotificationBadge,
        other.onNotificationBadge,
        t,
      )!,
      notificationBadge: Color.lerp(
        notificationBadge,
        other.notificationBadge,
        t,
      )!,
      onStatusFill: Color.lerp(onStatusFill, other.onStatusFill, t)!,
      photoStatusContainer: Color.lerp(
        photoStatusContainer,
        other.photoStatusContainer,
        t,
      )!,
      brandShadow: Color.lerp(brandShadow, other.brandShadow, t)!,
      insightOverlay: Color.lerp(insightOverlay, other.insightOverlay, t)!,
      statusOverlay: Color.lerp(statusOverlay, other.statusOverlay, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      mutedSurface: Color.lerp(mutedSurface, other.mutedSurface, t)!,
      background: Color.lerp(background, other.background, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textBody: Color.lerp(textBody, other.textBody, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      hint: Color.lerp(hint, other.hint, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      navInactive: Color.lerp(navInactive, other.navInactive, t)!,
      emphasis: Color.lerp(emphasis, other.emphasis, t)!,
      primaryContainer: Color.lerp(
        primaryContainer,
        other.primaryContainer,
        t,
      )!,
      primaryContainerBorder: Color.lerp(
        primaryContainerBorder,
        other.primaryContainerBorder,
        t,
      )!,
      onPrimaryContainer: Color.lerp(
        onPrimaryContainer,
        other.onPrimaryContainer,
        t,
      )!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      infoText: Color.lerp(infoText, other.infoText, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      aiContainer: Color.lerp(aiContainer, other.aiContainer, t)!,
      onAiContainer: Color.lerp(onAiContainer, other.onAiContainer, t)!,
      aiAccent: Color.lerp(aiAccent, other.aiAccent, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
      onErrorContainer: Color.lerp(
        onErrorContainer,
        other.onErrorContainer,
        t,
      )!,
      chartLine: Color.lerp(chartLine, other.chartLine, t)!,
      chartBand: Color.lerp(chartBand, other.chartBand, t)!,
      chartLowest: Color.lerp(chartLowest, other.chartLowest, t)!,
      selectedChip: Color.lerp(selectedChip, other.selectedChip, t)!,
      onSelectedChip: Color.lerp(onSelectedChip, other.onSelectedChip, t)!,
      aiBody: Color.lerp(aiBody, other.aiBody, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      snackbarSuccess: Color.lerp(snackbarSuccess, other.snackbarSuccess, t)!,
      onSnackbarSuccess: Color.lerp(
        onSnackbarSuccess,
        other.onSnackbarSuccess,
        t,
      )!,
      shopeeBrand: Color.lerp(shopeeBrand, other.shopeeBrand, t)!,
      lazadaBrand: Color.lerp(lazadaBrand, other.lazadaBrand, t)!,
      shopeeButton: Color.lerp(shopeeButton, other.shopeeButton, t)!,
      lazadaButton: Color.lerp(lazadaButton, other.lazadaButton, t)!,
      onBrandButton: Color.lerp(onBrandButton, other.onBrandButton, t)!,
      savingsText: Color.lerp(savingsText, other.savingsText, t)!,
      budgetActionBorder: Color.lerp(
        budgetActionBorder,
        other.budgetActionBorder,
        t,
      )!,
      onboardingGradientStart: Color.lerp(
        onboardingGradientStart,
        other.onboardingGradientStart,
        t,
      )!,
      onboardingGradientEnd: Color.lerp(
        onboardingGradientEnd,
        other.onboardingGradientEnd,
        t,
      )!,
      illustrationSurface: Color.lerp(
        illustrationSurface,
        other.illustrationSurface,
        t,
      )!,
      illustrationInset: Color.lerp(
        illustrationInset,
        other.illustrationInset,
        t,
      )!,
      illustrationBadge: Color.lerp(
        illustrationBadge,
        other.illustrationBadge,
        t,
      )!,
      illustrationBadgeBorder: Color.lerp(
        illustrationBadgeBorder,
        other.illustrationBadgeBorder,
        t,
      )!,
      onboardingBorder: Color.lerp(
        onboardingBorder,
        other.onboardingBorder,
        t,
      )!,
      comparisonSurface: Color.lerp(
        comparisonSurface,
        other.comparisonSurface,
        t,
      )!,
      comparisonHint: Color.lerp(comparisonHint, other.comparisonHint, t)!,
      switchTrack: Color.lerp(switchTrack, other.switchTrack, t)!,
      secondaryActionBorder: Color.lerp(
        secondaryActionBorder,
        other.secondaryActionBorder,
        t,
      )!,
      secondaryActionText: Color.lerp(
        secondaryActionText,
        other.secondaryActionText,
        t,
      )!,
      subtleText: Color.lerp(subtleText, other.subtleText, t)!,
      appBarSurface: Color.lerp(appBarSurface, other.appBarSurface, t)!,
      budgetCardShadow: Color.lerp(
        budgetCardShadow,
        other.budgetCardShadow,
        t,
      )!,
      summaryCardShadow: Color.lerp(
        summaryCardShadow,
        other.summaryCardShadow,
        t,
      )!,
      illustrationShadow: Color.lerp(
        illustrationShadow,
        other.illustrationShadow,
        t,
      )!,
      illustrationBadgeShadow: Color.lerp(
        illustrationBadgeShadow,
        other.illustrationBadgeShadow,
        t,
      )!,
      budgetCardShadow5: Color.lerp(
        budgetCardShadow5,
        other.budgetCardShadow5,
        t,
      )!,
      previewShadow: Color.lerp(previewShadow, other.previewShadow, t)!,
      segmentShadow: Color.lerp(segmentShadow, other.segmentShadow, t)!,
    );
  }
}
