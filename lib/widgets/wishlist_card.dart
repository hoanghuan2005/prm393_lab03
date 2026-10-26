import 'package:flutter/material.dart';

import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../models/wishlist_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import 'motive_chip.dart';

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
        shape: const RoundedRectangleBorder(
          borderRadius: AppDimens.borderLarge,
          side: BorderSide(color: AppColors.divider, width: 1),
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
                    Expanded(
                      child: Text(
                        item.title,
                        style: AppTextStyles.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppDimens.space12),
                    Text(
                      formatVnd(item.latestPriceVnd),
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.space12),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: AppDimens.space12,
                  runSpacing: AppDimens.space8,
                  children: [
                    MotiveChip(motive: item.displayMotive, isCompact: true),
                    _buildStatusBadge(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (item.isInCooldown) {
      final hours = item.remainingCooldown.inHours;
      final days = item.remainingCooldown.inDays;
      final timeText = days > 0 ? '$days ngày hoãn' : '$hours giờ hoãn';

      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space8,
          vertical: AppDimens.space4,
        ),
        decoration: const BoxDecoration(
          color: AppColors.motiveEmotionBg,
          borderRadius: AppDimens.borderPill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.timer_outlined,
              size: 14,
              color: AppColors.motiveEmotion,
            ),
            const SizedBox(width: AppDimens.space4),
            Text(
              timeText,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.motiveEmotion,
              ),
            ),
          ],
        ),
      );
    }

    // "Chờ" keeps the status "Đang cân nhắc"; the review date is what the user needs to see
    if (item.isWaiting || item.isReviewDue) {
      return _badge(
        icon: item.isReviewDue
            ? Icons.notifications_active_outlined
            : Icons.event,
        text: item.isReviewDue
            ? 'Đến hẹn xem lại'
            : 'Xem lại ${formatDayMonth(item.reviewAt!)}',
      );
    }

    return _badge(
      icon: item.status.icon,
      text: item.status.label,
      color: item.status.color,
    );
  }

  Widget _badge({
    required IconData icon,
    required String text,
    Color color = AppColors.accentNeutral,
  }) {
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
          Text(text, style: AppTextStyles.labelMedium.copyWith(color: color)),
        ],
      ),
    );
  }
}
