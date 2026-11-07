import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/models/daily_price.dart';
import 'package:prm393_lab03/models/price_history.dart';
import 'package:prm393_lab03/models/sale_event.dart';
import 'package:prm393_lab03/models/ui_state.dart';
import 'package:prm393_lab03/screens/dev/price_chart_gallery.dart';
import 'package:prm393_lab03/theme/app_theme.dart';
import 'package:prm393_lab03/viewmodels/price_history_viewmodel.dart';
import 'package:prm393_lab03/widgets/price_history_chart.dart';

/// 2026-11-12 12:00 in Vietnam
final _now = DateTime.utc(2026, 11, 12, 5);

/// [daysBack] days before 2026-11-12 at 10:00 + [hour] in Vietnam
DateTime _at(int daysBack, [int hour = 0]) =>
    DateTime.utc(2026, 11, 12 - daysBack, 3 + hour);

int _n = 0;
PriceHistoryReport _r(
  int amount,
  int daysBack, {
  HistoryPriceType type = HistoryPriceType.single,
  String? shop,
}) => PriceHistoryReport(
  id: 'r${_n++}',
  amountVnd: amount,
  priceType: type,
  observedAt: _at(daysBack, _n % 5),
  shopName: shop,
);

/// 2 reports of [amount] on [daysBack]
List<PriceHistoryReport> _two(int amount, int daysBack) => [
  _r(amount, daysBack),
  _r(amount, daysBack),
];

PriceHistoryProduct _product(String key, String shop, {bool demo = false}) =>
    PriceHistoryProduct(
      productKey: key,
      title: 'Tai nghe',
      shopId: '1',
      itemId: '2',
      shopName: shop,
      isDemo: demo,
      createdAt: DateTime(2026),
    );

final _sale = SaleEvent(
  id: 's',
  name: '11.11',
  date: DateTime.utc(2026, 11, 10, 17), // 11/11 00:00 in Vietnam
  type: SaleType.doubleDay,
  confirmed: true,
);

/// Product "a" (shop A) over 7 days (11/06 … 11/12 = days 0 … 6):
/// 06/11: 100k, 101k · 07/11: 100k, 100k · 08/11: one report · 09/11: none ·
/// 10/11: 98k, 99k · 11/11 (sale): 90k, 91k and after-voucher 80k, 82k ·
/// 12/11: 99k, 99k
InMemoryPriceHistoryService _single({bool demo = false}) =>
    InMemoryPriceHistoryService(
      products: {'a': _product('a', 'Shop A', demo: demo)},
      reports: {
        'a': [
          _r(100000, 6, shop: 'Shop A'),
          _r(101000, 6, shop: 'Shop A'),
          ..._two(100000, 5),
          _r(95000, 4),
          _r(98000, 2),
          _r(99000, 2),
          _r(90000, 1, type: HistoryPriceType.sale),
          _r(91000, 1, type: HistoryPriceType.sale),
          _r(80000, 1, type: HistoryPriceType.afterVoucher),
          _r(82000, 1, type: HistoryPriceType.afterVoucher),
          ..._two(99000, 0),
        ],
      },
      sales: [_sale],
    );

/// 3 shops over 7 days (days 0 … 6):
/// 0: A 100k, B 110k, C 120k · 1: A 102k, B 108k · 2: none · 3: B 105k ·
/// 4: A 98k, C 115k · 5: A 97k, B 99k, C 118k · 6: B 103k, C 101k
InMemoryPriceHistoryService _group() => InMemoryPriceHistoryService(
  products: {
    'a': _product('a', 'Shop A'),
    'b': _product('b', 'Shop B'),
    'c': _product('c', 'Shop C'),
  },
  reports: {
    'a': [
      ..._two(100000, 6),
      ..._two(102000, 5),
      ..._two(98000, 2),
      ..._two(97000, 1),
    ],
    'b': [
      ..._two(110000, 6),
      ..._two(108000, 5),
      ..._two(105000, 3),
      ..._two(99000, 1),
      ..._two(103000, 0),
    ],
    'c': [
      ..._two(120000, 6),
      ..._two(115000, 2),
      ..._two(118000, 1),
      ..._two(101000, 0),
    ],
  },
  groupKeys: const ['a', 'b', 'c'],
);

/// Product "a" priced on 3 days of 30 only
InMemoryPriceHistoryService _sparse() => InMemoryPriceHistoryService(
  products: {'a': _product('a', 'Shop A')},
  reports: {
    'a': [..._two(120000, 20), ..._two(110000, 9), ..._two(115000, 2)],
  },
);

Future<PriceHistoryView> _view(
  InMemoryPriceHistoryService service, {
  bool group = false,
  PriceHistoryRange range = PriceHistoryRange.week,
}) async {
  final vm = PriceHistoryViewModel(service: service, now: () => _now);
  addTearDown(vm.dispose);
  vm.setRange(range);
  if (group) {
    await vm.openGroup(InMemoryPriceHistoryService.groupId);
  } else {
    await vm.openProduct('a');
  }
  return (vm.state as UiSuccess<PriceHistoryView>).data;
}

Future<void> _pump(
  WidgetTester tester,
  PriceHistoryView view, {
  ThemeData? theme,
  int? selected,
  SavedPrice? saved,
  ValueChanged<PriceHistoryRange>? onRange,
}) async {
  tester.view.physicalSize = const Size(412, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: PriceHistoryChart(
            view: view,
            initialSelectedDay: selected,
            savedPrice: saved,
            onRangeChanged: onRange,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

LineChartData _data(WidgetTester tester) =>
    tester.widget<LineChart>(find.byType(LineChart)).data;

/// Bars drawn as a visible line (not the band edges or the dots)
List<LineChartBarData> _lines(LineChartData data) => [
  for (final b in data.lineBarsData)
    if (b.barWidth > 0) b,
];

/// The dots drawn: the last bar, one painter per spot
List<(FlSpot, PriceDotPainter)> _marks(LineChartData data) {
  final bar = data.lineBarsData.last;
  return [
    for (final (i, s) in bar.spots.indexed)
      (s, bar.dotData.getDotPainter(s, 0, bar, i) as PriceDotPainter),
  ];
}

/// Texts of the day details panel
List<String> _details(WidgetTester tester) => [
  for (final t in tester.widgetList<Text>(
    find.descendant(
      of: find.byKey(const ValueKey('price-day-details')),
      matching: find.byType(Text),
    ),
  ))
    // A line with a shop link is a Text.rich
    t.data ?? t.textSpan!.toPlainText(),
];

DailyPricePoint _p(
  int day,
  int? min, {
  int? max,
  String? shop,
  bool sale = false,
}) => DailyPricePoint(
  day: DateTime.utc(2026, 11, 1 + day),
  minVnd: min,
  maxVnd: max ?? min,
  shopName: shop,
  hasSale: sale,
);

List<DailyPricePoint> _days(List<int?> prices, {String? shop}) => [
  for (final (i, v) in prices.indexed) _p(i, v, shop: shop),
];

void main() {
  group('fillForward (G5b, unchanged)', () {
    List<(int, int, bool)?> filled(List<int?> prices) => [
      for (final f in fillForward(_days(prices)))
        f == null ? null : (f.vnd, f.sourceIndex, f.held),
    ];

    test('3-day gap joined, 8-day gap broken, nothing before the start', () {
      expect(filled([100, null, null, null, 90]), [
        (100, 0, false),
        (100, 0, true),
        (100, 0, true),
        (100, 0, true),
        (90, 4, false),
      ]);
      final eight = filled([100, ...List.filled(8, null), 90]);
      expect(eight.sublist(1, 8), everyElement((100, 0, true)));
      expect(eight[8], isNull);
      expect(filled([null, 100, null]), [
        null,
        (100, 1, false),
        (100, 1, true),
      ]);
    });

    test('a sale price stays on its own day; the regular price is kept after', () {
      final f = fillForward([
        _p(0, 100),
        _p(1, null),
        _p(2, 80, sale: true),
        _p(3, null),
        _p(4, null),
      ]);
      expect(
        [for (final x in f) x == null ? null : (x.vnd, x.sourceIndex, x.held)],
        [
          (100, 0, false),
          (100, 0, true),
          (80, 2, false),
          (100, 0, true),
          (100, 0, true),
        ],
      );
      // Without an earlier regular price nothing is kept after a sale
      expect(fillForward([_p(0, 80, sale: true), _p(1, null)])[1], isNull);
    });

    test('a one-day sale does not keep the band low on the next days', () {
      final band = computeBand({
        'a': [
          _p(0, 100, shop: 'A'),
          _p(1, 70, shop: 'A', sale: true),
          _p(2, null),
        ],
        'b': [_p(0, 110, shop: 'B'), _p(1, null), _p(2, null)],
      });
      expect(band[1].lowVnd, 70, reason: 'the sale day itself');
      expect(band[2].lowVnd, 100, reason: "A's regular price is kept");
    });

    test('stepSpots: each day flat over its column, held days apart', () {
      final f = fillForward(_days([100, null, null, 90, 99]));
      List<(double, double)?> xy(List<FlSpot> spots) => [
        for (final s in spots) s.isNull() ? null : (s.x, s.y),
      ];
      expect(xy(stepSpots(f)), [
        (-0.5, 100),
        (0.5, 100),
        null,
        (2.5, 100),
        (2.5, 90),
        (3.5, 90),
        (3.5, 99),
        (4.5, 99),
      ]);
      expect(xy(stepSpots(f, held: true)), [(0.5, 100), (2.5, 100), null]);
    });

    test('smoothSteps: a rise or fall eased into an S, the rest kept', () {
      final s = smoothSteps([
        const FlSpot(-0.5, 100),
        const FlSpot(0.5, 100),
        const FlSpot(0.5, 80),
        const FlSpot(1.5, 80),
        FlSpot.nullSpot,
        const FlSpot(3.5, 90),
        const FlSpot(4.5, 90),
      ], samples: 4);
      expect(s, hasLength(10));
      expect(s.first, const FlSpot(-0.5, 100));
      // From 0.1 to 0.9: 100 → 80, flat at both ends, halfway at the column edge
      final change = s.sublist(1, 6);
      expect([for (final p in change) p.x], [
        for (final x in [0.1, 0.3, 0.5, 0.7, 0.9]) closeTo(x, 1e-9),
      ]);
      expect([for (final p in change) p.y], [
        for (final y in [100, 96.875, 90, 83.125, 80]) closeTo(y, 1e-9),
      ]);
      expect([for (final p in s.sublist(6)) p.isNull() ? null : (p.x, p.y)], [
        (1.5, 80),
        null,
        (3.5, 90),
        (4.5, 90),
      ]);
      // Nothing to ease
      expect(smoothSteps(const [FlSpot(0, 1), FlSpot(1, 1)]), const [
        FlSpot(0, 1),
        FlSpot(1, 1),
      ]);
    });
  });

  group('priceAxis', () {
    int ticks(({double minY, double maxY, double step}) a) =>
        (a.maxY / a.step).floor() - (a.minY / a.step).ceil() + 1;

    test('10% padding, round steps, at most 5 labels', () {
      final a = priceAxis(520000, 680000);
      expect((a.minY, a.maxY, a.step), (504000, 696000, 50000));
      expect(priceAxis(450000, 900000).step, 100000);
      for (final (low, high) in [
        (55000, 70000),
        (1700000, 2900000),
        (600000, 600000),
      ]) {
        expect(ticks(priceAxis(low, high)), inInclusiveRange(2, 5));
      }
    });
  });

  group('computeBand', () {
    test('3 shops: lowest and highest shop price, their shops, count', () {
      final band = computeBand({
        'a': [_p(0, 100000, shop: 'Shop A')],
        'b': [_p(0, 110000, max: 140000, shop: 'Shop B')],
        'c': [_p(0, 120000, shop: 'Shop C')],
      });
      final d = band.single;
      expect((d.lowVnd, d.lowShop), (100000, 'Shop A'));
      // Each shop counts with its lowest price, not its highest report
      expect((d.highVnd, d.highShop), (120000, 'Shop C'));
      expect((d.shopCount, d.isCarried, d.isRecorded), (3, false, true));
    });

    test('1 shop priced: low == high; names from shopNames when needed', () {
      final d = computeBand(
        {
          'a': [_p(0, null)],
          'b': [_p(0, 105000)],
          'c': [_p(0, null)],
        },
        shopNames: {'b': 'Shop B'},
      ).single;
      expect((d.lowVnd, d.highVnd, d.shopCount), (105000, 105000, 1));
      expect((d.lowShop, d.highShop), ('Shop B', 'Shop B'));
    });

    test('a single product: lowest and highest kept report of the day', () {
      final d = computeBand({
        'a': [_p(0, 98000, max: 99000, shop: 'Shop A')],
      }).single;
      expect((d.lowVnd, d.highVnd, d.shopCount), (98000, 99000, 1));
    });

    test('a day with only kept prices: carried, from the day recorded', () {
      final band = computeBand({
        'a': _days([100, null, null], shop: 'A'),
        'b': _days([120, null, 90], shop: 'B'),
      });
      final carried = band[1];
      expect(carried.isCarried, isTrue);
      expect(carried.isRecorded, isFalse);
      expect((carried.lowVnd, carried.highVnd), (100, 120));
      expect((carried.sourceIndex, carried.shopCount), (0, 2));
      expect(carried.day, DateTime.utc(2026, 11, 2));
      expect(band[2].isCarried, isFalse, reason: 'B has a new price');
      // A did not report: its price of day 0 still counts
      expect((band[2].lowVnd, band[2].lowFrom, band[2].shopCount), (90, 2, 2));
      expect(
        (band[2].highVnd, band[2].highShop, band[2].highFrom),
        (100, 'A', 0),
      );
    });

    test(
      'a shop that did not report keeps its price: the low does not jump',
      () {
        // A is the lowest and reports every other day; B reports every day
        final band = computeBand({
          'a': _days([90, null, 90, null, 90], shop: 'A'),
          'b': _days([120, 120, 120, 120, 120], shop: 'B'),
        });
        expect([for (final d in band) d.lowVnd], [90, 90, 90, 90, 90]);
        expect([for (final d in band) d.lowFrom], [0, 0, 2, 2, 4]);
        expect(band.every((d) => d.shopCount == 2 && !d.isCarried), isTrue);
      },
    );

    test('equal prices: the more recent one', () {
      final d = computeBand({
        'a': _days([90, null], shop: 'A'),
        'b': _days([null, 90], shop: 'B'),
      })[1];
      expect((d.lowShop, d.lowFrom), ('B', 1));
    });

    test(
      'more than 7 days without a price: no band; never before the start',
      () {
        final band = computeBand({
          'a': _days([null, 100, ...List.filled(8, null), 90]),
          'b': _days(List.filled(11, null)),
        });
        expect(band[0].lowVnd, isNull, reason: 'before the first price');
        expect(band.sublist(2, 9).every((d) => d.isCarried), isTrue);
        expect(band[9].lowVnd, isNull);
        expect((band[9].isCarried, band[9].shopCount), (false, 0));
        expect(band[10].isRecorded, isTrue);
      },
    );

    test('from a view: single product range from the reports', () async {
      final band = bandOf(await _view(_single()));
      expect((band[0].lowVnd, band[0].highVnd), (100000, 101000));
      expect(band[0].lowShop, 'Shop A');
      expect(band[2].isCarried, isTrue, reason: '08/11: 1 report only');
      expect(band[5].highVnd, 91000, reason: 'after voucher never counts');
    });
  });

  group('axisDayIndices', () {
    test('first, last, sale day, then the biggest price changes, spaced', () {
      final prices = List<int?>.filled(30, 100000);
      for (var d = 5; d <= 15; d++) {
        prices[d] = 80000; // −20k on day 5, +20k on day 16
      }
      prices[24] = 96000; // −4k, +4k on day 25: smaller, left out
      final band = computeBand({'a': _days(prices)});
      final sale = SaleEvent(
        id: 's',
        name: '12.12',
        // 12/11 00:00 in Vietnam = day 11 of _days
        date: DateTime.utc(2026, 11, 11, 17),
        type: SaleType.doubleDay,
        confirmed: true,
      );
      final days = axisDayIndices(band, [sale]);
      expect(days, unorderedEquals(<int>[0, 5, 11, 16, 29]));
      final sorted = days.toList()..sort();
      for (var k = 1; k < sorted.length; k++) {
        expect(sorted[k] - sorted[k - 1], greaterThanOrEqualTo(5));
      }
    });

    test('a change too close to a label is skipped', () {
      final prices = List<int?>.filled(30, 100000);
      prices[2] = 70000; // big, but 2 days from day 0
      prices[3] = 100000;
      final days = axisDayIndices(computeBand({'a': _days(prices)}), const []);
      expect(days, unorderedEquals(<int>[0, 29]));
      expect(axisDayIndices(const [], const []), isEmpty);
    });
  });

  group('buildPriceMilestones', () {
    final today = DateTime.utc(2026, 11, 12, 5);
    BandDay day(
      int d,
      int low,
      int high, {
      String? shop,
      bool carried = false,
    }) => BandDay(
      day: DateTime.utc(2026, 11, 6 + d),
      lowVnd: low,
      lowShop: shop,
      highVnd: high,
      highShop: shop == null ? null : '$shop+',
      shopCount: 2,
      isCarried: carried,
      sourceIndex: d,
    );

    test('4 rows in order, with day, shop and sale', () {
      final band = [
        day(0, 100, 130, shop: 'A'),
        day(1, 100, 130, shop: 'A', carried: true),
        day(2, 95, 110, shop: 'B'),
        day(3, 105, 120, shop: 'C'),
        BandDay(day: DateTime.utc(2026, 11, 10)),
        day(5, 90, 99, shop: 'A'),
        day(6, 99, 101, shop: 'C'),
      ];
      final rows = buildPriceMilestones(
        band,
        SavedPrice(vnd: 115, savedAt: DateTime.utc(2026, 10, 1, 3)),
        [_sale],
        today,
      );
      expect([for (final r in rows) r.kind], PriceMilestoneKind.values);
      expect(
        [for (final r in rows) r.kind.label],
        ['Thấp nhất', 'Cao nhất', 'Lúc bạn lưu', 'Hiện tại thấp nhất'],
      );
      final [low, high, saved, latest] = rows;
      expect(
        (low.vnd, low.dayIndex, low.detail),
        (90, 5, 'Hôm qua · A · 11.11'),
      );
      expect((high.vnd, high.dayIndex, high.detail), (130, 0, '06/11 · A+'));
      // Saved before the period: shown, not tappable
      expect((saved.vnd, saved.dayIndex, saved.detail), (115, null, '01/10'));
      expect(
        (latest.vnd, latest.dayIndex, latest.detail),
        (99, 6, 'Hôm nay · C'),
      );
    });

    test('without a saved price: 3 rows', () {
      final rows = buildPriceMilestones(
        [day(0, 100, 120, shop: 'A'), day(1, 90, 95, shop: 'B')],
        null,
        const [],
        today,
      );
      expect(
        [for (final r in rows) r.kind],
        [
          PriceMilestoneKind.lowest,
          PriceMilestoneKind.highest,
          PriceMilestoneKind.latest,
        ],
      );
    });

    test('same price on several days: the most recent one', () {
      final rows = buildPriceMilestones(
        [
          day(0, 90, 120, shop: 'A'),
          day(2, 90, 120, shop: 'B'),
          day(4, 95, 100, shop: 'C'),
        ],
        null,
        const [],
        today,
      );
      expect((rows[0].dayIndex, rows[0].shop), (1, 'B'));
      expect((rows[1].dayIndex, rows[1].shop), (1, 'B+'));
    });

    test('carried days never give the lowest or highest', () {
      final rows = buildPriceMilestones(
        [day(0, 100, 120), day(1, 50, 900, carried: true), day(2, 110, 115)],
        null,
        const [],
        today,
      );
      expect((rows[0].vnd, rows[1].vnd, rows[2].vnd), (100, 120, 110));
    });

    test('no recorded day: only the saved price', () {
      final rows = buildPriceMilestones(
        [BandDay(day: DateTime.utc(2026, 11, 12))],
        SavedPrice(vnd: 100, savedAt: today),
        const [],
        today,
      );
      expect([for (final r in rows) r.kind], [PriceMilestoneKind.saved]);
      expect((rows.single.dayIndex, rows.single.dayLabel), (0, 'Hôm nay'));
    });
  });

  testWidgets('30 days by default', (tester) async {
    final vm = PriceHistoryViewModel(service: _single(), now: () => _now);
    addTearDown(vm.dispose);
    await vm.openProduct('a');
    expect(vm.range, PriceHistoryRange.month);
  });

  testWidgets('a light band and ONE violet line of the lowest price', (
    tester,
  ) async {
    await _pump(tester, await _view(_single()));

    final data = _data(tester);
    final accent = priceLineColor(AppTheme.lightTheme);
    final bars = data.lineBarsData;
    // Band edges (invisible), held part, recorded part, dots
    expect(bars, hasLength(5));
    final between = data.betweenBarsData.single;
    expect((between.fromIndex, between.toIndex), (0, 1));
    expect(between.color!.a, lessThan(0.3));
    expect(between.color!.withValues(alpha: 1), accent);
    expect(bars[0].spots.first, const FlSpot(-0.5, 100000));
    expect(bars[1].spots.first, const FlSpot(-0.5, 101000));
    for (final edge in bars.take(2)) {
      expect(edge.barWidth, 0);
      expect(edge.spots.where((s) => s.isNull()), isEmpty);
    }

    final [held, line] = _lines(data);
    expect(line.color, accent);
    expect(line.dashArray, isNull);
    expect(line.spots.first, const FlSpot(-0.5, 100000));
    expect(line.spots.last, const FlSpot(6.5, 99000));
    // 08/11–09/11 keep 07/11's price: dashed and fainter
    expect(held.dashArray, isNotNull);
    expect(held.color!.a, lessThan(line.color!.a));
    expect(held.spots.take(2), const [
      FlSpot(1.5, 100000),
      FlSpot(3.5, 100000),
    ]);
    expect(find.text('Từng shop'), findsNothing);
  });

  testWidgets('group: the band between the shops, still one line', (
    tester,
  ) async {
    await _pump(tester, await _view(_group(), group: true));

    final data = _data(tester);
    final recorded = [
      for (final b in _lines(data))
        if (b.dashArray == null) b,
    ];
    expect(recorded, hasLength(1));
    // 06/11: A 100k … C 120k
    expect(data.lineBarsData[0].spots.first, const FlSpot(-0.5, 100000));
    expect(data.lineBarsData[1].spots.first, const FlSpot(-0.5, 120000));
    // 12/11: A did not report; its 97k of 11/11 is still the lowest (not C's 101k)
    expect(recorded.single.spots.last, const FlSpot(6.5, 97000));
    // Only 08/11 has no new price at all: the one dashed part
    final held = [
      for (final b in _lines(data))
        if (b.dashArray != null) b,
    ];
    expect(held.single.spots.where((s) => !s.isNull()), const [
      FlSpot(1.5, 102000),
      FlSpot(2.5, 102000),
    ]);
    expect(
      find.text(
        'Vùng tô: từ giá thấp nhất tới cao nhất giữa các shop mỗi ngày',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a card: caption on top, no price axis or grid, 2 dates', (
    tester,
  ) async {
    await _pump(tester, await _view(_single()));

    final card = find.byKey(const ValueKey('price-chart-card'));
    final caption = tester.widget<Text>(
      find.byKey(const ValueKey('price-chart-caption')),
    );
    expect(
      caption.data,
      'Vùng tô: từ giá thấp nhất tới cao nhất ghi được mỗi ngày',
    );
    expect(caption.textAlign, TextAlign.center);
    expect(
      tester.getRect(find.byWidget(caption)).bottom,
      lessThan(tester.getRect(find.byType(LineChart)).top),
    );
    expect(
      find.descendant(of: card, matching: find.byType(LineChart)),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('price-legend')), findsNothing);

    final data = _data(tester);
    expect(data.titlesData.leftTitles.sideTitles.showTitles, isFalse);
    expect(data.titlesData.bottomTitles.sideTitles.showTitles, isFalse);
    expect(data.gridData.show, isFalse);
    // First and last day at the plot's edges, plus 10/11 when the price moved
    // (11/11 is too close to the last day and already named above the plot)
    final dates = find.byKey(const ValueKey('price-chart-dates'));
    final texts = tester
        .widgetList<Text>(
          find.descendant(of: dates, matching: find.byType(Text)),
        )
        .map((t) => t.data);
    expect(texts, ['06/11', '10/11', '12/11']);
    final plot = tester.getRect(find.byType(LineChart));
    expect(tester.getRect(find.text('06/11')).left, plot.left);
    expect(tester.getRect(find.text('12/11')).right, plot.right);
  });

  testWidgets('"Giá lúc bạn lưu": dashed horizontal line, label on the right', (
    tester,
  ) async {
    await _pump(
      tester,
      await _view(_single()),
      saved: SavedPrice(vnd: 105000, savedAt: _at(20)),
    );

    final data = _data(tester);
    final saved = data.extraLinesData.horizontalLines.single;
    expect(saved.y, 105000);
    expect(saved.dashArray, isNotNull);
    expect(saved.label.show, isTrue);
    expect(saved.label.alignment, Alignment.topRight);
    expect(saved.label.labelResolver(saved), 'giá lúc bạn lưu');
    // The axis makes room for it
    expect(data.maxY, greaterThan(105000));
  });

  testWidgets('one green dot on the lowest point, its price in short', (
    tester,
  ) async {
    await _pump(tester, await _view(_single()), selected: 3);

    final (spot, dot) = _marks(_data(tester)).single;
    expect(spot, const FlSpot(5, 90000));
    expect(dot.label, '90k');
    expect(dot.color, lowestDotColor(AppTheme.lightTheme));
    expect(dot.labelOnLeft, isFalse);
  });

  testWidgets('Y range: 10% padding around the data shown', (tester) async {
    await _pump(tester, await _view(_single()));

    final data = _data(tester);
    // 90k–101k → 88,9k–102,1k
    expect(data.minY, closeTo(88900, 0.01));
    expect(data.maxY, closeTo(102100, 0.01));
  });

  testWidgets('sale day: dashed vertical line, "11.11" above the plot', (
    tester,
  ) async {
    await _pump(tester, await _view(_single()));

    final data = _data(tester);
    final line = data.extraLinesData.verticalLines.single;
    expect(line.x, 5);
    expect(line.dashArray, isNotNull);
    expect(line.color!.a, lessThanOrEqualTo(0.5));
    expect(line.label.show, isFalse);
    expect(data.titlesData.topTitles.sideTitles.showTitles, isTrue);

    final plot = tester.getRect(find.byType(LineChart));
    final label = tester.getRect(find.text('11.11'));
    expect(label.bottom, lessThanOrEqualTo(plot.top + 18));
    // Centered on the column of 11/11
    expect(label.center.dx, closeTo(plot.left + plot.width * 5.5 / 7, 1));
  });

  testWidgets('day details: lowest, highest, reports, sale, after voucher', (
    tester,
  ) async {
    await _pump(tester, await _view(_single()), selected: 5);

    expect(_details(tester), [
      '11/11/2026',
      'Thấp nhất: 90.000 ₫ · Shop A',
      'Cao nhất: 91.000 ₫ · Shop A',
      '2 báo cáo',
      '11.11',
      'Sau voucher (tham khảo): 80.000 ₫',
    ]);
    final voucher = tester.widget<Text>(
      find.text('Sau voucher (tham khảo): 80.000 ₫'),
    );
    expect(
      voucher.style!.color,
      AppTheme.lightTheme.colorScheme.onSurfaceVariant,
    );
  });

  testWidgets('day details of a carried day', (tester) async {
    await _pump(tester, await _view(_single()), selected: 2);

    expect(_details(tester), [
      '08/11/2026',
      'Thấp nhất: 100.000 ₫ · Shop A',
      'Chưa có giá mới · giá ghi ngày 07/11',
      'Chưa đủ dữ liệu (1 báo cáo)',
    ]);
  });

  testWidgets('day details of a group: shops with a price', (tester) async {
    final view = await _view(_group(), group: true);
    await _pump(tester, view, selected: 0);
    expect(_details(tester), [
      '06/11/2026',
      'Thấp nhất: 100.000 ₫ · Shop A',
      'Cao nhất: 120.000 ₫ · Shop C',
      '3 shop có giá',
    ]);

    // Only B reported: A and C count with their recent prices, dated
    await _pump(tester, view, selected: 3);
    expect(_details(tester), [
      '09/11/2026',
      'Thấp nhất: 102.000 ₫ · Shop A · ghi ngày 07/11',
      'Cao nhất: 120.000 ₫ · Shop C · ghi ngày 06/11',
      '3 shop có giá',
    ]);

    await _pump(tester, view, selected: 2);
    expect(_details(tester), [
      '08/11/2026',
      'Thấp nhất: 102.000 ₫ · Shop A',
      'Cao nhất: 120.000 ₫ · Shop C · ghi ngày 06/11',
      '3 shop có giá',
      'Chưa có giá mới · giá ghi ngày 07/11',
    ]);
  });

  testWidgets('touching anywhere in a day\'s column shows that day', (
    tester,
  ) async {
    await _pump(tester, await _view(_single()));
    expect(find.byKey(const ValueKey('price-day-details')), findsNothing);
    final box = tester.getRect(find.byKey(const ValueKey('price-chart-touch')));
    double columnX(int i) => box.left + box.width * (i + 0.5) / 7;

    await tester.tapAt(Offset(box.right - 2, box.top + 2));
    await tester.pump();
    expect(_details(tester).first, '12/11/2026');
    final band = _data(tester).rangeAnnotations.verticalRangeAnnotations;
    expect((band.single.x1, band.single.x2), (5.5, 6.5));

    // Between the 2 dates under the plot
    final dates = tester.getRect(
      find.byKey(const ValueKey('price-chart-dates')),
    );
    await tester.tapAt(Offset(columnX(5) + 3, dates.center.dy));
    await tester.pump();
    expect(_details(tester).first, '11/11/2026');

    await tester.dragFrom(
      Offset(columnX(5), box.center.dy),
      Offset(columnX(0) - columnX(5), 0),
    );
    await tester.pump();
    expect(_details(tester).first, '06/11/2026');
  });

  testWidgets('milestones under the chart; tapping one marks its day', (
    tester,
  ) async {
    await _pump(
      tester,
      await _view(_single()),
      saved: SavedPrice(vnd: 105000, savedAt: _at(20)),
    );

    final list = find.byKey(const ValueKey('price-milestones'));
    expect(
      tester.getRect(list).top,
      greaterThan(tester.getRect(find.byType(LineChart)).bottom),
    );
    String row(PriceMilestoneKind k) => [
      for (final t in tester.widgetList<Text>(
        find.descendant(
          of: find.byKey(ValueKey('price-milestone-${k.name}')),
          matching: find.byType(Text),
        ),
      ))
        t.data!,
    ].join(' | ');
    expect(
      row(PriceMilestoneKind.lowest),
      'Thấp nhất | Hôm qua · Shop A · 11.11 | 90.000 ₫',
    );
    expect(
      row(PriceMilestoneKind.highest),
      'Cao nhất | 06/11 · Shop A | 101.000 ₫',
    );
    expect(row(PriceMilestoneKind.saved), 'Lúc bạn lưu | 23/10 | 105.000 ₫');
    expect(
      row(PriceMilestoneKind.latest),
      'Hiện tại thấp nhất | Hôm nay · Shop A | 99.000 ₫',
    );
    // The 2 tiles of G5b are gone
    expect(find.byKey(const ValueKey('price-summary-lowest')), findsNothing);
    expect(find.text('Thấp nhất trong kỳ'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('price-milestone-highest')));
    await tester.pump();
    expect(_details(tester).first, '06/11/2026');
    final band = _data(tester).rangeAnnotations.verticalRangeAnnotations;
    expect((band.single.x1, band.single.x2), (-0.5, 0.5));

    for (final word in [
      'Nên mua',
      'nên mua',
      'nên chọn',
      'rẻ nhất',
      'Rẻ nhất',
    ]) {
      expect(find.textContaining(word), findsNothing, reason: word);
    }
  });

  testWidgets('fewer than 5 days with a price: milestones only', (
    tester,
  ) async {
    await _pump(tester, await _view(_sparse(), range: PriceHistoryRange.month));

    expect(find.byType(LineChart), findsNothing);
    expect(find.byKey(const ValueKey('price-legend')), findsNothing);
    expect(
      find.text('Chưa đủ dữ liệu để vẽ biểu đồ (3 ngày có giá)'),
      findsOneWidget,
    );
    expect(find.text('Thấp nhất'), findsOneWidget);
    expect(find.text('110.000 ₫'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('price-milestone-lowest')));
    await tester.pump();
    expect(_details(tester).first, '03/11/2026');
  });

  testWidgets('7N / 30N / 90N buttons', (tester) async {
    PriceHistoryRange? picked;
    await _pump(tester, await _view(_single()), onRange: (r) => picked = r);

    expect(find.text('7N'), findsOneWidget);
    expect(find.text('30N'), findsOneWidget);
    await tester.tap(find.text('90N'));
    expect(picked, PriceHistoryRange.quarter);
  });

  testWidgets('"Dữ liệu mẫu" only for sample data', (tester) async {
    await _pump(tester, await _view(_single(demo: true)));
    expect(find.text('Dữ liệu mẫu'), findsOneWidget);

    await _pump(tester, await _view(_single()));
    expect(find.text('Dữ liệu mẫu'), findsNothing);
  });

  for (final dark in [false, true]) {
    testWidgets('gallery, ${dark ? 'dark' : 'light'}: group, one product, '
        'too few days', (tester) async {
      final theme = dark ? AppTheme.darkTheme : AppTheme.lightTheme;
      tester.view.physicalSize = const Size(412, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: SingleChildScrollView(child: PriceChartGallerySection()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final charts = tester
          .widgetList<PriceHistoryChart>(find.byType(PriceHistoryChart))
          .toList();
      expect(charts, hasLength(3));
      expect(charts[0].view.isGroup, isTrue);
      expect(charts[1].savedPrice, isNotNull);
      expect(find.byType(LineChart), findsNWidgets(2));
      expect(find.byKey(const ValueKey('price-too-few')), findsOneWidget);
      final group = tester.widgetList<LineChart>(find.byType(LineChart)).first;
      expect(_lines(group.data).last.color, priceLineColor(theme));
      expect(tester.takeException(), isNull);
    });
  }

  group('shop links in the day details', () {
    /// Two real-looking Shopee products: A 100k, B 120k on the last 2 days
    InMemoryPriceHistoryService linked({bool demo = false}) =>
        InMemoryPriceHistoryService(
          products: {
            'shopee:11:21': _product('shopee:11:21', 'Shop A', demo: demo),
            'shopee:12:22': _product('shopee:12:22', 'Shop B', demo: demo),
          },
          reports: {
            'shopee:11:21': [..._two(100000, 1), ..._two(100000, 0)],
            'shopee:12:22': [..._two(120000, 1), ..._two(120000, 0)],
          },
          groupKeys: const ['shopee:11:21', 'shopee:12:22'],
        );

    test('lowest and highest shop open their own Shopee listing', () async {
      final view = await _view(linked(), group: true);
      final shops = [
        for (final l in describeDay(view, bandOf(view), 6)) ?l.shop,
      ];
      expect([for (final s in shops) (s.name, s.url)], [
        ('Shop A', 'https://shopee.vn/product/11/21'),
        ('Shop B', 'https://shopee.vn/product/12/22'),
      ]);
    });

    test('sample shops are named but have no Shopee link', () async {
      final view = await _view(linked(demo: true), group: true);
      final shops = [
        for (final l in describeDay(view, bandOf(view), 6)) ?l.shop,
      ];
      expect([for (final s in shops) s.name], ['Shop A', 'Shop B']);
      expect([for (final s in shops) s.url], [null, null]);
    });

    testWidgets('the shop name is the link; a sample shop says it has no page', (
      tester,
    ) async {
      await _pump(
        tester,
        await _view(linked(demo: true), group: true),
        selected: 6,
      );
      expect(_details(tester), contains('Thấp nhất: 100.000 ₫ · Shop A'));

      final line = tester.widget<Text>(
        find.byKey(const ValueKey('price-day-shop-shopee:11:21')),
      );
      final link = (line.textSpan! as TextSpan).children!
          .whereType<TextSpan>()
          .singleWhere((s) => s.recognizer != null);
      expect(link.text, 'Shop A');
      expect(link.style!.decoration, TextDecoration.underline);

      (link.recognizer! as TapGestureRecognizer).onTap!();
      await tester.pump();
      expect(
        find.text('Shop A là shop mẫu, không có trang Shopee thật.'),
        findsOneWidget,
      );
    });
  });
}
