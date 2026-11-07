import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../models/item_suggestion.dart';
import '../models/price_snapshot.dart';
import '../models/purchase_item.dart';
import '../models/wishlist_item.dart';
import '../models/wishlist_status.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/decision_support_viewmodel.dart';
import '../viewmodels/wishlist_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/decision_card_panel.dart';
import '../widgets/item_suggestions.dart';
import '../widgets/motive_chip.dart';
import '../widgets/price_history_entry_card.dart';
import '../widgets/price_history_panel.dart';
import '../widgets/price_update_sheet.dart';
import '../widgets/product_image.dart';
import '../widgets/review_date_sheet.dart';
import '../widgets/same_product_card.dart';
import '../widgets/shared_price_section.dart';
import '../widgets/shopee_rating_line.dart';
import '../widgets/undo_snack_bar.dart';
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
  Future<bool> _run(Future<bool> Function(WishlistViewModel vm) action) async {
    if (_isProcessing) return false;
    setState(() => _isProcessing = true);
    final vm = context.read<WishlistViewModel>();
    final ok = await action(vm);
    if (!mounted) return ok;
    setState(() => _isProcessing = false);
    if (!ok) {
      _showRetry(
        ScaffoldMessenger.of(context),
        vm.actionError ?? 'Chưa lưu được quyết định.',
        () => _run(action),
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
    final ok = await _run((vm) => vm.wait(item, reviewAt));
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
    final ok = await _run((vm) => vm.skip(item));
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
    final ok = await _run((vm) => vm.setConfirmedDuplicate(item, value));
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
    final ok = await _run((vm) => vm.reconsider(item));
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
    final confirmed = amount == item.latestPriceVnd;
    final ok = await _run((vm) => vm.updatePrice(item, amount));
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
    final saved = await _run(
      (vm) => vm.updatePrice(item, amount, source: PriceSource.community),
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
    final ok = await _run((vm) => vm.deleteItem(item));
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết & Quyết định'),
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
                  Text(item.title, style: AppTextStyles.headlineMedium),
                  if (item.variantLabel != null) ...[
                    const SizedBox(height: AppDimens.space4),
                    Text(
                      'Phân loại: ${item.variantLabel}',
                      style: AppTextStyles.bodyMedium,
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
                  const SizedBox(height: AppDimens.space12),
                  Text(
                    formatVnd(item.latestPriceVnd),
                    style: item.hasPrice
                        ? AppTextStyles.displayMedium.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w700,
                          )
                        : AppTextStyles.titleLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                  ),
                  const SizedBox(height: AppDimens.space4),
                  Text(_priceNote(item), style: AppTextStyles.labelMedium),
                  if (item.status != WishlistStatus.purchased)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, AppDimens.minTouchTarget),
                        foregroundColor: AppColors.accentNeutral,
                      ),
                      onPressed: _isProcessing
                          ? null
                          : () => _updatePrice(item),
                      icon: const Icon(Icons.price_change_outlined, size: 18),
                      label: Text(item.hasPrice ? 'Cập nhật giá' : 'Nhập giá'),
                    ),
                  const SizedBox(height: AppDimens.space8),
                  Wrap(
                    spacing: AppDimens.space12,
                    runSpacing: AppDimens.space8,
                    children: [
                      MotiveChip(motive: item.displayMotive),
                      if (item.shopName != null && item.shopName!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.storefront_outlined,
                                size: 13,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.shopName!,
                                style: AppTextStyles.labelMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (item.isFromExtension)
                        WishlistCard.fromExtensionChip(),
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

            // A-14: every recorded price, compared only when it makes sense (spec 6.5)
            if (item.hasPrice) PriceHistoryPanel(item: item),

            // "Giá tham khảo" from priceHistory; nothing without data
            if (item.productKey case final key?) ...[
              PriceHistoryEntryCard(productKey: key, item: item),
              // G8: the same item and variant in other shops (automatic match)
              SameProductCard(item: item),
            ],

            // Spec 8.3: anonymous prices other people recorded for the same variant
            if (item.status == WishlistStatus.considering)
              SharedPriceSection(
                item: item,
                onUsePrice: _isProcessing
                    ? null
                    : (amount) => _useSharedPrice(item, amount),
              ),

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
              'Thẻ Quyết Định (Decision Card)',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: AppDimens.space8),
            Text(
              'Sau khi suy ngẫm, bạn lựa chọn hành động nào cho món đồ này?',
              style: AppTextStyles.bodyMedium,
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
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppDimens.space12),
            ],
            if (canDecide && item.reviewAt != null) ...[
              _ReviewInfo(item: item),
              const SizedBox(height: AppDimens.space16),
            ],
            // Mua · Chờ · Bỏ qua: same variant and size, none is highlighted (spec 7.4)
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
                onPressed: () => _wait(item),
              ),
              const SizedBox(height: AppDimens.space12),
              AppButton(
                title: 'Bỏ qua',
                variant: AppButtonVariant.secondary,
                icon: Icons.do_not_disturb_on_outlined,
                isLoading: _isProcessing,
                onPressed: () => _skip(item),
              ),
            ] else if (item.status == WishlistStatus.skipped) ...[
              Text(
                'Bạn đã quyết định không mua món này'
                '${item.decidedAt == null ? '' : ' ngày ${formatDate(item.decidedAt!)}'}.',
                style: AppTextStyles.bodyMedium,
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
              Text(item.status.label, style: AppTextStyles.titleMedium),
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
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppDimens.borderMedium,
      ),
      child: Row(
        children: [
          Icon(
            item.isReviewDue
                ? Icons.notifications_active_outlined
                : Icons.event,
            color: AppColors.accentNeutral,
          ),
          const SizedBox(width: AppDimens.space12),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
        ],
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
        color: AppColors.surface,
        borderRadius: AppDimens.borderMedium,
        border: Border.all(color: AppColors.divider),
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
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                    : AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isLowest
                      ? const Color(0xFF10B981)
                      : (isCurrent
                            ? AppColors.primary.withValues(alpha: 0.4)
                            : AppColors.divider),
                  width: isLowest ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.storefront_outlined,
                    size: 18,
                    color: isLowest
                        ? const Color(0xFF10B981)
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppDimens.space8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                shopTitle,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: isCurrent || isLowest
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Đang xem',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            if (isLowest) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Rẻ nhất ⭐',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF10B981),
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
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimens.space8),
                  Text(
                    formatVnd(offer.latestPriceVnd),
                    style: AppTextStyles.titleMedium.copyWith(
                      color: isLowest
                          ? const Color(0xFF10B981)
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
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
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.savings_outlined,
                    color: Color(0xFF10B981),
                    size: 18,
                  ),
                  const SizedBox(width: AppDimens.space8),
                  Expanded(
                    child: Text(
                      'Tiết kiệm ${formatVnd(savings)} nếu mua tại ${lowestItem.shopName ?? 'shop rẻ nhất'}!',
                      style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFF047857),
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
