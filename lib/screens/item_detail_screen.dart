import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../models/purchase_item.dart';
import '../models/wishlist_item.dart';
import '../models/wishlist_status.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<WishlistViewModel>().onItemViewed(widget.item);
    });
  }

  Future<void> _handleDecision(WishlistStatus newStatus) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    final wishlistVm = context.read<WishlistViewModel>();
    final item = _currentItem(wishlistVm);

    final success = await wishlistVm.updateDecision(
      itemId: item.id,
      status: newStatus,
      motive: item.displayMotive,
      price: item.latestPriceVnd,
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        String msg = '';
        if (newStatus == WishlistStatus.skipped) {
          msg = 'Đã chuyển món sang Bỏ qua.';
        } else {
          msg = 'Đã đặt ngày xem lại món.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.success),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              wishlistVm.actionError ??
                  'Chưa lưu được quyết định. Vui lòng thử lại.',
            ),
          ),
        );
      }
    }
  }

  WishlistItem _currentItem(WishlistViewModel vm) => vm.allItems.firstWhere(
    (item) => item.id == widget.item.id,
    orElse: () => widget.item,
  );

  Future<void> _recordPurchase(WishlistItem item) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    final saved = await Navigator.pushNamed<PurchaseItem>(
      context,
      AppRoutes.recordPurchase,
      arguments: RecordPurchaseArgs(wishlistItem: item),
    );
    if (!mounted) return;
    setState(() => _isProcessing = false);
    if (saved != null) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.purchaseDetail,
        arguments: PurchaseDetailArgs(saved),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _currentItem(context.watch<WishlistViewModel>());
    final canDecide = item.status == WishlistStatus.considering;
    final needsPurchase =
        item.status == WishlistStatus.purchased && item.purchaseId == null;

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
                  Wrap(
                    spacing: AppDimens.space12,
                    runSpacing: AppDimens.space8,
                    children: [
                      MotiveChip(motive: item.displayMotive),
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

            if (needsPurchase) ...[
              Text(
                'Món đã được đánh dấu mua nhưng chưa có khoản thực chi. Bạn có thể bổ sung khoản mua.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppDimens.space12),
            ],
            if (canDecide || needsPurchase) ...[
              AppButton(
                title: needsPurchase ? 'Bổ sung khoản mua' : 'Mua',
                variant: AppButtonVariant.secondary,
                icon: Icons.shopping_bag_outlined,
                isLoading: _isProcessing,
                onPressed: () => _recordPurchase(item),
              ),
            ],
            if (canDecide) ...[
              const SizedBox(height: AppDimens.space12),

              AppButton(
                title: 'Chờ',
                variant: AppButtonVariant.secondary,
                icon: Icons.schedule,
                isLoading: _isProcessing,
                onPressed: () => _handleDecision(WishlistStatus.considering),
              ),
              const SizedBox(height: AppDimens.space12),

              AppButton(
                title: 'Bỏ qua',
                variant: AppButtonVariant.secondary,
                icon: Icons.do_not_disturb_on_outlined,
                isLoading: _isProcessing,
                onPressed: () => _handleDecision(WishlistStatus.skipped),
              ),
            ] else if (!needsPurchase)
              Text(item.status.label, style: AppTextStyles.titleMedium),
          ],
        ),
      ),
    );
  }
}
