import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Decision state of a wishlist item. Mua · Chờ · Bỏ qua are shown with equal weight
/// (same neutral color, no praise for skipping).
enum WishlistStatus {
  considering(
    'considering',
    'Đang cân nhắc',
    Icons.hourglass_top_outlined,
    AppColors.accentNeutral,
  ),
  purchased(
    'purchased',
    'Đã mua',
    Icons.shopping_bag_outlined,
    AppColors.accentNeutral,
  ),
  skipped(
    'skipped',
    'Bỏ qua',
    Icons.do_not_disturb_on_outlined,
    AppColors.accentNeutral,
  );

  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const WishlistStatus(this.key, this.label, this.icon, this.color);

  /// Also reads keys written by older app versions
  static WishlistStatus fromKey(String? key) {
    switch (key) {
      case 'purchased':
      case 'bought':
        return WishlistStatus.purchased;
      case 'skipped':
      case 'dropped':
        return WishlistStatus.skipped;
      case 'considering':
      case 'waiting':
      default:
        return WishlistStatus.considering;
    }
  }
}
