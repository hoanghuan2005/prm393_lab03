import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shared brand mark for "Why I Buy".
class WhyIBuyLogo extends StatelessWidget {
  final double size;
  final Color color;

  const WhyIBuyLogo({
    super.key,
    this.size = 48,
    this.color = AppColors.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.spa_rounded, size: size * 0.58, color: color),
      ),
    );
  }
}
