import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../models/price_insights.dart';
import '../models/wishlist_item.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/decision_support_viewmodel.dart';

/// A-14 "Lịch sử giá" (screen 22.3): every recorded price with its date, and the
/// neutral comparisons of spec 6.5 / 8.3 when there is enough history.
class PriceHistoryPanel extends StatefulWidget {
  final WishlistItem item;

  const PriceHistoryPanel({super.key, required this.item});

  @override
  State<PriceHistoryPanel> createState() => _PriceHistoryPanelState();
}

class _PriceHistoryPanelState extends State<PriceHistoryPanel> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PriceHistoryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.latestPriceAt != widget.item.latestPriceAt) _load();
  }

  void _load() =>
      context.read<DecisionSupportViewModel?>()?.loadPriceHistory(widget.item);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DecisionSupportViewModel?>();
    final insights = vm?.priceInsightsFor(widget.item);
    if (vm == null || insights == null || insights.history.isEmpty) {
      return const SizedBox.shrink();
    }
    final history = insights.history;
    return Card(
      key: const ValueKey('price-history'),
      margin: const EdgeInsets.only(bottom: AppDimens.space16),
      child: ExpansionTile(
        leading: const Icon(Icons.timeline_outlined),
        title: Text(
          'Lịch sử giá (${history.length} lần ghi)',
          style: AppTextStyles.titleMedium,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppDimens.space16,
          0,
          AppDimens.space16,
          AppDimens.space16,
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final note in insights.notes)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.space4),
              child: Text('• $note', style: AppTextStyles.bodyMedium),
            ),
          if (insights.notes.isNotEmpty) const Divider(),
          for (final (index, s) in history.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppDimens.space4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      formatDate(s.observedAt) +
                          (index == history.length - 1 ? ' · lúc lưu' : ''),
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                  Text(
                    formatVnd(s.amountVnd),
                    style: AppTextStyles.titleMedium,
                  ),
                  if (index == 0) ...[
                    const SizedBox(width: AppDimens.space8),
                    Text(
                      PriceInsights.freshnessLabel(s, vm.now),
                      style: AppTextStyles.labelMedium,
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: AppDimens.space4),
          Text(
            'Giá do bạn tự ghi cho món này; app không theo dõi giá trên Shopee.',
            style: AppTextStyles.labelMedium,
          ),
        ],
      ),
    );
  }
}
