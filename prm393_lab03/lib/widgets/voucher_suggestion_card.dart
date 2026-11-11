import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/formatters/money_format.dart';
import '../models/voucher.dart';
import '../models/wishlist_item.dart';
import '../services/voucher_service.dart';
import '../theme/app_dimens.dart';
import '../theme/app_semantic_colors.dart';
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
    final shopName = widget.item.shopName;

    // Get applicable vouchers for this price and shop
    final applicable = allVouchers
        .where((v) => v.canApplyTo(
              priceVnd: price,
              itemPlatform: platform,
              itemShopName: shopName,
            ))
        .toList();

    Voucher? bestVoucher;
    if (applicable.isNotEmpty) {
      applicable.sort((a, b) {
        if (a.isShopVoucher && !b.isShopVoucher) return -1;
        if (!a.isShopVoucher && b.isShopVoucher) return 1;
        return b.discountAmount.compareTo(a.discountAmount);
      });
      bestVoucher = applicable.first;
    }

    Voucher? nextTargetVoucher;
    if (bestVoucher == null && allVouchers.isNotEmpty) {
      final potential = allVouchers
          .where(
            (v) =>
                v.isActive &&
                (v.platform == 'Tất cả' || v.platform == platform) &&
                (!v.isShopVoucher ||
                    (shopName != null &&
                        v.shopName!.toLowerCase().contains(shopName.toLowerCase()))),
          )
          .toList();
      if (potential.isNotEmpty) {
        potential.sort((a, b) => a.minOrder.compareTo(b.minOrder));
        nextTargetVoucher = potential.first;
      }
    }

    if (bestVoucher == null && nextTargetVoucher == null) {
      return const SizedBox.shrink();
    }
    final cardBg = AppSemanticColors.of(context).cardSurface;
    final isShopee = platform == 'Shopee';
    final brandColor = isShopee
        ? AppSemanticColors.of(context).shopeeBrand
        : AppSemanticColors.of(context).lazadaBrand;

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
            color: brandColor.withValues(
              alpha: AppSemanticColors.of(context).brandShadow.a,
            ),
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
                padding: const EdgeInsets.all(AppDimens.space6),
                decoration: BoxDecoration(
                  color: brandColor.withValues(alpha: 0.12),
                  borderRadius: AppDimens.borderSmall,
                ),
                child: Icon(
                  Icons.local_offer_rounded,
                  color: brandColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppDimens.space8),
              Expanded(
                child: Wrap(
                  spacing: AppDimens.space6,
                  runSpacing: AppDimens.space4,
                  children: [
                    Text(
                      'Mã giảm giá $platform',
                      style: AppTextStyles.titleMedium
                          .themed(context)
                          .copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppSemanticColors.of(context).textPrimary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.space6,
                        vertical: AppDimens.space2,
                      ),
                      decoration: BoxDecoration(
                        color: AppSemanticColors.of(context).success
                            .withValues(alpha: 0.15),
                        borderRadius: AppDimens.borderSmall,
                      ),
                      child: Text(
                        'Đủ điều kiện',
                        style: AppTextStyles.caption
                            .themed(context)
                            .copyWith(
                              color: AppSemanticColors.of(context).success,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              if (applicable.length > 1)
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(
                      AppDimens.minTouchTarget,
                      AppDimens.minTouchTarget,
                    ),
                  ),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  child: Text(
                    _isExpanded
                        ? 'Thu gọn'
                        : '+${applicable.length - 1} mã khác',
                    style: AppTextStyles.labelMedium
                        .themed(context)
                        .copyWith(
                          color: AppSemanticColors.of(context).info,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimens.space12),

          // Main Voucher Showcase
          if (bestVoucher != null) ...[
            // Banner gợi ý giá sau khi áp voucher
            if (price > 0) ...[
              Container(
                margin: const EdgeInsets.only(bottom: AppDimens.space12),
                padding: const EdgeInsets.all(AppDimens.space12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      brandColor.withValues(alpha: 0.12),
                      AppSemanticColors.of(context).success.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: AppDimens.borderMedium,
                  border: Border.all(
                    color: brandColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: brandColor,
                      size: 22,
                    ),
                    const SizedBox(width: AppDimens.space8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Giá sau áp voucher:',
                                style: AppTextStyles.caption.themed(context).copyWith(
                                      color: AppSemanticColors.of(context).textSecondary,
                                    ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                formatVnd(price),
                                style: AppTextStyles.caption.themed(context).copyWith(
                                      decoration: TextDecoration.lineThrough,
                                      color: AppSemanticColors.of(context).textSecondary,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                formatVnd(
                                  (price - bestVoucher.discountAmount) > 0
                                      ? (price - bestVoucher.discountAmount)
                                      : 0,
                                ),
                                style: AppTextStyles.titleMedium.themed(context).copyWith(
                                      color: AppSemanticColors.of(context).success,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppSemanticColors.of(context).success,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Tiết kiệm ${formatVnd(bestVoucher.discountAmount)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            _buildVoucherRow(context, bestVoucher, brandColor),
          ] else if (nextTargetVoucher != null) ...[
            // Mẹo đạt điều kiện áp mã
            Container(
              padding: const EdgeInsets.all(AppDimens.space12),
              decoration: BoxDecoration(
                color: AppSemanticColors.of(context).mutedSurface,
                borderRadius: AppDimens.borderMedium,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: AppSemanticColors.of(context).warning,
                  ),
                  const SizedBox(width: AppDimens.space8),
                  Expanded(
                    child: Text(
                      'Mã ${nextTargetVoucher.code} cần thêm ${formatVnd(nextTargetVoucher.minOrder - price)} để đạt mức đơn tối thiểu (giảm ${formatVnd(nextTargetVoucher.discountAmount)}).',
                      style: AppTextStyles.bodyMedium
                          .themed(context)
                          .copyWith(
                            color: AppSemanticColors.of(context).textBody,
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
            ...applicable
                .skip(1)
                .map(
                  (v) => Padding(
                    padding: const EdgeInsets.only(top: AppDimens.space8),
                    child: _buildVoucherRow(
                      context,
                      v,
                      brandColor,
                      isSecondary: true,
                    ),
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
    Color brandColor, {
    bool isSecondary = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space12),
      decoration: BoxDecoration(
        color: AppSemanticColors.of(context).mutedSurface,
        borderRadius: AppDimens.borderMedium,
        border: Border.all(
          color: isSecondary
              ? AppSemanticColors.of(context).divider
              : brandColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppDimens.space8,
                  runSpacing: AppDimens.space4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Code Box
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.space8,
                        vertical: AppDimens.space4,
                      ),
                      decoration: BoxDecoration(
                        color: AppSemanticColors.of(context).cardSurface,
                        borderRadius: AppDimens.borderSmall,
                        border: Border.all(
                          color: brandColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        voucher.code,
                        style: AppTextStyles.bodyMedium.withInheritedColor
                            .copyWith(
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                              color: brandColor,
                            ),
                      ),
                    ),
                    if (voucher.isShopVoucher)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: brandColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Mã Shop: ${voucher.shopName}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: brandColor,
                          ),
                        ),
                      ),
                    Text(
                      'Giảm ${formatVnd(voucher.discountAmount)}',
                      style: AppTextStyles.labelLarge
                          .themed(context)
                          .copyWith(
                            color: AppSemanticColors.of(context).success,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.space6),
                Text(
                  voucher.title,
                  style: AppTextStyles.bodyMedium
                      .themed(context)
                      .copyWith(
                        color: AppSemanticColors.of(context).textBody,
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDimens.space4),
                Text(
                  'Đơn tối thiểu ${formatVnd(voucher.minOrder)} · Hạn đến ${voucher.validUntil}',
                  style: AppTextStyles.caption
                      .themed(context)
                      .copyWith(
                        color: AppSemanticColors.of(context).textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimens.space8),
          InkWell(
            borderRadius: AppDimens.borderSmall,
            onTap: () {
              Clipboard.setData(ClipboardData(text: voucher.code));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Đã sao chép mã ${voucher.code} để dùng trên ${voucher.platform}.',
                    style: TextStyle(
                      color: AppSemanticColors.of(context).onBrandButton,
                    ),
                  ),
                  backgroundColor: brandColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              constraints: const BoxConstraints(
                minWidth: AppDimens.minTouchTarget,
                minHeight: AppDimens.minTouchTarget,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space12,
                vertical: AppDimens.space8,
              ),
              decoration: BoxDecoration(
                color: brandColor,
                borderRadius: AppDimens.borderSmall,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.copy_rounded,
                    size: 14,
                    color: AppSemanticColors.of(context).onBrandButton,
                  ),
                  const SizedBox(width: AppDimens.space4),
                  Text(
                    'Lưu mã',
                    style: AppTextStyles.labelMedium.withInheritedColor
                        .copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppSemanticColors.of(context).onBrandButton,
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
