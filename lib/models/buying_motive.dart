import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 8 Buying Motives based on "Why I Buy - The Psychology of Money"
enum BuyingMotive {
  need(
    'need',
    'Nhu cầu',
    Icons.inventory_2_outlined,
    AppColors.motiveNeed,
    AppColors.motiveNeedBg,
  ),
  want(
    'want',
    'Mong muốn',
    Icons.favorite_outline,
    AppColors.motiveWant,
    AppColors.motiveWantBg,
  ),
  sale(
    'sale',
    'Khuyến mãi',
    Icons.local_offer_outlined,
    AppColors.motiveSale,
    AppColors.motiveSaleBg,
  ),
  emotion(
    'emotion',
    'Cảm xúc',
    Icons.sentiment_very_satisfied_outlined,
    AppColors.motiveEmotion,
    AppColors.motiveEmotionBg,
  ),
  social(
    'social',
    'Ảnh hưởng MXH',
    Icons.trending_up,
    AppColors.motiveSocial,
    AppColors.motiveSocialBg,
  ),
  convenience(
    'convenience',
    'Tiện lợi',
    Icons.bolt_outlined,
    AppColors.motiveConvenience,
    AppColors.motiveConvenienceBg,
  ),
  ads(
    'ads',
    'Quảng cáo',
    Icons.campaign_outlined,
    AppColors.motiveAds,
    AppColors.motiveAdsBg,
  ),
  other(
    'other',
    'Khác',
    Icons.more_horiz,
    AppColors.motiveOther,
    AppColors.motiveOtherBg,
  );

  final String key;
  final String label;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const BuyingMotive(
    this.key,
    this.label,
    this.icon,
    this.color,
    this.backgroundColor,
  );

  static BuyingMotive fromKey(String? key) {
    return BuyingMotive.values.firstWhere(
      (m) => m.key == key,
      orElse: () => BuyingMotive.other,
    );
  }

  /// Whether this motive triggers the 3-day psychological cooldown period
  bool get triggersCooldown =>
      this == BuyingMotive.emotion || this == BuyingMotive.social;

  /// Whether this motive relates to periodic shopping sale dates
  bool get relatesToSales => this == BuyingMotive.sale;
}
