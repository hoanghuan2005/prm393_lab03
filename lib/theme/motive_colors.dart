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
/// Widgets: `MotiveColors.of(context).of(motive)`; models read [MotiveColors.light].
@immutable
class MotiveColors extends ThemeExtension<MotiveColors> {
  final Map<BuyingMotive, MotivePalette> palettes;

  const MotiveColors(this.palettes);

  static const light = MotiveColors({
    BuyingMotive.need: MotivePalette(
      AppColors.motiveNeed,
      AppColors.motiveNeedBg,
    ),
    BuyingMotive.want: MotivePalette(
      AppColors.motiveWant,
      AppColors.motiveWantBg,
    ),
    BuyingMotive.sale: MotivePalette(
      AppColors.motiveSale,
      AppColors.motiveSaleBg,
    ),
    BuyingMotive.emotion: MotivePalette(
      AppColors.motiveEmotion,
      AppColors.motiveEmotionBg,
    ),
    BuyingMotive.social: MotivePalette(
      AppColors.motiveSocial,
      AppColors.motiveSocialBg,
    ),
    BuyingMotive.convenience: MotivePalette(
      AppColors.motiveConvenience,
      AppColors.motiveConvenienceBg,
    ),
    BuyingMotive.ads: MotivePalette(AppColors.motiveAds, AppColors.motiveAdsBg),
    BuyingMotive.other: MotivePalette(
      AppColors.motiveOther,
      AppColors.motiveOtherBg,
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
