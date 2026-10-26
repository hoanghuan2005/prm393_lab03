import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Decision States for Why I Buy items
enum ItemStatus {
  considering(
    'considering',
    'Đang cân nhắc',
    Icons.hourglass_top_outlined,
    AppColors.warning,
  ),
  waiting('waiting', 'Chờ đợt sale', Icons.schedule, AppColors.info),
  bought(
    'bought',
    'Đã mua',
    Icons.shopping_bag_outlined,
    AppColors.textSecondary,
  ),
  dropped(
    'dropped',
    'Bỏ qua (Tiết kiệm)',
    Icons.savings_outlined,
    AppColors.success,
  );

  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const ItemStatus(this.key, this.label, this.icon, this.color);

  static ItemStatus fromKey(String? key) {
    return ItemStatus.values.firstWhere(
      (s) => s.key == key,
      orElse: () => ItemStatus.considering,
    );
  }
}
