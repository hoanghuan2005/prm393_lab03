import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/formatters/money_format.dart';
import '../models/voucher.dart';
import '../models/wishlist_item.dart';
import '../services/voucher_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

class VoucherSuggestionCard extends StatefulWidget {
  final WishlistItem item;

  const VoucherSuggestionCard({super.key, required this.item});

  @override
  State<VoucherSuggestionCard> createState() => _VoucherSuggestionCardState();
}

class _VoucherSuggestionCardState extends State<VoucherSuggestionCard> {
  bool _isExpanded = false;

  String _detectPlatform(WishlistItem item) {
    final url = (item.url ?? '').toLowerCase();
    final shop = (item.shopName ?? '').toLowerCase();
    if (url.contains('lazada') || shop.contains('lazada')) return 'Lazada';
    return 'Shopee';
  }

  @override
  Widget build(BuildContext context) {
    List<Voucher> allVouchers = VoucherService.defaultVouchers;
    try {
      final vs = Provider.of<VoucherService?>(context);
      if (vs != null) {
        allVouchers = vs.allVouchers;
      }
    } catch (_) {
      // In case Provider is not mounted or during hot reload without full restart
    }

    final platform = _detectPlatform(widget.item);
    final price = widget.item.latestPriceVnd ?? 0;

    // Get applicable vouchers for this price
    final applicable = allVouchers
        .where((v) => v.canApplyTo(priceVnd: price, itemPlatform: platform))
        .toList();

    Voucher? bestVoucher;
    if (applicable.isNotEmpty) {
      applicable.sort((a, b) => b.discountAmount.compareTo(a.discountAmount));
      bestVoucher = applicable.first;
    }

    Voucher? nextTargetVoucher;
    if (bestVoucher == null && allVouchers.isNotEmpty) {
      final potential = allVouchers
          .where((v) => v.isActive && (v.platform == 'Tất cả' || v.platform == platform))
          .toList();
      if (potential.isNotEmpty) {
        potential.sort((a, b) => a.minOrder.compareTo(b.minOrder));
        nextTargetVoucher = potential.first;
      }
    }

    if (bestVoucher == null && nextTargetVoucher == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final isShopee = platform == 'Shopee';
    final brandColor = isShopee ? const Color(0xFFEE4D2D) : const Color(0xFF0F146D);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: AppDimens.space12),
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppDimens.borderLarge,
        border: Border.all(
          color: brandColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: brandColor.withValues(alpha: isDark ? 0.08 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: brandColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.local_offer_rounded,
                  color: brandColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppDimens.space8),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'Ưu đãi & Voucher $platform',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Tiết kiệm',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (applicable.length > 1)
                GestureDetector(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Text(
                    _isExpanded ? 'Thu gọn' : '+${applicable.length - 1} mã khác',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.info,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimens.space12),

          // Main Voucher Showcase
          if (bestVoucher != null) ...[
            _buildVoucherRow(context, bestVoucher, brandColor, isDark),
          ] else if (nextTargetVoucher != null) ...[
            // Mẹo đạt điều kiện áp mã
            Container(
              padding: const EdgeInsets.all(AppDimens.space12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
                borderRadius: AppDimens.borderMedium,
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.warning),
                  const SizedBox(width: AppDimens.space8),
                  Expanded(
                    child: Text(
                      'Thêm ${formatVnd(nextTargetVoucher.minOrder - price)} để áp dụng mã ${nextTargetVoucher.code} (Giảm ${formatVnd(nextTargetVoucher.discountAmount)})!',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark ? AppColors.textOnDark : AppColors.textBody,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Expanded List for other vouchers
          if (_isExpanded && applicable.length > 1) ...[
            const SizedBox(height: AppDimens.space12),
            const Divider(height: 1),
            const SizedBox(height: AppDimens.space8),
            ...applicable.skip(1).map(
                  (v) => Padding(
                    padding: const EdgeInsets.only(top: AppDimens.space8),
                    child: _buildVoucherRow(context, v, brandColor, isDark, isSecondary: true),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoucherRow(
    BuildContext context,
    Voucher voucher,
    Color brandColor,
    bool isDark, {
    bool isSecondary = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
        borderRadius: AppDimens.borderMedium,
        border: Border.all(
          color: isSecondary ? AppColors.divider : brandColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Code Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: brandColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        voucher.code,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                          color: brandColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Giảm ${formatVnd(voucher.discountAmount)}',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  voucher.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppColors.textOnDark : AppColors.textBody,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Đơn tối thiểu ${formatVnd(voucher.minOrder)} · Hạn đến ${voucher.validUntil}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              Clipboard.setData(ClipboardData(text: voucher.code));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã sao chép mã ${voucher.code} để dùng trên ${voucher.platform}!'),
                  backgroundColor: brandColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: brandColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Lưu mã',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
