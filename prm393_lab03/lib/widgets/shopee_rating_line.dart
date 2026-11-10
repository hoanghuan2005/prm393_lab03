import 'package:flutter/material.dart';

import '../core/formatters/rating_format.dart';
import '../theme/app_text_styles.dart';

/// "★ 4,8 (1.200 đánh giá) · [shop icon] Shop Mây ★ 4,9" from what the extension read
/// on Shopee. Each part only when known; nothing at all without any rating (the shop
/// name alone is shown elsewhere).
class ShopeeRatingLine extends StatelessWidget {
  final double? productRating;
  final int? productRatingCount;
  final String? shopName;
  final double? shopRating;

  const ShopeeRatingLine({
    super.key,
    this.productRating,
    this.productRatingCount,
    this.shopName,
    this.shopRating,
  });

  @override
  Widget build(BuildContext context) {
    if (productRating == null && shopRating == null) {
      return const SizedBox.shrink();
    }
    final style = AppTextStyles.bodyMedium.themed(context);
    final product = formatProductRating(productRating, productRatingCount);
    final shop = formatShopRating(shopName, shopRating);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          if (product != null) TextSpan(text: product),
          if (product != null && shop != null) const TextSpan(text: ' · '),
          if (shop != null) ...[
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(
                Icons.storefront_outlined,
                size: (style.fontSize ?? 14) - 1,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                semanticLabel: 'Shop',
              ),
            ),
            TextSpan(text: ' $shop'),
          ],
        ],
      ),
    );
  }
}
