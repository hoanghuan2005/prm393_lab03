import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../models/buying_motive.dart';
import '../models/voucher.dart';
import '../models/voucher_matcher.dart';
import '../models/wishlist_item.dart';
import '../services/voucher_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/motive_colors.dart';
import '../viewmodels/decision_support_viewmodel.dart';
import 'demo_data_badge.dart';
import 'motive_chip.dart';
import 'product_image.dart';

/// Reusable Wishlist Item Card conforming to Figma specs
class WishlistCard extends StatelessWidget {
  final WishlistItem item;
  final VoidCallback onTap;

  const WishlistCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Check for good deal insight or voucher discount
    final decisionSupportVm = context.watch<DecisionSupportViewModel?>();
    final insights = decisionSupportVm?.priceInsightsFor(item);
    final hasDeal = insights?.hasGoodDeal ?? false;
    final dealSavings = insights?.goodDealSavingsVnd ?? 0;

    // Check for voucher price suggestion
    final voucherService = context.watch<VoucherService?>();
    // V8: the list price stays the card's main price; a voucher that applies only
    // adds a small "Có mã …" line. V6c: the saved latest price is a list price
    // (never "sau voucher"), so the card needs no price history of its own.
    final listPrice = VoucherMatcher.cardListPrice(
      item,
      history: insights?.history,
    );
    final bestVoucher = (listPrice != null && voucherService != null)
        ? voucherService.findBestVoucher(
            item: item,
            priceVnd: listPrice.amountVnd,
            now: DateTime.now(),
          )
        : null;
    // "Thấp hơn lúc lưu N%": compared with the price recorded when saving
    final savedPrice = insights?.saved?.amountVnd;
    final dealPercent = (hasDeal && savedPrice != null && savedPrice > 0)
        ? (dealSavings * 100 / savedPrice).round()
        : null;

    return Semantics(
      button: true,
      label:
          'Món ${item.title}, giá ${formatVnd(item.latestPriceVnd)}, động cơ ${item.displayMotive.label}',
      child: Card(
        margin: const EdgeInsets.only(bottom: AppDimens.space12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimens.borderLarge,
          side: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppDimens.borderLarge,
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildThumbnail(context),
                    const SizedBox(width: AppDimens.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            // themed: the default styles are dark text, unreadable in dark mode
                            style: AppTextStyles.titleMedium.themed(context),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.variantLabel != null) ...[
                            const SizedBox(height: AppDimens.space4),
                            _metaLine(
                              context,
                              Icons.style_outlined,
                              item.variantLabel!,
                            ),
                          ],
                          if (item.shopName != null) ...[
                            const SizedBox(height: AppDimens.space4),
                            _metaLine(
                              context,
                              Icons.storefront_outlined,
                              item.shopName!,
                            ),
                          ],
                          const SizedBox(height: AppDimens.space8),
                          Text(
                            formatVnd(item.latestPriceVnd),
                            key: const ValueKey('card-price'),
                            style: item.hasPrice
                                ? AppTextStyles.titleMedium
                                      .copyWith(
                                        color: AppColors.onPrimary,
                                        fontWeight: FontWeight.w700,
                                      )
                                      .themed(context)
                                : AppTextStyles.labelMedium
                                      .themed(context)
                                      .copyWith(
                                        color: AppSemanticColors.of(
                                          context,
                                        ).textSecondary,
                                        fontStyle: FontStyle.italic,
                                      ),
                          ),
                          if (bestVoucher != null) ...[
                            const SizedBox(height: AppDimens.space4),
                            _voucherLine(context, bestVoucher),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.space12),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
                ),
                const SizedBox(height: AppDimens.space12),
                Wrap(
                  spacing: AppDimens.space8,
                  runSpacing: AppDimens.space8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    MotiveChip(motive: item.displayMotive, isCompact: true),
                    if (hasDeal) _lowerThanSavedBadge(context, dealPercent, dealSavings),
                    if (item.isDemo) const DemoDataBadge(),
                    if (item.isFromExtension) fromExtensionChip(context),
                    _buildStatusBadge(context),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// "Có mã −15.000 ₫ · đơn từ 50.000 ₫": a voucher that applies, in the quiet
  /// secondary style; the list price above stays the main price (V8)
  Widget _voucherLine(BuildContext context, Voucher voucher) {
    final color = AppSemanticColors.of(context).textSecondary;
    final owner = voucher.isShopVoucher ? 'Có mã của shop' : 'Có mã';
    final minOrder = voucher.minOrder > 0
        ? ' · đơn từ ${formatVnd(voucher.minOrder)}'
        : '';
    return Row(
      key: const ValueKey('card-voucher-line'),
      children: [
        Icon(Icons.local_offer_outlined, size: 14, color: color),
        const SizedBox(width: AppDimens.space4),
        Expanded(
          child: Text(
            '$owner −${formatVnd(voucher.discountAmount)}$minOrder',
            style: AppTextStyles.caption.themed(context).copyWith(color: color),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Neutral observation, never "giá hời" / "tiết kiệm" (no red, no emoji)
  Widget _lowerThanSavedBadge(BuildContext context, int? percent, int savings) {
    final colors = AppSemanticColors.of(context);
    final amount = savings > 0 ? formatVnd(savings) : null;
    return Container(
      key: const ValueKey('card-lower-than-saved'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space8,
        vertical: AppDimens.space4,
      ),
      decoration: BoxDecoration(
        color: colors.mutedSurface,
        borderRadius: AppDimens.borderPill,
        border: Border.all(color: colors.divider),
      ),
      child: Text(
        percent != null && amount != null
            ? 'Thấp hơn lúc lưu $percent% (−$amount)'
            : 'Thấp hơn lúc lưu',
        style: AppTextStyles.caption
            .themed(context)
            .copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  static const double _thumbSize = 84;

  /// Framed product photo; a quiet bag icon keeps cards aligned when there is no photo
  Widget _buildThumbnail(BuildContext context) {
    final colors = AppSemanticColors.of(context);
    return Container(
      width: _thumbSize,
      height: _thumbSize,
      decoration: BoxDecoration(
        color: colors.mutedSurface,
        borderRadius: AppDimens.borderMedium,
        border: Border.all(color: colors.cardBorder.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: ProductImage.canShow(item.imageUrl)
          ? ProductImage(url: item.imageUrl, size: _thumbSize)
          : Icon(
              Icons.shopping_bag_outlined,
              size: 32,
              color: colors.textSecondary,
            ),
    );
  }

  static Widget _metaLine(BuildContext context, IconData icon, String text) {
    final color = AppSemanticColors.of(context).textSecondary;
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: AppDimens.space4),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.caption.themed(context).copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    if (item.isInCooldown) {
      // Theme palette of "Cảm xúc" (purple): light and dark variants
      final palette = MotiveColors.of(context).paletteOf(BuyingMotive.emotion);
      final timeText =
          'Mốc ${formatDayMonth(item.cooldownUntil!)} · ${formatTime(item.cooldownUntil!)}';

      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space8,
          vertical: AppDimens.space4,
        ),
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: AppDimens.borderPill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 14, color: palette.foreground),
            const SizedBox(width: AppDimens.space4),
            Text(
              timeText,
              style: AppTextStyles.labelMedium
                  .themed(context)
                  .copyWith(color: palette.foreground),
            ),
          ],
        ),
      );
    }

    // "Chờ" keeps the status "Đang cân nhắc"; the review date is what the user needs to see
    if (item.isWaiting || item.isReviewDue) {
      return _badge(
        context,
        icon: item.isReviewDue
            ? Icons.notifications_active_outlined
            : Icons.event,
        text: item.isReviewDue
            ? 'Đến hẹn xem lại'
            : 'Xem lại ${formatDayMonth(item.reviewAt!)}',
      );
    }

    return _badge(
      context,
      icon: item.status.icon,
      text: item.status.label,
      color: AppSemanticColors.of(context).statusNeutral,
    );
  }

  /// "Từ máy tính": saved with the Chrome extension (saveChannel extension)
  static Widget fromExtensionChip(BuildContext context) => _badge(
    context,
    icon: Icons.computer_rounded,
    text: 'Từ máy tính',
    color: AppSemanticColors.of(context).textSecondary,
  );

  static Widget _badge(
    BuildContext context, {
    required IconData icon,
    required String text,
    Color? color,
  }) {
    color ??= AppSemanticColors.of(context).accent;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space8,
        vertical: AppDimens.space4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppDimens.borderPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppDimens.space4),
          Text(
            text,
            style: AppTextStyles.labelMedium
                .themed(context)
                .copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
