import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../models/buying_motive.dart';
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
    final bestVoucher = (item.latestPriceVnd != null && voucherService != null)
        ? voucherService.findBestVoucher(
            priceVnd: item.latestPriceVnd!,
            platform: (item.url ?? '').toLowerCase().contains('lazada')
                ? 'Lazada'
                : 'Shopee',
            shopName: item.shopName,
          )
        : null;
    final priceAfterVoucher = (bestVoucher != null && item.latestPriceVnd != null)
        ? (item.latestPriceVnd! - bestVoucher.discountAmount)
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
                          // Price; with a voucher the list price is struck through
                          // and the price after voucher shows next to it
                          Wrap(
                            spacing: AppDimens.space8,
                            runSpacing: AppDimens.space4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                formatVnd(item.latestPriceVnd),
                                style: item.hasPrice
                                    ? AppTextStyles.titleMedium
                                          .themed(context)
                                          .copyWith(
                                            color: priceAfterVoucher != null
                                                ? AppSemanticColors.of(
                                                    context,
                                                  ).textSecondary
                                                : AppColors.onPrimary,
                                            fontWeight: priceAfterVoucher != null
                                                ? FontWeight.w500
                                                : FontWeight.w700,
                                            decoration: priceAfterVoucher != null
                                                ? TextDecoration.lineThrough
                                                : null,
                                          )
                                          .themed(context)
                                    : AppTextStyles.labelMedium
                                          .themed(context)
                                          .copyWith(
                                            color: AppSemanticColors.of(
                                              context,
                                            ).textSecondary,
                                            fontStyle: FontStyle.italic,
                                          )
                                          .themed(context),
                              ),
                              if (priceAfterVoucher != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 12,
                                      color: AppSemanticColors.of(
                                        context,
                                      ).success,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      formatVnd(
                                        priceAfterVoucher > 0
                                            ? priceAfterVoucher
                                            : 0,
                                      ),
                                      style: AppTextStyles.titleMedium
                                          .themed(context)
                                          .copyWith(
                                            color: AppSemanticColors.of(
                                              context,
                                            ).success,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
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
                    if (hasDeal)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppSemanticColors.of(context).error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppSemanticColors.of(context).error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(
                              dealSavings > 0
                                  ? 'Giá hời · Tiết kiệm ${formatVnd(dealSavings)}'
                                  : 'Giá hời',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppSemanticColors.of(context).error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (bestVoucher != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppSemanticColors.of(context).success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppSemanticColors.of(context).success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_offer_rounded,
                              size: 11,
                              color: AppSemanticColors.of(context).success,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              bestVoucher.isShopVoucher
                                  ? 'Voucher Shop -${formatVnd(bestVoucher.discountAmount)}'
                                  : 'Mã ${bestVoucher.code} -${formatVnd(bestVoucher.discountAmount)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppSemanticColors.of(context).success,
                              ),
                            ),
                          ],
                        ),
                      ),
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
