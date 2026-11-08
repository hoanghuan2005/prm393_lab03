import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../core/formatters/rating_format.dart';
import '../models/same_product.dart';
import '../models/ui_state.dart';
import '../services/analytics_service.dart';
import '../services/crashlytics_service.dart';
import '../services/price_history_service.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/price_history_viewmodel.dart';
import '../widgets/price_history_chart.dart';
import '../widgets/section_card.dart';
import '../widgets/states/ui_state_builder.dart';

/// "Giá tham khảo": the chart of one product or of every shop in its group.
/// Facts only: no advice, no ranking of shops.
class PriceHistoryScreen extends StatefulWidget {
  /// Opened from a product (Chi tiết món); can switch to its group
  final String? productKey;

  /// Opened on a group (Firebase Demo Area), or the product's group once known.
  /// Sample data only: a real product's groupId is ignored (G8).
  final String? groupId;

  /// Real product (G8): the shops of "Cùng món ở shop khác" for "Cả nhóm"
  final SameProductLinks? sameProduct;

  /// "Giá lúc bạn lưu" of the item on Chi tiết món, when it can be compared
  final SavedPrice? savedPrice;

  const PriceHistoryScreen({
    super.key,
    this.productKey,
    this.groupId,
    this.sameProduct,
    this.savedPrice,
  }) : assert(productKey != null || groupId != null);

  /// The route: a ViewModel for this screen only, from the services in context
  static Widget withViewModel({
    String? productKey,
    String? groupId,
    SameProductLinks? sameProduct,
    SavedPrice? savedPrice,
  }) => ChangeNotifierProvider(
    create: (context) {
      final vm = PriceHistoryViewModel(
        service: context.read<PriceHistoryService>(),
        analytics: context.read<AppAnalyticsService>(),
        crashlyticsService: context.read<CrashlyticsService>(),
      );
      if (productKey != null) {
        vm.openProduct(productKey);
      } else {
        vm.openGroup(groupId!);
      }
      return vm;
    },
    child: PriceHistoryScreen(
      productKey: productKey,
      groupId: groupId,
      sameProduct: sameProduct,
      savedPrice: savedPrice,
    ),
  );

  @override
  State<PriceHistoryScreen> createState() => _PriceHistoryScreenState();
}

class _PriceHistoryScreenState extends State<PriceHistoryScreen> {
  late String? _groupId = widget.groupId;
  String? _title;

  /// Whether the opened product is sample data, once loaded
  bool? _isDemo;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PriceHistoryViewModel>();
    final theme = Theme.of(context);
    final state = vm.state;
    final key = widget.productKey;
    if (state case UiSuccess(:final data)) {
      // Remember the product's group and the title across loads
      final product = key == null ? null : data.products[key];
      if (product != null) {
        _isDemo ??= product.isDemo;
        // A real product may still hold a groupId from before G8: not used
        if (product.isDemo) _groupId ??= product.groupId;
      }
      _title =
          data.group?.name ?? data.products.values.firstOrNull?.title ?? _title;
    }
    final same = widget.sameProduct;
    final canSame =
        key != null &&
        _isDemo == false &&
        (same?.productKeys.isNotEmpty ?? false);
    final canGroup = key != null && _isDemo != false && _groupId != null;
    final canSwitch = canSame || canGroup;

    return Scaffold(
      appBar: AppBar(title: const Text('Giá tham khảo')),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.space16),
        children: [
          if (_title != null) ...[
            Text(_title!, style: AppTextStyles.titleMedium),
            const SizedBox(height: AppDimens.space12),
          ],
          if (canSwitch) ...[
            SegmentedButton<bool>(
              key: const ValueKey('price-scope'),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: false, label: Text('Chỉ món này')),
                ButtonSegment(value: true, label: Text('Cả nhóm')),
              ],
              selected: {vm.groupId != null || vm.isSameProduct},
              onSelectionChanged: (s) => !s.single
                  ? vm.openProduct(key)
                  : canSame
                  ? vm.openSameProduct(
                      [key, ...same!.productKeys],
                      variantCode: same.variantCode,
                      name: _title ?? '',
                    )
                  : vm.openGroup(_groupId!),
            ),
            const SizedBox(height: AppDimens.space16),
          ],
          if (state is UiSuccess<PriceHistoryView>)
            _Content(
              view: state.data,
              onRange: vm.setRange,
              savedPrice: widget.savedPrice,
            )
          else
            SizedBox(
              height: 320,
              child: UiStateBuilder<PriceHistoryView>(
                state: state,
                emptyIcon: Icons.show_chart_rounded,
                builder: (_, _) => const SizedBox.shrink(),
              ),
            ),
          const SizedBox(height: AppDimens.space16),
          if (vm.isSameProduct) ...[
            Text(
              'Các shop được ghép tự động theo mã món và phân loại, có thể chưa '
              'đúng. Chỉ tính giá của cùng phân loại.',
              key: const ValueKey('same-product-note'),
              style: AppTextStyles.labelMedium.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppDimens.space8),
          ],
          Text(
            'Giá do người dùng và extension ghi lại trên Shopee, chỉ để tham '
            'khảo. Ngày chưa có giá mới giữ giá gần nhất tối đa 7 ngày (nét '
            'đứt, mờ hơn); lâu hơn thì để trống.',
            style: AppTextStyles.labelMedium.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final PriceHistoryView view;
  final ValueChanged<PriceHistoryRange> onRange;
  final SavedPrice? savedPrice;

  const _Content({required this.view, required this.onRange, this.savedPrice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = AppTextStyles.labelMedium.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PriceHistoryChart(
          view: view,
          onRangeChanged: onRange,
          savedPrice: savedPrice,
        ),
        if (view.isGroup) ...[
          const SizedBox(height: AppDimens.space16),
          SectionCard(
            title: 'Giá gần nhất theo shop',
            icon: Icons.storefront_outlined,
            children: [
              // Group order, not sorted: shops are not ranked
              for (final p in view.summary.latestByShop)
                Padding(
                  key: ValueKey('shop-latest-${p.productKey}'),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimens.space6,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.shopName ?? 'Shop chưa rõ tên',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: AppDimens.space8),
                      // Shrinks and wraps on narrow screens / large text
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatVnd(p.vnd),
                              style: AppTextStyles.labelLarge,
                              textAlign: TextAlign.end,
                            ),
                            Text(
                              [
                                'ngày ${formatDayMonth(p.day)}',
                                if (p.productRating case final r?)
                                  '★ ${formatStars(r)}',
                              ].join(' · '),
                              style: muted,
                              textAlign: TextAlign.end,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
