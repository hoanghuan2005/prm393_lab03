import 'package:flutter/material.dart';

import '../theme/motive_colors.dart';

/// 8 Buying Motives based on "Why I Buy - The Psychology of Money"
enum BuyingMotive {
  need('need', 'Nhu cầu', Icons.inventory_2_outlined),
  want('want', 'Mong muốn', Icons.favorite_outline),
  sale('sale', 'Khuyến mãi', Icons.local_offer_outlined),
  emotion('emotion', 'Cảm xúc', Icons.sentiment_very_satisfied_outlined),
  social('social', 'Ảnh hưởng MXH', Icons.trending_up),
  convenience('convenience', 'Tiện lợi', Icons.bolt_outlined),
  ads('ads', 'Quảng cáo', Icons.campaign_outlined),
  other('other', 'Khác', Icons.more_horiz);

  final String key;
  final String label;
  final IconData icon;

  const BuyingMotive(this.key, this.label, this.icon);

  /// Colors come from the single source in MotiveColors (theme/motive_colors.dart)
  Color get color => MotiveColors.light.paletteOf(this).foreground;
  Color get backgroundColor => MotiveColors.light.paletteOf(this).background;

  static BuyingMotive fromKey(String? key) {
    return BuyingMotive.values.firstWhere(
      (m) => m.key == key,
      orElse: () => BuyingMotive.other,
    );
  }

  /// "Nhu cầu" items skip the cooling-off period; every other motive waits
  bool get skipsCooldown => this == BuyingMotive.need;

  /// Whether this motive relates to periodic shopping sale dates
  bool get relatesToSales => this == BuyingMotive.sale;
}
