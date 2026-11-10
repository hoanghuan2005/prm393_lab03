import 'package:flutter/material.dart';

import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../models/buying_motive.dart';
import '../models/wishlist_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/motive_colors.dart';
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
                    if (ProductImage.canShow(item.imageUrl)) ...[
                      ProductImage(url: item.imageUrl),
                      const SizedBox(width: AppDimens.space12),
                    ],
                    Expanded(
                      child: Text(
                        item.title,
                        // themed: the default styles are dark text, unreadable in dark mode
                        style: AppTextStyles.titleMedium.themed(context),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppDimens.space12),
                    Text(
                      formatVnd(item.latestPriceVnd),
                      style: item.hasPrice
                          ? AppTextStyles.titleMedium
                                .themed(context)
                                .copyWith(
                                  color: AppColors.onPrimary,
                                  fontWeight: FontWeight.w700,
                                )
                                .themed(context)
                          : AppTextStyles.labelMedium
                                .themed(context)
                                .copyWith(
                                  color: AppSemanticColors.of(context)
                                      .textSecondary,
                                )
                                .themed(context),
                    ),
                  ],
                ),
                if (item.variantLabel != null) ...[
                  const SizedBox(height: AppDimens.space4),
                  Text(
                    'Phân loại: ${item.variantLabel}',
                    style: AppTextStyles.caption.themed(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (item.shopName != null) ...[
                  const SizedBox(height: AppDimens.space4),
                  Text(
                    'Shop: ${item.shopName}',
                    style: AppTextStyles.caption.themed(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppDimens.space12),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: AppDimens.space12,
                  runSpacing: AppDimens.space8,
                  children: [
                    MotiveChip(motive: item.displayMotive, isCompact: true),
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

  Widget _buildStatusBadge(BuildContext context) {
    if (item.isInCooldown) {
      // Theme palette of "Cảm xúc" (purple): light and dark variants
      final palette = MotiveColors.of(context).paletteOf(BuyingMotive.emotion);
      // Same wording as the detail screen: time left to think it over
      final timeText = 'Còn ${item.remainingCooldownLabel}';

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
