import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../models/price_insights.dart';
import '../models/price_snapshot.dart';
import '../models/ui_state.dart';
import '../models/wishlist_item.dart';
import '../services/price_history_service.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/decision_support_viewmodel.dart';
import '../viewmodels/own_price_view.dart';
import '../viewmodels/price_history_viewmodel.dart';
import '../viewmodels/same_product_viewmodel.dart';
import 'price_history_chart.dart';
import 'price_history_entry_card.dart';
import 'shared_price_section.dart';

/// A-14 "Lịch sử giá" (screen 22.3), the one place for the item's prices on Chi tiết
/// món (G6b): a chart, the neutral comparisons of spec 6.5 / 8.3, every recorded
/// price, and "Giá người khác ghi".
/// - Enough community prices (priceHistory: [PriceHistoryChart.minChartDays] days
///   with ≥ 2 people): the "Giá tham khảo" chart, the user's own prices as small
///   hollow dots ("Giá bạn ghi"), and "Xem toàn màn hình".
/// - Otherwise the chart is drawn from the user's own prices ("Giá bạn đã ghi"), with
///   "Chưa đủ người ghi giá…" when the item has a Shopee link.
/// - Without a Shopee link: "Thêm link Shopee" (items still being considered).
/// Below [PriceHistoryChart.minChartDays] days with a price the chart shows only the
/// milestones. After-voucher prices never enter the chart (N8).
class PriceHistoryPanel extends StatefulWidget {
  final WishlistItem item;

  /// "Giá người khác ghi" and "Thêm link Shopee" (items still being considered)
  final bool showSharedPrices;
  final ValueChanged<int>? onUsePrice;

  /// "Thêm link Shopee": opens the edit screen; null disables the button
  final VoidCallback? onAddLink;

  const PriceHistoryPanel({
    super.key,
    required this.item,
    this.showSharedPrices = false,
    this.onUsePrice,
    this.onAddLink,
  });

  @override
  State<PriceHistoryPanel> createState() => _PriceHistoryPanelState();
}

class _PriceHistoryPanelState extends State<PriceHistoryPanel> {
  PriceHistoryRange _range = PriceHistoryRange.month;

  /// "Giá tham khảo" of the item's Shopee product: a preview, not a chart view
  /// (no analytics)
  PriceHistoryViewModel? _community;

  @override
  void initState() {
    super.initState();
    _load();
    _openCommunity();
  }

  @override
  void didUpdateWidget(covariant PriceHistoryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.latestPriceAt != widget.item.latestPriceAt) _load();
    if (oldWidget.item.productKey != widget.item.productKey) {
      _closeCommunity();
      _openCommunity();
    }
  }

  @override
  void dispose() {
    _closeCommunity();
    super.dispose();
  }

  void _load() {
    if (!widget.item.hasPrice) return;
    context.read<DecisionSupportViewModel?>()?.loadPriceHistory(widget.item);
  }

  void _openCommunity() {
    final key = widget.item.productKey;
    final service = context.read<PriceHistoryService?>();
    if (key == null || service == null) return;
    _community = PriceHistoryViewModel(service: service)
      ..setRange(_range)
      ..addListener(_changed)
      ..openProduct(key);
  }

  void _closeCommunity() {
    _community
      ?..removeListener(_changed)
      ..dispose();
    _community = null;
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _setRange(PriceHistoryRange range) {
    setState(() => _range = range);
    _community?.setRange(range);
  }

  void _openFullScreen(String productKey, SavedPrice? saved) =>
      Navigator.pushNamed(
        context,
        AppRoutes.priceHistory,
        arguments: PriceHistoryArgs(
          productKey: productKey,
          sameProduct: context
              .read<SameProductViewModel?>()
              ?.stateFor(widget.item)
              ?.links,
          savedPrice: saved,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final productKey = item.productKey;
    final decision = context.watch<DecisionSupportViewModel?>();
    final insights = decision?.priceInsightsFor(item);
    final history = insights?.history ?? const <PriceSnapshot>[];
    final askLink = productKey == null && widget.showSharedPrices;
    if (history.isEmpty && productKey == null) {
      return askLink
          ? Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.space16),
              child: _AddLinkHint(onPressed: widget.onAddLink),
            )
          : const SizedBox.shrink();
    }

    final communityState = _community?.state;
    final community = switch (communityState) {
      UiSuccess(:final data)
          when data.summary.daysWithData >= PriceHistoryChart.minChartDays =>
        data,
      _ => null,
    };
    final communityLoaded = communityState is UiSuccess || communityState is UiEmpty;
    final own = ownPriceView(
      history,
      range: _range,
      now: DateTime.now(),
      shopName: item.shopName,
    );
    final saved = savedPriceOf(item, insights);
    final Widget? chart = community != null
        ? PriceHistoryChart(
            key: const ValueKey('price-chart-community'),
            view: community,
            savedPrice: saved,
            onRangeChanged: _setRange,
            ownPrices: ownPriceDots(community, own),
          )
        : history.isNotEmpty
        ? PriceHistoryChart(
            key: const ValueKey('price-chart-own'),
            view: own,
            savedPrice: saved,
            onRangeChanged: _setRange,
            caption: 'Giá bạn đã ghi',
          )
        : null;
    final notes = insights?.notes ?? const <String>[];

    return Card(
      key: const ValueKey('price-history'),
      margin: const EdgeInsets.only(bottom: AppDimens.space16),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline_outlined),
                const SizedBox(width: AppDimens.space8),
                Expanded(
                  child: Text('Lịch sử giá', style: AppTextStyles.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.space12),
            ?chart,
            if (history.length == 1)
              Padding(
                padding: const EdgeInsets.only(top: AppDimens.space8),
                child: Text(
                  'Ghi thêm giá để xem biến động',
                  key: const ValueKey('price-record-more'),
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            if (productKey != null && community == null && communityLoaded)
              Padding(
                padding: const EdgeInsets.only(top: AppDimens.space8),
                child: Text(
                  'Chưa đủ người ghi giá để vẽ đường cộng đồng '
                  '(${_community!.reportCount} lần ghi)',
                  key: const ValueKey('price-community-too-few'),
                  style: AppTextStyles.labelMedium,
                ),
              ),
            if ((productKey, community) case (final key?, _?))
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: const ValueKey('price-fullscreen'),
                  onPressed: () => _openFullScreen(key, saved),
                  icon: const Icon(Icons.open_in_full_rounded, size: 18),
                  label: const Text('Xem toàn màn hình'),
                ),
              ),
            if (askLink)
              Padding(
                padding: const EdgeInsets.only(top: AppDimens.space8),
                child: _AddLinkHint(onPressed: widget.onAddLink),
              ),
            if (notes.isNotEmpty) ...[
              const Divider(height: AppDimens.space24),
              for (final note in notes)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppDimens.space4),
                  child: Text('• $note', style: AppTextStyles.bodyMedium),
                ),
            ],
            if (history.isNotEmpty)
              ExpansionTile(
                key: const ValueKey('price-records'),
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                shape: const Border(),
                collapsedShape: const Border(),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                title: Text(
                  'Các lần ghi (${history.length})',
                  style: AppTextStyles.labelLarge,
                ),
                children: [
                  for (final (index, s) in history.indexed)
                    _RecordRow(
                      snapshot: s,
                      isSaved: index == history.length - 1,
                      freshness: index == 0
                          ? PriceInsights.freshnessLabel(s, decision!.now)
                          : null,
                    ),
                  const SizedBox(height: AppDimens.space4),
                  Text(
                    'Giá do bạn tự ghi hoặc lưu từ extension; app không theo dõi giá trên Shopee.',
                    style: AppTextStyles.labelMedium,
                  ),
                ],
              ),
            if (widget.showSharedPrices && productKey != null)
              SharedPriceSection(
                item: item,
                onUsePrice: widget.onUsePrice,
                embedded: true,
              ),
          ],
        ),
      ),
    );
  }
}

/// One recorded price: date ("· lúc lưu" for the first), price, tag, freshness of
/// the newest
class _RecordRow extends StatelessWidget {
  final PriceSnapshot snapshot;
  final bool isSaved;
  final String? freshness;

  const _RecordRow({
    required this.snapshot,
    required this.isSaved,
    this.freshness,
  });

  @override
  Widget build(BuildContext context) {
    final s = snapshot;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.space4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              formatDate(s.observedAt) + (isSaved ? ' · lúc lưu' : ''),
              style: AppTextStyles.bodyMedium,
            ),
          ),
          Text(
            s.isRange
                ? '${formatVnd(s.minVnd)} – ${formatVnd(s.maxVnd)}'
                : formatVnd(s.amountVnd),
            style: AppTextStyles.titleMedium,
          ),
          if (_tagFor(s) case final tag?) ...[
            const SizedBox(width: AppDimens.space8),
            Text(tag, style: AppTextStyles.labelMedium),
          ],
          if (freshness case final label?) ...[
            const SizedBox(width: AppDimens.space8),
            Text(label, style: AppTextStyles.labelMedium),
          ],
        ],
      ),
    );
  }

  /// Extension prices: "Sau voucher" is a personal reference, an unread-back page price
  /// is "Chưa xác nhận"
  static String? _tagFor(PriceSnapshot s) {
    if (s.priceType == PriceType.afterVoucher) {
      return s.saleLabel == null
          ? 'Sau voucher'
          : 'Sau voucher · ${s.saleLabel}';
    }
    if (s.source == PriceSource.community) return 'Từ giá người khác';
    if (!s.confirmed) return 'Chưa xác nhận';
    if (s.priceType == PriceType.sale) {
      final parts = [
        if (s.discountPercent > 0) '-${s.discountPercent}%',
        s.saleLabel ?? 'Đang giảm',
      ];
      return parts.join(' · ');
    }
    if (s.priceType == PriceType.flash) return 'Flash Sale';
    return null;
  }
}

/// "Thêm link Shopee" for an item without one, with what the link gives
class _AddLinkHint extends StatelessWidget {
  final VoidCallback? onPressed;

  const _AddLinkHint({this.onPressed});

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('price-add-link'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextButton.icon(
        key: const ValueKey('price-add-link-button'),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, AppDimens.minTouchTarget),
        ),
        onPressed: onPressed,
        icon: const Icon(Icons.add_link_rounded, size: 18),
        label: const Text('Thêm link Shopee'),
      ),
      Text(
        'Có link thì xem được giá người khác ghi và cùng món ở shop khác.',
        style: AppTextStyles.labelMedium,
      ),
    ],
  );
}
