import 'package:flutter/material.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

/// The yellow "W" mark of the admin portal
class BrandMark extends StatelessWidget {
  final double size;

  const BrandMark({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Text(
        'W',
        style: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.onPrimary,
          fontSize: size * 0.5,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}
