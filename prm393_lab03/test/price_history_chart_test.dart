import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
  double? rating,
}) => PriceHistoryReport(
  id: 'r${_n++}',
  amountVnd: amount,
  priceType: type,
  observedAt: _at(daysBack, _n % 5),
  shopName: shop,
  productRating: rating,
);

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

/// Product "a" (shop A) over 7 days:
/// 11/06: 100k, 101k (★ 4.8) · 11/08: one report · 11/11: sale 90k, 91k and
/// after-voucher 80k, 82k · 11/12: 99k, 99k
InMemoryPriceHistoryService _single({bool demo = false}) =>
    InMemoryPriceHistoryService(
      products: {'a': _product('a', 'Shop A', demo: demo)},
      reports: {
        'a': [
          _r(100000, 6, shop: 'Shop A', rating: 4.8),
          _r(101000, 6, shop: 'Shop A', rating: 4.8),
          _r(95000, 4, shop: 'Shop A'),
          _r(90000, 1, type: HistoryPriceType.sale, shop: 'Shop A'),
          _r(91000, 1, type: HistoryPriceType.sale, shop: 'Shop A'),
          _r(80000, 1, type: HistoryPriceType.afterVoucher),
          _r(82000, 1, type: HistoryPriceType.afterVoucher),
          _r(99000, 0, shop: 'Shop A'),
          _r(99000, 0, shop: 'Shop A'),
        ],
      },
      sales: [_sale],
    );

InMemoryPriceHistoryService _group() => InMemoryPriceHistoryService(
  products: {
    'a': _product('a', 'Shop A'),
    'b': _product('b', 'Shop B'),
    'c': _product('c', 'Shop C'),
  },
  reports: {
    'a': [_r(100000, 0, rating: 4.2), _r(101000, 0, rating: 4.2)],
    'b': [_r(110000, 0, rating: 4.9), _r(111000, 0, rating: 4.9)],
    'c': [_r(120000, 0, rating: 4.5), _r(121000, 0, rating: 4.5)],
  },
  groupKeys: const ['a', 'b', 'c'],
);

Future<PriceHistoryView> _view(
  InMemoryPriceHistoryService service, {
  bool group = false,
}) async {
  final vm = PriceHistoryViewModel(service: service, now: () => _now);
  addTearDown(vm.dispose);
  vm.setRange(PriceHistoryRange.week);
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
  bool voucherDots = false,
  ValueChanged<PriceHistoryRange>? onRange,
}) async {
  tester.view.physicalSize = const Size(412, 1000);
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
            showAfterVoucherDots: voucherDots,
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

void main() {
  testWidgets('step line with dots; null days break the line', (tester) async {
    await _pump(tester, await _view(_single()));

    final bars = _data(tester).lineBarsData;
    expect(bars, hasLength(1), reason: 'no after-voucher dots by default');
    final line = bars.single;
    expect(line.isStepLineChart, isTrue);
    expect(line.dotData.show, isTrue);
    // 7 days: 11/06 price, 11/07 none, 11/08 one report, 11/09–10 none, 11/11, 11/12
    expect(line.spots, hasLength(7));
    expect(
      [for (final s in line.spots) s.isNull() ? null : s.y],
      [100000, null, null, null, null, 90000, 99000],
    );
  });

  testWidgets('after-voucher prices: never a line, optional hollow dots', (
    tester,
  ) async {
    await _pump(tester, await _view(_single()), voucherDots: true);

    final bars = _data(tester).lineBarsData;
    expect(bars, hasLength(2));
    final dots = bars.last;
    expect(dots.barWidth, 0);
    expect(dots.spots[5].y, 80000);
  });

  testWidgets('sale day: faint vertical line labelled "11.11"', (tester) async {
    await _pump(tester, await _view(_single()));

    final lines = _data(tester).extraLinesData.verticalLines;
    expect(lines, hasLength(1));
    expect(lines.single.x, 5);
    expect(lines.single.label.labelResolver(lines.single), '11.11');
    expect(lines.single.color!.a, lessThan(0.5));
  });

  testWidgets('a day with 1 report: "Chưa đủ dữ liệu (1 báo cáo)"', (
    tester,
  ) async {
    await _pump(tester, await _view(_single()), selected: 2);

    expect(find.text('08/11/2026'), findsOneWidget);
    expect(find.text('Chưa đủ dữ liệu (1 báo cáo)'), findsOneWidget);
  });

  testWidgets('a sale day: price, shop, count, "Đang giảm", after voucher', (
    tester,
  ) async {
    await _pump(tester, await _view(_single()), selected: 5);

    expect(find.text('Thấp nhất: 90.000 ₫ · Shop A'), findsOneWidget);
    expect(find.text('2 báo cáo'), findsOneWidget);
    expect(find.text('Đang giảm'), findsOneWidget);
    final voucher = tester.widget<Text>(
      find.text('Sau voucher (tham khảo): 80.000 ₫'),
    );
    expect(
      voucher.style!.color,
      AppTheme.lightTheme.colorScheme.onSurfaceVariant,
    );
    // Rating shown with the lowest price
    await _pump(tester, await _view(_single()), selected: 0);
    expect(find.text('Thấp nhất: 100.000 ₫ · Shop A · ★ 4,8'), findsOneWidget);
  });

  testWidgets('tapping the chart shows that day', (tester) async {
    await _pump(tester, await _view(_single()));
    expect(find.byKey(const ValueKey('price-day-details')), findsNothing);

    // Right edge of the plot = the last day (12/11)
    final box = tester.getRect(find.byType(LineChart));
    await tester.tapAt(Offset(box.right - 2, box.center.dy));
    await tester.pump();

    expect(find.byKey(const ValueKey('price-day-details')), findsOneWidget);
    expect(find.text('12/11/2026'), findsOneWidget);
    expect(find.text('Thấp nhất: 99.000 ₫ · Shop A'), findsOneWidget);
  });

  testWidgets('summary in words under the chart', (tester) async {
    await _pump(tester, await _view(_single()));

    expect(
      tester.widget<Text>(find.byKey(const ValueKey('price-summary'))).data,
      'Thấp nhất 7 ngày: 90.000 ₫ ngày 11/11 tại Shop A. Giá gần nhất: '
      '99.000 ₫ ngày 12/11 tại Shop A (có dữ liệu 3/7 ngày).',
    );
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

  testWidgets('group: one line per shop, legend with names, distinct dashes', (
    tester,
  ) async {
    await _pump(tester, await _view(_group(), group: true), selected: 6);

    final bars = _data(tester).lineBarsData;
    expect(bars, hasLength(3));
    expect({for (final b in bars) b.dashArray?.join(',')}, hasLength(3));
    for (final name in ['Shop A', 'Shop B', 'Shop C']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('Thấp nhất: 100.000 ₫ · Shop A · ★ 4,2'), findsOneWidget);
    expect(
      find.text('Rating cao nhất: ★ 4,9 · Shop B · 110.000 ₫'),
      findsOneWidget,
    );
    expect(find.text('6 báo cáo'), findsOneWidget);
  });

  test('line colors keep 3:1 contrast on both themes', () {
    double contrast(Color a, Color b) {
      final (l1, l2) = (a.computeLuminance(), b.computeLuminance());
      return (l1 > l2 ? l1 + 0.05 : l2 + 0.05) /
          (l1 > l2 ? l2 + 0.05 : l1 + 0.05);
    }

    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      final colors = seriesColors(theme);
      expect(colors.toSet(), hasLength(4));
      for (final c in colors) {
        expect(
          contrast(c, theme.colorScheme.surface),
          greaterThanOrEqualTo(3),
          reason: '$c on ${theme.brightness}',
        );
      }
    }
  });

  testWidgets('gallery section builds both charts', (tester) async {
    tester.view.physicalSize = const Size(412, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: SingleChildScrollView(child: PriceChartGallerySection()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(PriceHistoryChart), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
