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
/// in-memory reports (no Firestore). One product, then a group of 3 shops.
class PriceChartGallerySection extends StatefulWidget {
  const PriceChartGallerySection({super.key});

  @override
  State<PriceChartGallerySection> createState() =>
      _PriceChartGallerySectionState();
}

class _PriceChartGallerySectionState extends State<PriceChartGallerySection> {
  final _service = InMemoryPriceHistoryService.sample(DateTime.now());
  late final _product = PriceHistoryViewModel(service: _service)
    ..addListener(_changed)
    ..openProduct(InMemoryPriceHistoryService.keys.first);
  late final _group = PriceHistoryViewModel(service: _service)
    ..addListener(_changed)
    ..openGroup(InMemoryPriceHistoryService.groupId);

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _product.dispose();
    _group.dispose();
    super.dispose();
  }

  Widget _chart(PriceHistoryViewModel vm, {bool voucherDots = false}) =>
      UiStateBuilder<PriceHistoryView>(
        state: vm.state,
        builder: (_, view) => PriceHistoryChart(
          view: view,
          onRangeChanged: vm.setRange,
          showAfterVoucherDots: voucherDots,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'PriceHistoryChart',
      icon: Icons.show_chart_rounded,
      children: [
        Text(
          'Một sản phẩm (chấm sau voucher bật)',
          style: AppTextStyles.labelLarge,
        ),
        const SizedBox(height: AppDimens.space8),
        _chart(_product, voucherDots: true),
        const SizedBox(height: AppDimens.space24),
        Text('Cả nhóm (3 shop)', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppDimens.space8),
        _chart(_group),
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

  /// 90 days for 3 shops, seeded: same data every run on the same day
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
      for (var d = 89; d >= 0; d--) {
        final day = today.subtract(Duration(days: d));
        if (rng.nextDouble() < 0.4) continue;
        final sale = day.day == day.month || day.day == 15 || day.day == 25;
        final price = base * (0.95 + rng.nextDouble() * 0.1) * (sale ? 0.8 : 1);
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
              amountVnd:
                  ((voucher ? price * 0.88 : price) / 1000).round() * 1000,
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
