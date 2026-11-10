import 'package:flutter/material.dart';

import '../core/formatters/money_format.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_text_styles.dart';

/// Latest price of a wishlist item; "Cần giá" when the price is not known (null)
class PriceChip extends StatelessWidget {
  final int? priceVnd;

  const PriceChip({super.key, required this.priceVnd});

  @override
  Widget build(BuildContext context) {
    final price = priceVnd;
    final missing = price == null;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space8,
        vertical: AppDimens.space4,
      ),
      decoration: BoxDecoration(
        color: missing
            ? AppSemanticColors.of(context).mutedSurface
            : AppSemanticColors.of(context).primaryContainer,
        borderRadius: AppDimens.borderPill,
        border: Border.all(color: AppSemanticColors.of(context).cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            missing ? Icons.sell_outlined : Icons.sell_rounded,
            size: 14,
            color: missing
                ? AppSemanticColors.of(context).accent
                : AppColors.onPrimary,
          ),
          const SizedBox(width: AppDimens.space4),
          Text(
            missing ? 'Cần giá' : formatVnd(price),
            style: AppTextStyles.labelMedium
                .themed(context)
                .copyWith(
                  color: missing
                      ? AppSemanticColors.of(context).accent
                      : AppColors.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
