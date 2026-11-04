import 'package:flutter/material.dart';

import '../models/buying_motive.dart';
import 'app_colors.dart';

/// Foreground + background pair for one buying motive
@immutable
class MotivePalette {
  final Color foreground;
  final Color background;

  const MotivePalette(this.foreground, this.background);

  MotivePalette lerp(MotivePalette other, double t) => MotivePalette(
    Color.lerp(foreground, other.foreground, t)!,
    Color.lerp(background, other.background, t)!,
  );
}

/// Single source of the 8 motive colors.
/// Synchronized with Admin Web Portal (`motiveDistributionData` in mockData.ts).
/// Widgets: `MotiveColors.of(context).of(motive)`; models read [MotiveColors.light].
@immutable
class MotiveColors extends ThemeExtension<MotiveColors> {
  final Map<BuyingMotive, MotivePalette> palettes;

  const MotiveColors(this.palettes);

  // ═══════════════════════════════════════════════════════════════════════════
  // LIGHT MODE — vibrant fg on pastel bg (Tailwind *-500 / *-100)
  // ═══════════════════════════════════════════════════════════════════════════
  static const light = MotiveColors({
    BuyingMotive.need: MotivePalette(
      AppColors.motiveNeed, // blue-500
      AppColors.motiveNeedBg, // blue-100
    ),
    BuyingMotive.want: MotivePalette(
      AppColors.motiveWant, // pink-500
      AppColors.motiveWantBg, // pink-100
    ),
    BuyingMotive.sale: MotivePalette(
      AppColors.motiveSale, // amber-500
      AppColors.motiveSaleBg, // amber-100
    ),
    BuyingMotive.emotion: MotivePalette(
      AppColors.motiveEmotion, // purple-500
      AppColors.motiveEmotionBg, // purple-100
    ),
    BuyingMotive.social: MotivePalette(
      AppColors.motiveSocial, // sky-500
      AppColors.motiveSocialBg, // sky-100
    ),
    BuyingMotive.convenience: MotivePalette(
      AppColors.motiveConvenience, // teal-500
      AppColors.motiveConvenienceBg, // teal-100
    ),
    BuyingMotive.ads: MotivePalette(
      AppColors.motiveAds, // blue-600
      AppColors.motiveAdsBg, // blue-100
    ),
    BuyingMotive.other: MotivePalette(
      AppColors.motiveOther, // slate-500
      AppColors.motiveOtherBg, // slate-100
    ),
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // DARK MODE — lighter/luminous fg on deep-hued bg
  // Matches Web admin pie chart colors on slate-950 background
  // ═══════════════════════════════════════════════════════════════════════════
  static const dark = MotiveColors({
    BuyingMotive.need: MotivePalette(
      Color(0xFF60A5FA), // blue-400
      Color(0xFF172554), // blue-950
    ),
    BuyingMotive.want: MotivePalette(
      Color(0xFFF472B6), // pink-400
      Color(0xFF500724), // pink-950
    ),
    BuyingMotive.sale: MotivePalette(
      Color(0xFFFBBF24), // amber-400
      Color(0xFF451A03), // amber-950
    ),
    BuyingMotive.emotion: MotivePalette(
      Color(0xFFC084FC), // purple-400
      Color(0xFF3B0764), // purple-950
    ),
    BuyingMotive.social: MotivePalette(
      Color(0xFF38BDF8), // sky-400
      Color(0xFF082F49), // sky-950
    ),
    BuyingMotive.convenience: MotivePalette(
      Color(0xFF2DD4BF), // teal-400
      Color(0xFF042F2E), // teal-950
    ),
    BuyingMotive.ads: MotivePalette(
      Color(0xFF60A5FA), // blue-400
      Color(0xFF172554), // blue-950
    ),
    BuyingMotive.other: MotivePalette(
      Color(0xFF94A3B8), // slate-400
      Color(0xFF1E293B), // slate-800
    ),
  });

  static MotiveColors of(BuildContext context) =>
      Theme.of(context).extension<MotiveColors>() ?? light;

  MotivePalette paletteOf(BuyingMotive motive) =>
      palettes[motive] ?? light.palettes[motive]!;

  @override
  MotiveColors copyWith({Map<BuyingMotive, MotivePalette>? palettes}) =>
      MotiveColors(palettes ?? this.palettes);

  @override
  MotiveColors lerp(covariant MotiveColors? other, double t) {
    if (other == null) return this;
    return MotiveColors({
      for (final m in BuyingMotive.values)
        m: paletteOf(m).lerp(other.paletteOf(m), t),
    });
  }
}
