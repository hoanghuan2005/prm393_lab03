import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/utils/price_history_ids.dart';
import '../../models/daily_price.dart';
import '../../models/price_history.dart';
import '../../models/sale_event.dart';
import '../../services/price_history_service.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_text_styles.dart';
import '../../viewmodels/price_history_viewmodel.dart';
import '../../widgets/price_history_chart.dart';
import '../../widgets/section_card.dart';
import '../../widgets/states/ui_state_builder.dart';

/// Widget Gallery (debug): PriceHistoryChart fed by the real ViewModel over made-up,
/// in-memory reports (no Firestore), in its 3 states: a group of 3 shops, one product
/// with "Giá lúc bạn lưu", and too few days to draw (milestones only).
class PriceChartGallerySection extends StatefulWidget {
  const PriceChartGallerySection({super.key});

  @override
  State<PriceChartGallerySection> createState() =>
      _PriceChartGallerySectionState();
}

class _PriceChartGallerySectionState extends State<PriceChartGallerySection> {
  final _now = DateTime.now();
  late final _service = InMemoryPriceHistoryService.sample(_now);
  late final _group = PriceHistoryViewModel(service: _service)
    ..addListener(_changed)
    ..openGroup(InMemoryPriceHistoryService.groupId);
  late final _product = PriceHistoryViewModel(service: _service)
    ..addListener(_changed)
    ..openProduct(InMemoryPriceHistoryService.keys.first);
  late final _few =
      PriceHistoryViewModel(service: InMemoryPriceHistoryService.sparse(_now))
        ..addListener(_changed)
        ..openProduct(InMemoryPriceHistoryService.keys.first);

  /// Made up: the item was saved 20 days ago at 640.000 đ
  late final _saved = SavedPrice(
    vnd: 640000,
    savedAt: _now.subtract(const Duration(days: 20)),
  );

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _group.dispose();
    _product.dispose();
    _few.dispose();
    super.dispose();
  }

  Widget _chart(PriceHistoryViewModel vm, {SavedPrice? saved}) =>
      UiStateBuilder<PriceHistoryView>(
        state: vm.state,
        builder: (_, view) => PriceHistoryChart(
          view: view,
          onRangeChanged: vm.setRange,
          savedPrice: saved,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'PriceHistoryChart',
      icon: Icons.show_chart_rounded,
      children: [
        Text('Cả nhóm (3 shop)', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppDimens.space8),
        _chart(_group),
        const SizedBox(height: AppDimens.space24),
        Text(
          'Một sản phẩm (có giá lúc bạn lưu)',
          style: AppTextStyles.labelLarge,
        ),
        const SizedBox(height: AppDimens.space8),
        _chart(_product, saved: _saved),
        const SizedBox(height: AppDimens.space24),
        Text('Ít dữ liệu (3 ngày có giá)', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppDimens.space8),
        _chart(_few),
      ],
    );
  }
}

/// [PriceHistoryService] over generated reports, for the gallery and tests
class InMemoryPriceHistoryService implements PriceHistoryService {
  static const groupId = 'gallery-group';
  static const keys = [
    'shopee:9000000001:9000000011',
    'shopee:9000000002:9000000012',
    'shopee:9000000003:9000000013',
  ];
  static const _shops = [
    'Nhà Tai Nghe Mây',
    'Góc Âm Thanh 79',
    'Phụ Kiện Cầu Gỗ',
  ];

  final Map<String, PriceHistoryProduct> products;
  final Map<String, List<PriceHistoryReport>> reports;
  final List<SaleEvent> sales;

  /// Products of the group [groupId]
  final List<String> groupKeys;

  InMemoryPriceHistoryService({
    required this.products,
    required this.reports,
    this.sales = const [],
    this.groupKeys = keys,
  });

  /// 90 days for 3 shops, seeded: same data every run on the same day. A shop's
  /// price holds for 3–10 days, then it adjusts it; sale days are 20% off.
  factory InMemoryPriceHistoryService.sample(DateTime now) {
    final rng = Random(42);
    final today = vnDate(now);
    final products = <String, PriceHistoryProduct>{};
    final reports = <String, List<PriceHistoryReport>>{};
    final sales = <SaleEvent>[];
    for (var d = 89; d >= 0; d--) {
      final day = today.subtract(Duration(days: d));
      if (day.day == day.month) {
        sales.add(
          SaleEvent(
            id: 's$d',
            name: '${day.day}.${day.month}',
            date: day.subtract(PriceHistoryIds.vietnamOffset),
            type: SaleType.doubleDay,
            confirmed: true,
          ),
        );
      }
    }
    for (var k = 0; k < keys.length; k++) {
      final key = keys[k];
      products[key] = PriceHistoryProduct(
        productKey: key,
        title: 'Tai nghe Sonora Air 2',
        shopId: key.split(':')[1],
        itemId: key.split(':')[2],
        shopName: _shops[k],
        groupId: groupId,
        isDemo: true,
        createdAt: today.subtract(const Duration(days: 90)),
      );
      final base = 600000 + k * 25000;
      final rating = 4.9 - k * 0.3;
      final list = <PriceHistoryReport>[];
      var n = 0;
      var listPrice = base;
      var holdDays = 0;
      for (var d = 89; d >= 0; d--) {
        final day = today.subtract(Duration(days: d));
        if (holdDays-- <= 0) {
          listPrice = (base * (0.95 + rng.nextDouble() * 0.1) / 1000).round();
          listPrice *= 1000;
          holdDays = 2 + rng.nextInt(8);
        }
        if (rng.nextDouble() < 0.4) continue;
        final sale = day.day == day.month || day.day == 15 || day.day == 25;
        final price = listPrice * (sale ? 0.8 : 1.0);
        final count = 1 + rng.nextInt(4);
        for (var r = 0; r < count; r++) {
          final at = day
              .subtract(PriceHistoryIds.vietnamOffset)
              .add(Duration(hours: 9 + r * 3));
          if (at.isAfter(now)) continue;
          final voucher = r == 0 && rng.nextDouble() < 0.15;
          list.add(
            PriceHistoryReport(
              id: 'demo${++n}',
              // Same-day list prices differ by a few thousand đồng (< 1%)
              amountVnd:
                  ((voucher ? price * 0.88 : price) / 1000).round() * 1000 +
                  (voucher ? 0 : r % 3 * 1000),
              priceType: voucher
                  ? HistoryPriceType.afterVoucher
                  : sale
                  ? HistoryPriceType.sale
                  : HistoryPriceType.single,
              observedAt: at,
              source: HistoryReportSource.demo,
              shopName: _shops[k],
              productRating: rating,
              productRatingCount: 300 + (89 - d) * 4,
              shopRating: 4.8,
            ),
          );
          // A second after-voucher price so it reaches its own threshold
          if (voucher) {
            list.add(
              PriceHistoryReport(
                id: 'demo${++n}',
                amountVnd: ((price * 0.9) / 1000).round() * 1000,
                priceType: HistoryPriceType.afterVoucher,
                observedAt: at.add(const Duration(minutes: 30)),
                source: HistoryReportSource.demo,
              ),
            );
          }
        }
      }
      reports[key] = list;
    }
    return InMemoryPriceHistoryService(
      products: products,
      reports: reports,
      sales: sales,
    );
  }

  /// The first product with 2 reports on 3 days only: too few days to draw
  factory InMemoryPriceHistoryService.sparse(DateTime now) {
    final today = vnDate(now);
    final key = keys.first;
    return InMemoryPriceHistoryService(
      products: {key: InMemoryPriceHistoryService.sample(now).products[key]!},
      reports: {
        key: [
          for (final (d, vnd) in const [(16, 619000), (9, 599000), (2, 609000)])
            for (var r = 0; r < 2; r++)
              PriceHistoryReport(
                id: 'sparse${d}_$r',
                amountVnd: vnd + r * 1000,
                priceType: HistoryPriceType.single,
                observedAt: today
                    .subtract(Duration(days: d))
                    .subtract(PriceHistoryIds.vietnamOffset)
                    .add(Duration(hours: 10 + r)),
                source: HistoryReportSource.demo,
                shopName: _shops.first,
              ),
        ],
      },
    );
  }

  @override
  Stream<PriceHistoryProduct?> watchProduct(String productKey) =>
      Stream.value(products[productKey]);

  @override
  Future<List<PriceHistoryReport>> fetchReports(
    String productKey,
    DateTime from,
  ) async => [
    for (final r in reports[productKey] ?? const <PriceHistoryReport>[])
      if (!r.observedAt.isBefore(from)) r,
  ];

  @override
  Future<ProductGroup?> fetchGroup(String groupId) async =>
      groupId == InMemoryPriceHistoryService.groupId
      ? ProductGroup(
          id: InMemoryPriceHistoryService.groupId,
          name: 'Tai nghe Sonora Air 2',
          productKeys: groupKeys,
          isDemo: products.values.any((p) => p.isDemo),
        )
      : null;

  @override
  Future<List<SaleEvent>> fetchSaleEvents(DateTime from, DateTime to) async => [
    for (final e in sales)
      if (!e.date.isBefore(from) && !e.date.isAfter(to)) e,
  ];

  @override
  Future<List<PriceHistoryProduct>> findSameProduct(
    String productCode, {
    required bool isDemo,
  }) async => [
    for (final p in products.values)
      if (p.productCode == productCode && p.isDemo == isDemo) p,
  ];
}
