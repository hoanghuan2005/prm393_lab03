import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../core/formatters/rating_format.dart';
import '../models/daily_price.dart';
import '../models/price_history_contribution.dart';
import '../models/same_product.dart';
import '../models/wishlist_item.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/same_product_viewmodel.dart';
import 'demo_data_badge.dart';
import 'section_card.dart';
import 'undo_snack_bar.dart';

/// Chi tiết món, under "Giá tham khảo" (G8): the same item and variant in up to 3
/// other shops, matched automatically by productCode. Facts only (price, day, shop,
/// how many people recorded it); no advice. Hidden without a productCode or a shop.
class SameProductCard extends StatefulWidget {
  final WishlistItem item;

  const SameProductCard({super.key, required this.item});

  @override
  State<SameProductCard> createState() => _SameProductCardState();
}

class _SameProductCardState extends State<SameProductCard> {
  @override
  void initState() {
    super.initState();
    // Once per opening of Chi tiết món
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SameProductViewModel?>()?.load(widget.item);
    });
  }

  Future<void> _hide(SameProductViewModel vm, SameProductOffer offer) async {
    final messenger = ScaffoldMessenger.of(context);
    showUndoSnackBar(
      context,
      'Đã ẩn ${offer.shopName ?? 'shop này'} khỏi danh sách.',
      () => vm.undoHide(offer.productKey),
    );
    if (!await vm.hide(offer.productKey)) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Chưa ẩn được. Kiểm tra mạng rồi thử lại.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  void _open(SameProductState state, SameProductOffer offer) {
    final own = HistoryContribution.productKeyOf(widget.item);
    Navigator.pushNamed(
      context,
      AppRoutes.priceHistory,
      arguments: PriceHistoryArgs(
        productKey: offer.productKey,
        // "Cả nhóm" from there: this item and the other shops of the list
        sameProduct: SameProductLinks(
          productKeys: [
            ?own,
            for (final o in state.offers)
              if (o.productKey != offer.productKey) o.productKey,
          ],
          variantCode: state.variantCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SameProductViewModel?>();
    final state = vm?.stateFor(widget.item);
    if (vm == null || state == null || !state.visible) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final muted = AppTextStyles.labelMedium.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Padding(
      key: const ValueKey('same-product-card'),
      padding: const EdgeInsets.only(bottom: AppDimens.space16),
      child: SectionCard(
        title: 'Cùng món ở shop khác',
        icon: Icons.storefront_outlined,
        children: [
          Wrap(
            spacing: AppDimens.space8,
            runSpacing: AppDimens.space4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Có thể là cùng món · ghép tự động', style: muted),
              if (state.isDemo) const DemoDataBadge(),
            ],
          ),
          for (final offer in state.offers) ...[
            const Divider(height: AppDimens.space16),
            _OfferRow(
              offer: offer,
              onOpen: () => _open(state, offer),
              onHide: () => _hide(vm, offer),
            ),
          ],
          const SizedBox(height: AppDimens.space8),
          Text(
            'Giá niêm yết ghi trong ${SameProduct.windowDays} ngày qua, cùng phân '
            'loại; không gồm giá sau voucher. Chỉ để tham khảo.',
            style: muted,
          ),
        ],
      ),
    );
  }
}

class _OfferRow extends StatelessWidget {
  final SameProductOffer offer;
  final VoidCallback onOpen;
  final VoidCallback onHide;

  const _OfferRow({
    required this.offer,
    required this.onOpen,
    required this.onHide,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = AppTextStyles.labelMedium.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final people = offer.reporterCount == 1
        ? '1 người ghi'
        : '${offer.reporterCount} người ghi';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          key: ValueKey('same-offer-${offer.productKey}'),
          borderRadius: AppDimens.borderLarge,
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppDimens.space4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.shopName ?? 'Shop chưa rõ tên',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: AppDimens.space4),
                      Text(
                        [
                          'ngày ${formatDayMonth(vnDate(offer.observedAt))}',
                          people,
                          if (offer.productRating case final r?)
                            '★ ${formatStars(r)}',
                        ].join(' · '),
                        style: muted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimens.space8),
                // Shrinks and wraps on narrow screens / large text
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatVnd(offer.priceVnd),
                        style: AppTextStyles.labelLarge,
                        textAlign: TextAlign.end,
                      ),
                      if (offer.onSale)
                        Text(
                          'Đang giảm',
                          key: ValueKey('same-sale-${offer.productKey}'),
                          style: muted,
                          textAlign: TextAlign.end,
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            key: ValueKey('same-hide-${offer.productKey}'),
            onPressed: onHide,
            child: const Text('Không phải món này'),
          ),
        ),
      ],
    );
  }
}
