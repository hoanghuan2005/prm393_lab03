import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../models/purchase_item.dart';
import '../models/wishlist_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/wishlist_viewmodel.dart';

/// "Định mua từ máy tính": items marked "Mua" in the Chrome extension (handoff X3).
/// The extension only records the intent; the purchase is recorded here with the usual form.
class BuyIntentSection extends StatelessWidget {
  const BuyIntentSection({super.key});

  @override
  Widget build(BuildContext context) {
    final items = context.watch<WishlistViewModel>().buyIntentItems;
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      key: const ValueKey('buy-intent-section'),
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppDimens.space16,
        AppDimens.space8,
        AppDimens.space16,
        0,
      ),
      padding: const EdgeInsets.all(AppDimens.space12),
      decoration: BoxDecoration(
        color: AppSemanticColors.of(context).primaryContainer,
        borderRadius: AppDimens.borderLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.computer_rounded,
                size: 18,
                color: AppColors.onPrimary,
              ),
              const SizedBox(width: AppDimens.space8),
              Text(
                'Định mua từ máy tính (${items.length})',
                style: AppTextStyles.labelLarge.themed(context),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space4),
          Text(
            'Bạn đã bấm Mua trên extension. Ghi khoản mua khi đã mua thật.',
            style: AppTextStyles.caption.themed(context),
          ),
          for (final item in items)
            _BuyIntentRow(key: ValueKey('buy-intent-${item.id}'), item: item),
        ],
      ),
    );
  }
}

class _BuyIntentRow extends StatelessWidget {
  final WishlistItem item;

  const _BuyIntentRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppDimens.space8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.variantLabel == null
                  ? item.title
                  : '${item.title} · ${item.variantLabel}',
              style: AppTextStyles.bodyMedium.themed(context),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () => _notBought(context),
            child: const Text('Chưa mua'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, AppDimens.minTouchTarget),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            onPressed: () => _record(context),
            child: const Text('Ghi khoản mua'),
          ),
        ],
      ),
    );
  }

  /// Same flow as "Mua" in the item detail: the form, then the saved purchase
  Future<void> _record(BuildContext context) async {
    final saved = await Navigator.pushNamed<PurchaseItem>(
      context,
      AppRoutes.recordPurchase,
      arguments: RecordPurchaseArgs(wishlistItem: item),
    );
    if (saved != null && context.mounted) {
      Navigator.pushNamed(
        context,
        AppRoutes.purchaseDetail,
        arguments: PurchaseDetailArgs(saved),
      );
    }
  }

  Future<void> _notBought(BuildContext context) async {
    final vm = context.read<WishlistViewModel>();
    final ok = await vm.clearBuyIntent(item);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '"${item.title}" vẫn ở trạng thái Đang cân nhắc.'
              : vm.actionError ?? 'Đã có lỗi, vui lòng thử lại.',
        ),
      ),
    );
  }
}
