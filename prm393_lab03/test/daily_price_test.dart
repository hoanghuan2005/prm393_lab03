import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/errors/app_exception.dart';
import 'package:prm393_lab03/models/daily_price.dart';
import 'package:prm393_lab03/models/price_history.dart';
import 'package:prm393_lab03/models/sale_event.dart';
import 'package:prm393_lab03/models/ui_state.dart';
import 'package:prm393_lab03/services/price_history_service.dart';
import 'package:prm393_lab03/viewmodels/price_history_viewmodel.dart';

/// 2026-11-06 12:00 in Vietnam
final _now = DateTime.utc(2026, 11, 6, 5);

/// [vnDay] days before 2026-11-06, at 10:00 in Vietnam
DateTime _at(int vnDay, {int hour = 10}) =>
    DateTime.utc(2026, 11, 6 - vnDay, hour - 7);

int _n = 0;
PriceHistoryReport _r(
  int amount, {
  int day = 0,
  HistoryPriceType type = HistoryPriceType.single,
  double? rating,
  double? shopRating,
  int? count,
  String? shop,
  int hour = 10,
}) => PriceHistoryReport(
  id: 'r${_n++}',
  amountVnd: amount,
  priceType: type,
  observedAt: _at(day, hour: hour),
  productRating: rating,
  shopRating: shopRating,
  productRatingCount: count,
  shopName: shop,
);

/// One day: 2026-11-06
DailyPricePoint _today(List<PriceHistoryReport> reports) =>
    aggregateDaily(reports, _at(0), _now).single;

void main() {
  group('aggregateDaily', () {
    test('drops prices more than 30% from the day median', () {
      final p = _today([
        _r(100000),
        _r(102000),
        _r(104000),
        _r(200000), // +92%
        _r(60000), // -41%
      ]);
      expect(p.reportCount, 3);
      expect(p.minVnd, 100000);
      expect(p.medianVnd, 102000);
    });

    test('1 report → no list price; 2 kept reports → a price', () {
      final one = _today([_r(100000)]);
      expect(one.minVnd, isNull);
      expect(one.medianVnd, isNull);
      expect(one.hasPrice, isFalse);
      expect(one.reportCount, 1);
      // Median 150.000: both are more than 30% away
      final apart = _today([_r(100000), _r(200000)]);
      expect(apart.minVnd, isNull);
      expect(apart.reportCount, 0);
      final two = _today([_r(100000), _r(110000)]);
      expect(two.reportCount, 2);
      expect(two.medianVnd, 105000);
    });

    test('a range counts with its lowest price (amountVnd)', () {
      final p = _today([_r(95000, type: HistoryPriceType.range), _r(100000)]);
      expect(p.minVnd, 95000);
      expect(p.reportCount, 2);
    });

    test('every day has an entry, also empty ones', () {
      final points = aggregateDaily(
        [_r(100000, day: 2), _r(101000, day: 2), _r(99000, day: 0)],
        _at(3),
        _now,
      );
      expect(points, hasLength(4));
      expect(points.map((p) => p.day), [
        DateTime.utc(2026, 11, 3),
        DateTime.utc(2026, 11, 4),
        DateTime.utc(2026, 11, 5),
        DateTime.utc(2026, 11, 6),
      ]);
      expect(points[0].hasPrice, isFalse, reason: '3 days ago: nothing');
      expect(points[0].reportCount, 0);
      expect(points[0].afterVoucherCount, 0);
      expect(points[0].productRating, isNull);
      expect(points[1].minVnd, 100000);
      expect(points[2].hasPrice, isFalse, reason: 'yesterday: nothing');
      expect(points[3].minVnd, isNull, reason: 'today: only 1 report');
    });

    test('days follow Vietnam time (UTC+7)', () {
      // 2026-11-05 17:30 UTC is 2026-11-06 00:30 in Vietnam
      final late = PriceHistoryReport(
        id: 'x',
        amountVnd: 100000,
        observedAt: DateTime.utc(2026, 11, 5, 17, 30),
      );
      expect(_today([late, _r(100000)]).reportCount, 2);
    });

    test('a lower afterVoucher price never changes minVnd or the count', () {
      final p = _today([
        _r(100000),
        _r(102000),
        _r(80000, type: HistoryPriceType.afterVoucher),
        _r(85000, type: HistoryPriceType.afterVoucher),
      ]);
      expect(p.minVnd, 100000);
      expect(p.medianVnd, 101000);
      expect(p.reportCount, 2);
      expect(p.afterVoucherCount, 2);
      expect(p.afterVoucherMinVnd, 80000);
    });

    test('afterVoucher has its own 2-report threshold', () {
      // 1 list price + 2 afterVoucher: no list price, an afterVoucher price
      final p = _today([
        _r(100000),
        _r(80000, type: HistoryPriceType.afterVoucher),
        _r(83000, type: HistoryPriceType.afterVoucher),
      ]);
      expect(p.minVnd, isNull);
      expect(p.reportCount, 1);
      expect(p.afterVoucherMinVnd, 80000);
      expect(p.afterVoucherCount, 2);
      // 2 list prices + 1 afterVoucher: a list price, no afterVoucher price
      final q = _today([
        _r(100000),
        _r(101000),
        _r(80000, type: HistoryPriceType.afterVoucher),
      ]);
      expect(q.minVnd, 100000);
      expect(q.afterVoucherMinVnd, isNull);
      expect(q.afterVoucherCount, 1);
    });

    test('a report dropped for its price is dropped for its rating too', () {
      final p = _today([
        _r(100000, rating: 4.6, shopRating: 4.9, count: 100, hour: 9),
        _r(
          99000,
          type: HistoryPriceType.flash,
          rating: 4.8,
          count: 120,
          shop: 'Mây',
          hour: 15,
        ),
        _r(101000, rating: 4.9, shopRating: 4.7, hour: 18),
        // Outlier: its 1.0 rating, count and shop name are ignored
        _r(
          300000,
          rating: 1.0,
          shopRating: 1.0,
          count: 999,
          shop: 'X',
          hour: 21,
        ),
      ]);
      expect(p.reportCount, 3);
      expect(p.hasSale, isTrue);
      expect(p.productRating, 4.8);
      expect(p.shopRating, 4.8);
      expect(p.productRatingCount, 120, reason: 'newest kept report');
      expect(p.shopName, 'Mây');
      expect(_today([_r(100000), _r(101000)]).hasSale, isFalse);
    });

    test('afterVoucher reports count for the rating', () {
      final p = _today([
        _r(100000, rating: 4.0),
        _r(101000, rating: 4.2),
        _r(80000, type: HistoryPriceType.afterVoucher, rating: 5.0),
      ]);
      expect(p.productRating, 4.2);
    });
  });

  group('compareGroup', () {
    // Day 0 = 2026-11-04, day 1 = 11-05, day 2 = 11-06
    List<DailyPricePoint> product(
      Map<int, (int price, double? rating)> byDay,
      String shop,
    ) => aggregateDaily(
      [
        for (final MapEntry(key: d, value: (price, rating)) in byDay.entries)
          for (final delta in [0, 1000])
            _r(price + delta, day: 2 - d, rating: rating, shop: shop),
      ],
      _at(2),
      _now,
    );

    test('3 shops: lowest price and highest rating, each day', () {
      final days = compareGroup({
        'a': product({0: (100000, 4.2), 1: (98000, 4.2)}, 'A'),
        'b': product({0: (110000, 4.9), 1: (97000, 4.9)}, 'B'),
        'c': product({0: (105000, null), 2: (120000, 4.5)}, 'C'),
      });

      expect(days, hasLength(3));
      final d0 = days[0]!;
      expect(d0.productCount, 3);
      expect(d0.lowestPrice.shopName, 'A');
      expect(d0.lowestPrice.minVnd, 100000);
      expect(d0.highestRated!.shopName, 'B');
      expect(d0.highestRated!.productRating, 4.9);
      expect(d0.highestRated!.minVnd, 110000);

      final d1 = days[1]!;
      expect(d1.lowestPrice.productKey, 'b');
      expect(d1.highestRated!.productKey, 'b');

      // Only one shop has a point: still returned
      final d2 = days[2]!;
      expect(d2.productCount, 1);
      expect(d2.lowestPrice.shopName, 'C');
      expect(d2.highestRated!.shopName, 'C');
      expect(d2.day, DateTime.utc(2026, 11, 6));
    });

    test('a day without any point is null; no rating → no highestRated', () {
      final days = compareGroup({
        'a': product({0: (100000, null)}, 'A'),
        'b': product({}, 'B'),
      });
      expect(days[0]!.highestRated, isNull);
      expect(days[1], isNull);
      expect(days[2], isNull);
    });

    test('compares minVnd only, never the after-voucher price', () {
      List<DailyPricePoint> withVoucher(int price, int voucher, String shop) =>
          [
            _today([
              _r(price, shop: shop),
              _r(price + 1000, shop: shop),
              _r(voucher, type: HistoryPriceType.afterVoucher, shop: shop),
              _r(voucher, type: HistoryPriceType.afterVoucher, shop: shop),
            ]),
          ];
      final [day] = compareGroup({
        'a': withVoucher(100000, 70000, 'A'),
        'b': withVoucher(95000, 90000, 'B'),
      });
      expect(day!.lowestPrice.shopName, 'B');
      expect(day.lowestPrice.minVnd, 95000);
      expect(withVoucher(100000, 70000, 'A').single.afterVoucherMinVnd, 70000);
    });

    test('ties go to the earlier product; rating tie to the lower price', () {
      final [day] = compareGroup({
        'a': [
          _today([_r(100000, rating: 4.8), _r(101000, rating: 4.8)]),
        ],
        'b': [
          _today([_r(100000, rating: 4.8), _r(99000, rating: 4.8)]),
        ],
      });
      expect(day!.lowestPrice.productKey, 'b');
      expect(day.highestRated!.productKey, 'b');
    });
  });

  group('PriceHistoryViewModel', () {
    late _FakeService service;
    late PriceHistoryViewModel vm;

    setUp(() {
      service = _FakeService();
      vm = PriceHistoryViewModel(service: service, now: () => _now);
    });
    tearDown(() => vm.dispose());

    test('product: summary of the period', () async {
      service.reports['p'] = [
        _r(100000, day: 20, shop: 'A'),
        _r(101000, day: 20, shop: 'A'),
        _r(95000, day: 5, shop: 'A'),
        _r(96000, day: 5, shop: 'A'),
        _r(99000, day: 1, shop: 'A'),
        _r(99000, day: 1, shop: 'A'),
        _r(50000, day: 1, type: HistoryPriceType.afterVoucher),
      ];
      final loading = <UiState>[];
      vm.addListener(() => loading.add(vm.state));
      await vm.openProduct('p');

      expect(loading.first, isA<UiLoading>());
      final view = (vm.state as UiSuccess<PriceHistoryView>).data;
      expect(view.range, PriceHistoryRange.month);
      expect(view.days, hasLength(30));
      expect(view.isGroup, isFalse);
      expect(view.summary.daysWithData, 3);
      expect(view.summary.lowest!.vnd, 95000, reason: 'afterVoucher ignored');
      expect(view.summary.lowest!.day, DateTime.utc(2026, 11, 1));
      expect(view.summary.lowest!.shopName, 'A');
      expect(view.summary.latest!.vnd, 99000);
      expect(view.summary.latest!.day, DateTime.utc(2026, 11, 5));

      // 7 days: the 20-days-ago point drops out; no new read
      vm.setRange(PriceHistoryRange.week);
      final week = (vm.state as UiSuccess<PriceHistoryView>).data;
      expect(week.days, hasLength(7));
      expect(week.summary.daysWithData, 2);
      expect(service.reportReads, 1);
    });

    test('not enough data → UiEmpty "Chưa đủ dữ liệu"', () async {
      service.reports['p'] = [_r(100000)];
      await vm.openProduct('p');
      expect(vm.state, isA<UiEmpty<PriceHistoryView>>());
      expect(
        (vm.state as UiEmpty).message,
        PriceHistoryViewModel.notEnoughData,
      );
    });

    test('an error → UiError with retry', () async {
      service.fail = true;
      await vm.openProduct('p');
      final error = vm.state as UiError;
      expect(error.message, 'Không có kết nối mạng.');

      service.fail = false;
      service.reports['p'] = [_r(100000), _r(101000)];
      error.onRetry!();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(vm.state, isA<UiSuccess<PriceHistoryView>>());
    });

    test('group: every shop, the comparison and the demo label', () async {
      service.group = const ProductGroup(
        id: 'g',
        name: 'Tai nghe',
        productKeys: ['a', 'b'],
        isDemo: true,
      );
      service.reports['a'] = [_r(100000, shop: 'A'), _r(101000, shop: 'A')];
      service.reports['b'] = [_r(90000, shop: 'B'), _r(91000, shop: 'B')];
      service.sales = [
        SaleEvent(
          id: 's',
          name: '11.11',
          date: DateTime.utc(2026, 11, 1),
          type: SaleType.doubleDay,
          confirmed: true,
        ),
      ];
      await vm.openGroup('g');

      final view = (vm.state as UiSuccess<PriceHistoryView>).data;
      expect(view.isGroup, isTrue);
      expect(view.isDemo, isTrue);
      expect(view.points.keys, ['a', 'b']);
      expect(view.points['a'], hasLength(30), reason: 'one entry per day');
      expect(view.comparison!.last!.lowestPrice.shopName, 'B');
      expect(view.summary.lowest!.productKey, 'b');
      expect(view.saleEvents.single.name, '11.11');
    });

    test(
      'group summary: last price with its day and shop; each shop',
      () async {
        service.group = const ProductGroup(
          id: 'g',
          name: 'Tai nghe',
          productKeys: ['a', 'b', 'c'],
        );
        // a: today; b: cheaper, 2 days ago; c: 3 days ago, no shop name in reports
        service.reports['a'] = [
          _r(100000, shop: 'A', rating: 4.5),
          _r(101000, shop: 'A', rating: 4.5),
        ];
        service.reports['b'] = [
          _r(90000, day: 2, shop: 'B', rating: 4.9),
          _r(91000, day: 2, shop: 'B', rating: 4.9),
        ];
        service.reports['c'] = [_r(95000, day: 3), _r(96000, day: 3)];
        service.products['c'] = PriceHistoryProduct(
          productKey: 'c',
          title: 'Tai nghe',
          shopId: '1',
          itemId: '2',
          shopName: 'Shop C',
          createdAt: DateTime(2026),
        );
        await vm.openGroup('g');

        final summary = (vm.state as UiSuccess<PriceHistoryView>).data.summary;
        expect(summary.lastPrice, 100000);
        expect(summary.lastPriceDate, DateTime.utc(2026, 11, 6));
        expect(summary.lastPriceShopName, 'A');
        expect(summary.lowest!.vnd, 90000);
        expect(summary.lowest!.shopName, 'B');
        expect(summary.daysWithData, 3);
        expect(
          [
            for (final p in summary.latestByShop)
              (p.productKey, p.vnd, p.day.day, p.shopName, p.productRating),
          ],
          [
            ('a', 100000, 6, 'A', 4.5),
            ('b', 90000, 4, 'B', 4.9),
            ('c', 95000, 3, 'Shop C', null),
          ],
        );
      },
    );
  });

  group('FirestorePriceHistoryService', () {
    late FakeFirebaseFirestore db;
    late FirestorePriceHistoryService service;
    const key = 'shopee:1:2';

    setUp(() {
      db = FakeFirebaseFirestore();
      service = FirestorePriceHistoryService(db);
    });

    test('reports from a date, oldest first; product and group', () async {
      final reports = db.collection('priceHistory/$key/reports');
      for (final (id, day) in [('old', 40), ('b', 1), ('a', 3)]) {
        await reports.doc(id).set({
          'amountVnd': 100000,
          'priceType': 'single',
          'observedAt': Timestamp.fromDate(_at(day)),
          'source': 'demo',
        });
      }
      await db.doc('priceHistory/$key').set({
        'title': 'Tai nghe',
        'shopId': '1',
        'itemId': '2',
        'shopName': 'A',
        'isDemo': true,
        'createdAt': Timestamp.now(),
      });
      await db.doc('productGroups/g').set({
        'name': 'Tai nghe',
        'productKeys': [key],
        'isDemo': true,
      });

      final read = await service.fetchReports(key, _at(30));
      expect(read.map((r) => r.id), ['a', 'b']);
      expect((await service.watchProduct(key).first)!.isDemo, isTrue);
      expect(await service.watchProduct('shopee:9:9').first, isNull);
      expect((await service.fetchGroup('g'))!.productKeys, [key]);
      expect(await service.fetchGroup('none'), isNull);
    });

    test('published sale events within the dates only', () async {
      Future<void> event(String id, DateTime date, String status) =>
          db.doc('saleEvents/$id').set({
            'name': id,
            'date': Timestamp.fromDate(date),
            'type': 'double_day',
            'confirmed': true,
            'status': status,
          });
      await event('in', DateTime.utc(2026, 11, 1), 'published');
      await event('draft', DateTime.utc(2026, 11, 2), 'draft');
      await event('before', DateTime.utc(2026, 9, 1), 'published');

      final events = await service.fetchSaleEvents(_at(30), _now);
      expect(events.map((e) => e.name), ['in']);
      expect(events.single.type, SaleType.doubleDay);
    });
  });
}

class _FakeService implements PriceHistoryService {
  final reports = <String, List<PriceHistoryReport>>{};
  final products = <String, PriceHistoryProduct>{};
  ProductGroup? group;
  List<SaleEvent> sales = const [];
  bool fail = false;
  int reportReads = 0;

  @override
  Future<List<PriceHistoryReport>> fetchReports(
    String productKey,
    DateTime from,
  ) async {
    reportReads++;
    if (fail) throw const AppException('network', 'Không có kết nối mạng.');
    return [
      for (final r in reports[productKey] ?? const <PriceHistoryReport>[])
        if (!r.observedAt.isBefore(from)) r,
    ];
  }

  @override
  Future<ProductGroup?> fetchGroup(String groupId) async => group;

  @override
  Future<List<SaleEvent>> fetchSaleEvents(DateTime from, DateTime to) async =>
      sales;

  @override
  Stream<PriceHistoryProduct?> watchProduct(String productKey) =>
      Stream.value(products[productKey]);
}
