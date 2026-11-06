import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../core/formatters/money_format.dart';
import '../models/ui_state.dart';
import '../services/price_history_service.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/price_history_viewmodel.dart';
import 'demo_data_badge.dart';

/// Chi tiết món: "Giá tham khảo" when priceHistory has data for [productKey]
/// (lowest price of 30 days, days with data); tapping opens the chart. Nothing while
/// loading, without data or on error. Not counted as view_price_history.
class PriceHistoryEntryCard extends StatelessWidget {
  final String productKey;

  const PriceHistoryEntryCard({super.key, required this.productKey});

  @override
  Widget build(BuildContext context) {
    final service = context.read<PriceHistoryService?>();
    if (service == null) return const SizedBox.shrink();
    return ChangeNotifierProvider(
      key: ValueKey(productKey),
      create: (_) =>
          PriceHistoryViewModel(service: service)..openProduct(productKey),
      child: Consumer<PriceHistoryViewModel>(
        builder: (context, vm, _) => switch (vm.state) {
          UiSuccess(:final data) => _card(context, data),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }

  Widget _card(BuildContext context, PriceHistoryView view) {
    final theme = Theme.of(context);
    final s = view.summary;
    final low = s.lowest!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.space16),
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimens.borderLarge,
          side: BorderSide(color: theme.dividerColor),
        ),
        child: InkWell(
          key: const ValueKey('price-history-entry'),
          borderRadius: AppDimens.borderLarge,
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.priceHistory,
            arguments: PriceHistoryArgs(productKey: productKey),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.space16),
            child: Row(
              children: [
                Icon(
                  Icons.show_chart_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppDimens.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Wraps on narrow screens / large text
                      Wrap(
                        spacing: AppDimens.space8,
                        runSpacing: AppDimens.space4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Giá tham khảo',
                            style: AppTextStyles.titleMedium,
                          ),
                          if (view.isDemo) const DemoDataBadge(),
                        ],
                      ),
                      const SizedBox(height: AppDimens.space4),
                      Text(
                        'Thấp nhất ${view.range.days} ngày: ${formatVnd(low.vnd)}',
                        style: AppTextStyles.bodyMedium,
                      ),
                      Text(
                        'Có dữ liệu ${s.daysWithData}/${view.days.length} ngày',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
