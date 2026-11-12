import 'package:flutter/material.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

/// The official Why I Buy brand mark for the admin portal
class BrandMark extends StatelessWidget {
  final double size;
  final Color color;

  const BrandMark({
    super.key,
    this.size = 44,
    this.color = AppColors.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.spa_rounded, size: size * 0.58, color: color),
      ),
    );
  }
}
