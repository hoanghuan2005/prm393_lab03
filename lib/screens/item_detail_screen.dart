import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../models/wishlist_item.dart';
import '../models/wishlist_status.dart';
import '../services/analytics_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/wishlist_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/motive_chip.dart';

/// Screen 03: Item Detail & Decision Card from Figma "Why I Buy"
class ItemDetailScreen extends StatefulWidget {
  final WishlistItem item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Log view_item_detail analytics event on enter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final analytics = context.read<AppAnalyticsService>();
      final daysInCooldown = DateTime.now()
          .difference(widget.item.createdAt)
          .inDays;
      analytics.logViewItemDetail(
        itemId: widget.item.id,
        motive: widget.item.displayMotive.key,
        daysInCooldown: daysInCooldown,
      );
    });
  }

  Future<void> _handleDecision(WishlistStatus newStatus) async {
    setState(() => _isProcessing = true);
    final wishlistVm = context.read<WishlistViewModel>();

    final success = await wishlistVm.updateDecision(
      itemId: widget.item.id,
      status: newStatus,
      motive: widget.item.displayMotive,
      price: widget.item.latestPriceVnd,
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        String msg = '';
        if (newStatus == WishlistStatus.skipped) {
          msg = 'Đã chuyển món sang Bỏ qua.';
        } else if (newStatus == WishlistStatus.purchased) {
          msg = 'Đã đánh dấu mua thành công sau khi cân nhắc kỹ.';
        } else {
          msg = 'Đã chuyển sang danh sách Chờ sale định kỳ.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.success),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết & Quyết định')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimens.space20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppDimens.borderLarge,
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: AppTextStyles.headlineMedium),
                  const SizedBox(height: AppDimens.space12),
                  Text(
                    formatVnd(item.latestPriceVnd),
                    style: AppTextStyles.displayMedium.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppDimens.space16),
                  Row(
                    children: [
                      MotiveChip(motive: item.displayMotive),
                      const Spacer(),
                      Text(
                        'Lưu ngày: ${formatDate(item.createdAt)}',
                        style: AppTextStyles.labelMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space20),

            // Psychological Cooldown Box
            if (item.isInCooldown) ...[
              Container(
                padding: const EdgeInsets.all(AppDimens.space16),
                decoration: BoxDecoration(
                  color: AppColors.motiveEmotionBg,
                  borderRadius: AppDimens.borderMedium,
                  border: Border.all(
                    color: AppColors.motiveEmotion.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.hourglass_top,
                      color: AppColors.motiveEmotion,
                      size: 28,
                    ),
                    const SizedBox(width: AppDimens.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đang trong thời gian cân nhắc',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.motiveEmotion,
                            ),
                          ),
                          Text(
                            'Còn lại khoảng ${item.remainingCooldown.inDays} ngày ${item.remainingCooldown.inHours % 24} giờ để bạn cân nhắc lý do mua.',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.space20),
            ],

            // Decision Card (Why I Buy Core)
            Text(
              'Thẻ Quyết Định (Decision Card)',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: AppDimens.space8),
            Text(
              'Sau khi suy ngẫm, bạn lựa chọn hành động nào cho món đồ này?',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppDimens.space16),

            // Button 1: Dropped (Save Money)
            AppButton(
              title: 'Bỏ qua',
              icon: Icons.savings_outlined,
              isLoading: _isProcessing,
              onPressed: () => _handleDecision(WishlistStatus.skipped),
            ),
            const SizedBox(height: AppDimens.space12),

            // Button 2: Wait for Sale
            AppButton(
              title: 'Chờ đợt sale định kỳ',
              variant: AppButtonVariant.secondary,
              icon: Icons.schedule,
              isLoading: _isProcessing,
              onPressed: () => _handleDecision(WishlistStatus.considering),
            ),
            const SizedBox(height: AppDimens.space12),

            // Button 3: Buy Now
            AppButton(
              title: 'Quyết định mua ngay',
              variant: AppButtonVariant.secondary,
              icon: Icons.shopping_bag_outlined,
              isLoading: _isProcessing,
              onPressed: () => _handleDecision(WishlistStatus.purchased),
            ),
          ],
        ),
      ),
    );
  }
}
