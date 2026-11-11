import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../models/buying_motive.dart';
import '../models/item_suggestion.dart';
import '../models/price_snapshot.dart';
import '../models/purchase_item.dart';
import '../models/wishlist_item.dart';
import '../models/wishlist_status.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/motive_colors.dart';
import '../viewmodels/decision_support_viewmodel.dart';
import '../viewmodels/wishlist_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/decision_card_panel.dart';
import '../widgets/demo_data_badge.dart';
import '../widgets/item_suggestions.dart';
import '../widgets/motive_chip.dart';
import '../widgets/price_history_panel.dart';
import '../widgets/price_update_sheet.dart';
import '../widgets/product_image.dart';
import '../widgets/review_date_sheet.dart';
import '../widgets/same_product_card.dart';
import '../widgets/shopee_rating_line.dart';
import '../widgets/undo_snack_bar.dart';
import '../widgets/voucher_suggestion_card.dart';
import '../widgets/why_i_buy_logo.dart';
import '../widgets/wishlist_card.dart';

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

  /// Runs one decision write; success and failure are only reported after the write returns
  Future<bool> _run(
    Future<bool> Function(WishlistViewModel vm) action, {
    required VoidCallback onRetry,
  }) async {
    if (!mounted || _isProcessing) return false;
    setState(() => _isProcessing = true);
    final vm = context.read<WishlistViewModel>();
    final ok = await action(vm);
    if (!mounted) return ok;
    setState(() => _isProcessing = false);
    if (!ok) {
      _showRetry(
        ScaffoldMessenger.of(context),
        vm.actionError ?? 'Chưa lưu được quyết định.',
        onRetry,
      );
    }
    return ok;
  }

  static void _showRetry(
    ScaffoldMessengerState messenger,
    String message,
    VoidCallback onRetry,
  ) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          persist: false,
          action: SnackBarAction(label: 'Thử lại', onPressed: onRetry),
        ),
      );
  }

  /// "Chờ": pick a review date, stay on the screen so the chosen date is visible
  Future<void> _wait(WishlistItem item) async {
    if (_isProcessing) return;
    final vm = context.read<WishlistViewModel>();
    final reviewAt = await ReviewDateSheet.show(
      context,
      defaultDays: vm.coolingOffDays,
      current: item.reviewAt,
      sale: context.read<DecisionSupportViewModel?>()?.nextConfirmedSale,
    );
    if (reviewAt == null || !mounted) return;
    await _saveReviewDate(item, reviewAt);
  }

  Future<void> _saveReviewDate(WishlistItem item, DateTime reviewAt) async {
    if (!mounted) return;
    final vm = context.read<WishlistViewModel>();
    final ok = await _run(
      (vm) => vm.wait(item, reviewAt),
      onRetry: () => _saveReviewDate(item, reviewAt),
    );
    if (!ok || !mounted) return;
    // Permission is asked here, right after the user chose to be reminded (spec 4.1 A-09)
    final permission = await vm.requestReminderPermission();
    if (!mounted) return;
    final date = formatWeekdayDate(reviewAt);
    final message = switch (permission) {
      ReminderPermission.granted =>
        'Đã hẹn xem lại vào $date. App sẽ nhắc bạn hôm đó.',
      ReminderPermission.denied =>
        'Đã hẹn xem lại vào $date. Thông báo đang tắt nên món sẽ hiện trong mục "Cần xem lại".',
      ReminderPermission.unsupported =>
        'Đã hẹn xem lại vào $date. Hôm đó món sẽ hiện trong mục "Cần xem lại".',
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  /// "Bỏ qua": back to the list with a 5-second "Hoàn tác"
  Future<void> _skip(WishlistItem item) async {
    final ok = await _run((vm) => vm.skip(item), onRetry: () => _skip(item));
    if (!ok || !mounted) return;
    final vm = context.read<WishlistViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    // The messenger outlives this route, so the undo stays available after pop
    showUndoSnackBar(context, 'Đã bỏ qua "${item.title}".', () {
      _undoSkip(vm, messenger, item);
    });
    Navigator.of(context).pop();
  }

  static Future<void> _undoSkip(
    WishlistViewModel vm,
    ScaffoldMessengerState messenger,
    WishlistItem item,
  ) async {
    final ok = await vm.reconsider(item);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Đã đưa "${item.title}" về Đang cân nhắc.'
                : vm.actionError ?? 'Chưa hoàn tác được.',
          ),
          behavior: SnackBarBehavior.floating,
          persist: false,
          action: ok
              ? null
              : SnackBarAction(
                  label: 'Thử lại',
                  onPressed: () => _undoSkip(vm, messenger, item),
                ),
        ),
      );
  }

  /// Decision Card label 5 (spec 7.4): the user marks the item as (not) a duplicate
  Future<void> _setDuplicate(WishlistItem item, bool value) async {
    final ok = await _run(
      (vm) => vm.setConfirmedDuplicate(item, value),
      onRetry: () => _setDuplicate(item, value),
    );
    if (!ok || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Đã đánh dấu món trùng với đồ bạn đã có.'
                : 'Đã bỏ đánh dấu trùng.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// A skipped item can be considered again later
  Future<void> _reconsider(WishlistItem item) async {
    final ok = await _run(
      (vm) => vm.reconsider(item),
      onRetry: () => _reconsider(item),
    );
    if (!ok || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Món đã về Đang cân nhắc.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// Spec 6.5: a price older than 7 days is shown as old and should be confirmed again
  static const int _stalePriceDays = 7;

  static String _priceNote(WishlistItem item) {
    final at = item.latestPriceAt;
    if (!item.hasPrice) return 'Bạn chưa ghi giá cho món này.';
    if (at == null) return 'Giá bạn đã ghi.';
    final days = DateTime.now().difference(at).inDays;
    return 'Giá ghi ngày ${formatDate(at)}'
        '${days > _stalePriceDays ? ' · đã $days ngày, giá hiện tại có thể khác' : ''}';
  }

  Future<void> _updatePrice(WishlistItem item) async {
    final amount = await PriceUpdateSheet.show(
      context,
      currentPrice: item.latestPriceVnd,
      currentPriceAt: item.latestPriceAt,
    );
    if (amount == null || !mounted) return;
    await _savePrice(item, amount);
  }

  Future<void> _savePrice(WishlistItem item, int amount) async {
    final confirmed = amount == item.latestPriceVnd;
    final ok = await _run(
      (vm) => vm.updatePrice(item, amount),
      onRetry: () => _savePrice(item, amount),
    );
    if (!ok || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            confirmed
                ? 'Đã xác nhận giá ${formatVnd(amount)} hôm nay.'
                : 'Đã lưu giá ${formatVnd(amount)}.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// Spec 8.3: other people's price is only a suggestion; it becomes this item's price
  /// only after the user confirms, and is then never shared again (source community)
  Future<void> _useSharedPrice(WishlistItem item, int amount) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Dùng giá ${formatVnd(amount)}?',
      message:
          'Đây là trung vị giá người khác ghi cho cùng sản phẩm và phân loại. '
          'Giá trên Shopee có thể đã đổi; bạn nên mở link kiểm tra lại.',
      confirmLabel: 'Dùng giá này',
    );
    if (!ok || !mounted) return;
    await _saveSharedPrice(item, amount);
  }

  Future<void> _saveSharedPrice(WishlistItem item, int amount) async {
    final saved = await _run(
      (vm) => vm.updatePrice(item, amount, source: PriceSource.community),
      onRetry: () => _saveSharedPrice(item, amount),
    );
    if (!saved || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Đã lưu giá ${formatVnd(amount)} (từ giá người khác ghi).',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _confirmDelete(WishlistItem item) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Xoá món này?',
      message:
          'Xoá "${item.title}" và lịch sử giá đã ghi khỏi danh sách mong muốn.'
          '${item.purchaseId != null ? '\n\nKhoản mua đã ghi từ món này vẫn được giữ trong Lịch sử.' : ''}',
      confirmLabel: 'Xoá',
      isDanger: true,
    );
    if (!confirmed || !mounted) return;
    await _deleteItem(item);
  }

  Future<void> _deleteItem(WishlistItem item) async {
    final ok = await _run(
      (vm) => vm.deleteItem(item),
      onRetry: () => _deleteItem(item),
    );
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Đã xoá "${item.title}".'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
    final wishlistVm = context.watch<WishlistViewModel>();
    final item = _currentItem(wishlistVm);
    final currentTokens = titleTokens(item.title);
    final matchingShopItems = wishlistVm.allItems.where((other) {
      if (other.id == item.id) return false;
      final otherTokens = titleTokens(other.title);
      return compareTitles(currentTokens, otherTokens) ==
          TitleSimilarity.likely;
    }).toList();
    final canDecide = item.status == WishlistStatus.considering;
    final needsPurchase =
        item.status == WishlistStatus.purchased && item.purchaseId == null;

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leadingWidth: AppDimens.minTouchTarget,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.chevron_left_rounded, size: 30),
          tooltip: 'Quay lại',
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            const WhyIBuyLogo(size: 26, color: AppColors.onPrimary),
            const SizedBox(width: AppDimens.space4),
            Flexible(
              child: Text(
                'Chi tiết & Quyết định',
                style: AppTextStyles.titleLarge.withInheritedColor.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sửa thông tin món',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _isProcessing
                ? null
                : () => Navigator.pushNamed(
                    context,
                    AppRoutes.wishlistEdit,
                    arguments: ItemDetailArgs(item),
                  ),
          ),
          IconButton(
            tooltip: 'Xoá món',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _isProcessing ? null : () => _confirmDelete(item),
          ),
        ],
      ),
      body: SingleChildScrollView(
        // Edge-to-edge (Android 15+): the last buttons stay above the navigation bar
        padding: EdgeInsets.fromLTRB(
          AppDimens.space16,
          AppDimens.space16,
          AppDimens.space16,
          AppDimens.space16 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimens.space20),
              decoration: BoxDecoration(
                // Theme surface and text colours: readable in dark mode too
                color: theme.colorScheme.surface,
                borderRadius: AppDimens.borderLarge,
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ProductImage.canShow(item.imageUrl)) ...[
                    Center(
                      child: ProductImage(
                        url: item.imageUrl,
                        size: 160,
                        borderRadius: AppDimens.borderLarge,
                      ),
                    ),
                    const SizedBox(height: AppDimens.space16),
                  ],
                  Text(
                    item.title,
                    style: AppTextStyles.headlineMedium.themed(context),
                  ),
                  if (item.variantLabel != null) ...[
                    const SizedBox(height: AppDimens.space4),
                    Text(
                      'Phân loại: ${item.variantLabel}',
                      style: AppTextStyles.bodyMedium.themed(context),
                    ),
                  ],
                  // Ratings the extension read on Shopee; nothing when unknown
                  if (item.productRating != null ||
                      item.shopRating != null) ...[
                    const SizedBox(height: AppDimens.space4),
                    ShopeeRatingLine(
                      key: const ValueKey('item-ratings'),
                      productRating: item.productRating,
                      productRatingCount: item.productRatingCount,
                      shopName: item.shopName,
                      shopRating: item.shopRating,
                    ),
                  ],
                  if (item.shopName != null) ...[
                    const SizedBox(height: AppDimens.space4),
                    Text(
                      'Shop: ${item.shopName}',
                      style: AppTextStyles.bodyMedium.themed(context),
                    ),
                  ],
                  if (item.vouchers case final vouchers?
                      when vouchers.isNotEmpty) ...[
                    const SizedBox(height: AppDimens.space8),
                    Text(
                      'Voucher đã lưu'
                      '${item.vouchersAt != null ? ' (${formatDate(item.vouchersAt!)})' : ''}:',
                      style: AppTextStyles.bodyMedium.themed(context),
                    ),
                    for (final v in vouchers)
                      Text(
                        '• $v',
                        style: AppTextStyles.caption.themed(context),
                      ),
                  ],
                  const SizedBox(height: AppDimens.space12),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppDimens.space8,
                    runSpacing: AppDimens.space8,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatVnd(item.latestPriceVnd),
                            style: item.hasPrice
                                ? AppTextStyles.displayMedium
                                      .themed(context)
                                      .copyWith(
                                        color: theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.w700,
                                      )
                                : AppTextStyles.titleLarge
                                      .themed(context)
                                      .copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                          ),
                          const SizedBox(height: AppDimens.space2),
                          Text(
                            _priceNote(item),
                            style: AppTextStyles.caption
                                .themed(context)
                                .copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                      if (item.status != WishlistStatus.purchased)
                        Material(
                          color: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppDimens.borderXLarge,
                            side: BorderSide(
                              color: AppSemanticColors.of(context).inputBorder,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: _isProcessing
                                ? null
                                : () => _updatePrice(item),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimens.space12,
                                vertical: AppDimens.space6,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 14,
                                    color: AppSemanticColors.of(context)
                                        .mutedText,
                                  ),
                                  const SizedBox(width: AppDimens.space4),
                                  Text(
                                    item.hasPrice ? 'Cập nhật giá' : 'Nhập giá',
                                    style: AppTextStyles.labelMedium
                                        .themed(context)
                                        .copyWith(
                                          color: AppSemanticColors.of(context)
                                              .mutedText,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.space12),
                  Divider(height: 1, color: theme.dividerColor),
                  const SizedBox(height: AppDimens.space12),
                  Wrap(
                    spacing: AppDimens.space8,
                    runSpacing: AppDimens.space8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      MotiveChip(motive: item.displayMotive),
                      Builder(
                        builder: (context) {
                          final insights = context
                              .watch<DecisionSupportViewModel?>()
                              ?.priceInsightsFor(item);
                          final hasDeal = insights?.hasGoodDeal ?? false;
                          final savings = insights?.goodDealSavingsVnd ?? 0;
                          if (!hasDeal) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppSemanticColors.of(context)
                                  .error
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppSemanticColors.of(context)
                                    .error
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🔥', style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 4),
                                Text(
                                  savings > 0
                                      ? 'Giá hời · Giảm ${formatVnd(savings)} so với lúc lưu'
                                      : 'Giá hời',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppSemanticColors.of(context).error,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      if (item.isDemo) ...[const DemoDataBadge()],
                      if (item.shopName != null &&
                          item.shopName!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.space8,
                            vertical: AppDimens.space4,
                          ),
                          decoration: BoxDecoration(
                            color: AppSemanticColors.of(context).cardSurface,
                            borderRadius: AppDimens.borderMedium,
                            border: Border.all(
                              color: AppSemanticColors.of(context).divider,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.storefront_outlined,
                                size: 13,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: AppDimens.space4),
                              Flexible(
                                child: Text(
                                  item.shopName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.labelMedium
                                      .themed(context)
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (item.isFromExtension) ...[
                        WishlistCard.fromExtensionChip(context),
                      ],
                      Wrap(
                        spacing: AppDimens.space8,
                        runSpacing: AppDimens.space8,

                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppDimens.space4),
                          Text(
                            'Lưu ngày: ${formatDate(item.createdAt)}',
                            style: AppTextStyles.labelMedium
                                .themed(context)
                                .copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space20),

            // G6b: the one place for the item's prices: the chart ("Giá tham khảo"
            // with the user's own prices, or only their own), every recorded price
            // (A-14, spec 6.5) and "Giá người khác ghi" (spec 8.3)
            PriceHistoryPanel(
              item: item,
              showSharedPrices: item.status == WishlistStatus.considering,
              onUsePrice: _isProcessing
                  ? null
                  : (amount) => _useSharedPrice(item, amount),
              onAddLink: _isProcessing
                  ? null
                  : () => Navigator.pushNamed(
                      context,
                      AppRoutes.wishlistEdit,
                      arguments: ItemDetailArgs(item),
                    ),
            ),

            // G8: the same item and variant in other shops (automatic match)
            if (item.productKey != null) SameProductCard(item: item),

            // Voucher & promotion suggestions from Admin / Shopee / Lazada
            VoucherSuggestionCard(item: item),

            // Comparison between multiple shops in Wishlist
            _ShopPriceComparisonSection(
              currentItem: item,
              matchingItems: matchingShopItems,
            ),

            // Psychological Cooldown Box
            if (item.isInCooldown) ...[
              Container(
                padding: const EdgeInsets.all(AppDimens.space16),
                decoration: BoxDecoration(
                  color: MotiveColors.of(context)
                      .paletteOf(BuyingMotive.emotion)
                      .background,
                  borderRadius: AppDimens.borderMedium,
                  border: Border.all(
                    color: MotiveColors.of(context)
                        .paletteOf(BuyingMotive.emotion)
                        .foreground
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.hourglass_top,
                      color: MotiveColors.of(context)
                          .paletteOf(BuyingMotive.emotion)
                          .foreground,
                      size: 28,
                    ),
                    const SizedBox(width: AppDimens.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đang trong thời gian cân nhắc',
                            style: AppTextStyles.labelLarge
                                .themed(context)
                                .copyWith(
                                  color: MotiveColors.of(context)
                                      .paletteOf(BuyingMotive.emotion)
                                      .foreground,
                                ),
                          ),
                          Text(
                            'Mốc cân nhắc: ${formatTime(item.cooldownUntil!)} ngày ${formatDate(item.cooldownUntil!)}. Bạn có thể chọn hành động bất cứ lúc nào.',
                            style: AppTextStyles.bodyMedium.themed(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.space20),
            ],

            if (canDecide)
              DuplicateHint(
                title: item.title,
                excludeItemId: item.id,
                budgetGroupId: item.budgetGroupId,
                onConfirmDuplicate: item.confirmedDuplicate
                    ? null
                    : () => _setDuplicate(item, true),
              ),

            // Decision Card (Why I Buy Core)
            Text(
              'Thẻ quyết định',
              style: AppTextStyles.titleLarge.themed(context),
            ),
            const SizedBox(height: AppDimens.space8),
            Text(
              'Mua mở form ghi khoản đã mua. Chờ đặt ngày xem lại. Bỏ qua có thể hoàn tác.',
              style: AppTextStyles.bodyMedium.themed(context),
            ),
            const SizedBox(height: AppDimens.space16),
            if (canDecide)
              DecisionCardPanel(
                item: item,
                onSetDuplicate: (value) => _setDuplicate(item, value),
              ),

            if (needsPurchase) ...[
              Text(
                'Món đã được đánh dấu mua nhưng chưa có khoản thực chi. Bạn có thể bổ sung khoản mua.',
                style: AppTextStyles.bodyMedium.themed(context),
              ),
              const SizedBox(height: AppDimens.space12),
            ],
            if (canDecide && item.reviewAt != null) ...[
              _ReviewInfo(item: item),
              const SizedBox(height: AppDimens.space16),
            ],
            // Mua · Chờ · Bỏ qua: 3 buttons side-by-side in 1 row with distinct intuitive colors
            if (canDecide) ...[
              Row(
                children: [
                  Expanded(
                    child: _DecisionButton(
                      title: 'Mua',
                      icon: Icons.shopping_bag_outlined,
                      backgroundColor: AppSemanticColors.of(context)
                          .success, // Filled purchase action
                      foregroundColor: AppSemanticColors.of(context)
                          .onStatusFill,
                      isLoading: _isProcessing,
                      onPressed: () => _recordPurchase(item),
                    ),
                  ),
                  const SizedBox(width: AppDimens.space8),
                  Expanded(
                    child: _DecisionButton(
                      title: 'Chờ',
                      icon: Icons.schedule,
                      backgroundColor: AppColors.primary, // Brand yellow
                      foregroundColor: AppColors.onPrimary,
                      isLoading: _isProcessing,
                      onPressed: () => _wait(item),
                    ),
                  ),
                  const SizedBox(width: AppDimens.space8),
                  Expanded(
                    child: _DecisionButton(
                      title: 'Bỏ qua',
                      icon: Icons.do_not_disturb_on_outlined,
                      backgroundColor: AppSemanticColors.of(context)
                          .mutedSurface, // Slate neutral
                      foregroundColor: AppSemanticColors.of(context)
                          .secondaryActionText,
                      borderColor: AppSemanticColors.of(context)
                          .secondaryActionBorder,
                      isLoading: _isProcessing,
                      onPressed: () => _skip(item),
                    ),
                  ),
                ],
              ),
            ] else if (needsPurchase) ...[
              AppButton(
                title: 'Bổ sung khoản mua',
                variant: AppButtonVariant.primary,
                icon: Icons.shopping_bag_outlined,
                isLoading: _isProcessing,
                onPressed: () => _recordPurchase(item),
              ),
            ] else if (item.status == WishlistStatus.skipped) ...[
              Text(
                'Bạn đã quyết định không mua món này'
                '${item.decidedAt == null ? '' : ' ngày ${formatDate(item.decidedAt!)}'}.',
                style: AppTextStyles.bodyMedium.themed(context),
              ),
              const SizedBox(height: AppDimens.space12),
              AppButton(
                title: 'Cân nhắc lại',
                variant: AppButtonVariant.secondary,
                icon: Icons.replay_rounded,
                isLoading: _isProcessing,
                onPressed: () => _reconsider(item),
              ),
            ] else if (!needsPurchase)
              Text(
                item.status.label,
                style: AppTextStyles.titleMedium.themed(context),
              ),
          ],
        ),
      ),
    );
  }
}

/// Review date chosen with "Chờ"; tells the user when it has arrived
class _ReviewInfo extends StatelessWidget {
  final WishlistItem item;

  const _ReviewInfo({required this.item});

  @override
  Widget build(BuildContext context) {
    final reviewAt = item.reviewAt!;
    final text = item.isReviewDue
        ? 'Đã đến ngày xem lại (${formatDate(reviewAt)}). Bạn muốn quyết định thế nào?'
        : 'Bạn hẹn xem lại vào ${formatWeekdayDate(reviewAt)}. Bấm Chờ để đổi ngày.';
    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppSemanticColors.of(context).mutedSurface,
        borderRadius: AppDimens.borderMedium,
      ),
      child: Row(
        children: [
          Icon(
            item.isReviewDue
                ? Icons.notifications_active_outlined
                : Icons.event,
            color: AppSemanticColors.of(context).accent,
          ),
          const SizedBox(width: AppDimens.space12),
          Expanded(
            child: Text(text, style: AppTextStyles.bodyMedium.themed(context)),
          ),
        ],
      ),
    );
  }
}

/// Compact decision button for the 3-column action row ("Mua" · "Chờ" · "Bỏ qua")
class _DecisionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _DecisionButton({
    required this.title,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
    this.isLoading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimens.space48,
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimens.borderLarge,
          side: borderColor != null
              ? BorderSide(color: borderColor!, width: 1.2)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: AppDimens.space20,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        foregroundColor,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 17, color: foregroundColor),
                      const SizedBox(width: AppDimens.space6),
                      Text(
                        title,
                        style: AppTextStyles.bodyMedium.withInheritedColor
                            .copyWith(
                              color: foregroundColor,

                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Section displaying price comparison across different shops for the same product
class _ShopPriceComparisonSection extends StatelessWidget {
  final WishlistItem currentItem;
  final List<WishlistItem> matchingItems;

  const _ShopPriceComparisonSection({
    required this.currentItem,
    required this.matchingItems,
  });

  @override
  Widget build(BuildContext context) {
    if (matchingItems.isEmpty) return const SizedBox.shrink();

    final allOffers = [currentItem, ...matchingItems];
    final validPrices = allOffers.where((i) => i.hasPrice).toList()
      ..sort((a, b) => a.latestPriceVnd!.compareTo(b.latestPriceVnd!));

    final lowestItem = validPrices.isNotEmpty ? validPrices.first : null;
    final highestItem = validPrices.length > 1 ? validPrices.last : null;
    final savings = (lowestItem != null && highestItem != null)
        ? highestItem.latestPriceVnd! - lowestItem.latestPriceVnd!
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.space20),
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppSemanticColors.of(context).cardSurface,
        borderRadius: AppDimens.borderMedium,
        border: Border.all(color: AppSemanticColors.of(context).divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.compare_arrows_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppDimens.space8),
              Expanded(
                child: Text(
                  'So sánh giá các cửa hàng (${allOffers.length} shop)',
                  style: AppTextStyles.titleMedium
                      .themed(context)
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space12),
          ...allOffers.map((offer) {
            final isCurrent = offer.id == currentItem.id;
            final isLowest =
                lowestItem != null &&
                offer.id == lowestItem.id &&
                validPrices.length > 1;
            final shopTitle = offer.shopName?.isNotEmpty == true
                ? offer.shopName!
                : (offer.url?.contains('shopee') == true
                      ? 'Shopee'
                      : 'Cửa hàng khác');

            return Container(
              margin: const EdgeInsets.only(bottom: AppDimens.space8),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space12,
                vertical: AppDimens.space8,
              ),
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : AppSemanticColors.of(context).background,
                borderRadius: AppDimens.borderSmall,
                border: Border.all(
                  color: isLowest
                      ? AppSemanticColors.of(context).success
                      : (isCurrent
                            ? AppColors.primary.withValues(alpha: 0.4)
                            : AppSemanticColors.of(context).divider),
                  width: isLowest ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.storefront_outlined,
                    size: 18,
                    color: isLowest
                        ? AppSemanticColors.of(context).success
                        : AppSemanticColors.of(context).textSecondary,
                  ),
                  const SizedBox(width: AppDimens.space8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: AppDimens.space8,
                          runSpacing: AppDimens.space8,
                          children: [
                            SizedBox(
                              child: Text(
                                shopTitle,
                                style: AppTextStyles.bodyMedium
                                    .themed(context)
                                    .copyWith(
                                      fontWeight: isCurrent || isLowest
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: AppDimens.space6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimens.space6,
                                  vertical: AppDimens.space2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: AppDimens.borderSmall,
                                ),
                                child: Text(
                                  'Đang xem',
                                  style: AppTextStyles
                                      .caption
                                      .withInheritedColor
                                      .copyWith(
                                        color: AppSemanticColors.of(context)
                                            .brandText,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                            if (isLowest) ...[
                              const SizedBox(width: AppDimens.space6),
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
                                  'Giá thấp nhất',
                                  style: AppTextStyles
                                      .caption
                                      .withInheritedColor
                                      .copyWith(
                                        color: AppSemanticColors.of(context)
                                            .success,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (offer.url != null && offer.url!.isNotEmpty)
                          Text(
                            offer.url!,
                            style: AppTextStyles.caption
                                .themed(context)
                                .copyWith(
                                  color: AppSemanticColors.of(context)
                                      .textSecondary,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: AppDimens.space4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            formatVnd(offer.latestPriceVnd),
                            style: AppTextStyles.titleMedium
                                .themed(context)
                                .copyWith(
                                  color: isLowest
                                      ? AppSemanticColors.of(context).success
                                      : AppSemanticColors.of(context)
                                            .textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          if (savings > 0 && lowestItem != null) ...[
            const SizedBox(height: AppDimens.space6),
            Container(
              padding: const EdgeInsets.all(AppDimens.space8),
              decoration: BoxDecoration(
                color: AppSemanticColors.of(context).success
                    .withValues(alpha: 0.1),
                borderRadius: AppDimens.borderSmall,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.savings_outlined,
                    color: AppSemanticColors.of(context).success,
                    size: 18,
                  ),
                  const SizedBox(width: AppDimens.space8),
                  Expanded(
                    child: Text(
                      'Chênh lệch giá ghi nhận: ${formatVnd(savings)} so với ${lowestItem.shopName ?? 'cửa hàng khác'}.',
                      style: AppTextStyles.caption
                          .themed(context)
                          .copyWith(
                            color: AppSemanticColors.of(context).savingsText,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
