import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/app/routes.dart';
import 'package:prm393_lab03/models/price_insights.dart';
import 'package:prm393_lab03/models/price_snapshot.dart';
import 'package:prm393_lab03/models/wishlist_item.dart';
import 'package:prm393_lab03/screens/dev/price_chart_gallery.dart';
import 'package:prm393_lab03/screens/price_history_screen.dart';
import 'package:prm393_lab03/services/analytics_service.dart';
import 'package:prm393_lab03/services/crashlytics_service.dart';
import 'package:prm393_lab03/services/price_history_service.dart';
import 'package:prm393_lab03/viewmodels/decision_support_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/own_price_view.dart';
import 'package:prm393_lab03/viewmodels/price_history_viewmodel.dart';
import 'package:prm393_lab03/widgets/price_history_chart.dart';
import 'package:prm393_lab03/widgets/price_history_panel.dart';
import 'package:provider/provider.dart';

import 'support/linked_auth_fakes.dart';
import 'support/test_theme.dart';

/// Lịch sử giá of any item: [snapshots]
class _Decision extends ChangeNotifier implements DecisionSupportViewModel {
  final List<PriceSnapshot> snapshots;

  _Decision(this.snapshots);

  @override
  DateTime get now => DateTime.now();

  @override
  PriceInsights? priceInsightsFor(WishlistItem item) =>
      PriceInsights(snapshots, now: now);

  @override
  Future<void> loadPriceHistory(WishlistItem item) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Analytics extends Fake implements AppAnalyticsService {
  @override
  Future<void> logViewPriceHistory({
    required String mode,
    required int rangeDays,
    required bool isDemo,
  }) async {}
}

const _keys = InMemoryPriceHistoryService.keys;

/// The user's prices [prices] (newest first), one a day from today back
List<PriceSnapshot> _mine(List<int> prices) {
  final now = DateTime.now();
  return [
    for (final (d, vnd) in prices.indexed)
      PriceSnapshot(
        id: 's$d',
        amountVnd: vnd,
        observedAt: now.subtract(Duration(days: d)),
      ),
  ];
}

WishlistItem _item({String? productKey, bool hasPrice = true}) => WishlistItem(
  id: 'i',
  title: 'Máy ảnh film mini',
  createdAt: DateTime.now().subtract(const Duration(days: 40)),
  latestPriceVnd: hasPrice ? 600000 : null,
  latestPriceAt: hasPrice ? DateTime.now() : null,
  productKey: productKey,
);

Future<void> _pump(
  WidgetTester tester,
  WishlistItem item,
  List<PriceSnapshot> prices, {
  PriceHistoryService? service,
  VoidCallback? onAddLink,
}) async {
  tester.view.physicalSize = const Size(412, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<DecisionSupportViewModel>.value(
          value: _Decision(prices),
        ),
        if (service != null)
          Provider<PriceHistoryService>.value(value: service),
        Provider<AppAnalyticsService>.value(value: _Analytics()),
        Provider<CrashlyticsService>.value(value: CountingCrashlytics()),
      ],
      child: MaterialApp(
        theme: testAppTheme,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PriceHistoryPanel(
              item: item,
              showSharedPrices: true,
              onAddLink: onAddLink,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ownPriceView (G6b)', () {
    // 12:00 in Vietnam
    final now = DateTime.utc(2026, 11, 12, 5);
    PriceSnapshot s(
      int vnd,
      int daysAgo, {
      PriceType type = PriceType.single,
      PriceSource source = PriceSource.manual,
      int? min,
      int? max,
    }) => PriceSnapshot(
      id: '$vnd-$daysAgo',
      amountVnd: vnd,
      observedAt: now.subtract(Duration(days: daysAgo)),
      priceType: type,
      source: source,
      minVnd: min,
      maxVnd: max,
    );

    test('a point a day: lowest and highest; never after voucher or community', () {
      final view = ownPriceView(
        [
          s(500000, 0),
          s(480000, 0),
          s(450000, 1, type: PriceType.afterVoucher),
          s(300000, 2, source: PriceSource.community),
          s(400000, 3, type: PriceType.range, min: 400000, max: 520000),
          s(350000, 4, type: PriceType.sale),
          s(900000, 40),
        ],
        range: PriceHistoryRange.month,
        now: now,
        shopName: 'Shop A',
      );

      expect(view.days, hasLength(30));
      expect(view.days.last, DateTime.utc(2026, 11, 12));
      final points = view.points[ownPricesKey]!;
      expect(points, hasLength(30));
      expect(
        [for (final p in points.sublist(25)) (p.minVnd, p.maxVnd)],
        [
          (350000, 350000),
          (400000, 520000),
          (null, null),
          (null, null),
          (480000, 500000),
        ],
      );
      expect(points[25].hasSale, isTrue);
      expect(points.last.reportCount, 2);
      expect(points.last.shopName, 'Shop A');
      expect(view.summary.daysWithData, 3);
      expect(view.isGroup, isFalse);
      expect(view.isDemo, isFalse);
    });

    test("ownPriceDots: the user's price on the days of another view", () {
      final own = ownPriceView(
        [s(500000, 0), s(450000, 3)],
        range: PriceHistoryRange.month,
        now: now,
      );
      final week = ownPriceView(
        const [],
        range: PriceHistoryRange.week,
        now: now,
      );
      expect(ownPriceDots(week, own), {6: 500000, 3: 450000});
    });
  });

  group('Lịch sử giá on Chi tiết món (G6b)', () {
    testWidgets('no Shopee link: only "Giá bạn ghi", a button to add the link', (
      tester,
    ) async {
      var addLink = 0;
      await _pump(
        tester,
        _item(),
        _mine([600000, 590000, 610000, 600000, 580000, 600000]),
        service: InMemoryPriceHistoryService.sample(DateTime.now()),
        onAddLink: () => addLink++,
      );

      expect(find.byKey(const ValueKey('price-chart-own')), findsOneWidget);
      expect(find.byKey(const ValueKey('price-chart-card')), findsOneWidget);
      expect(find.text('Giá bạn đã ghi'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('price-chart-community')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('price-community-too-few')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('price-fullscreen')), findsNothing);
      expect(find.text('Các lần ghi (6)'), findsOneWidget);
      expect(
        find.text(
          'Có link thì xem được giá người khác ghi và cùng món ở shop khác.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Thêm link Shopee'));
      expect(addLink, 1);
    });

    testWidgets('a link, too few people: "Giá bạn ghi" and why no community line', (
      tester,
    ) async {
      await _pump(
        tester,
        _item(productKey: _keys.first),
        _mine([600000, 590000, 610000, 600000, 580000, 600000]),
        service: InMemoryPriceHistoryService.sparse(DateTime.now()),
      );

      expect(find.byKey(const ValueKey('price-chart-own')), findsOneWidget);
      expect(
        find.text('Chưa đủ người ghi giá để vẽ đường cộng đồng (6 lần ghi)'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('price-fullscreen')), findsNothing);
      expect(find.byKey(const ValueKey('price-add-link')), findsNothing);
    });

    testWidgets('enough community prices: both layers and the full screen', (
      tester,
    ) async {
      await _pump(
        tester,
        _item(productKey: _keys.first),
        _mine([600000, 590000, 610000, 600000, 580000, 600000]),
        service: InMemoryPriceHistoryService.sample(DateTime.now()),
      );

      final chart = find.byKey(const ValueKey('price-chart-community'));
      expect(chart, findsOneWidget);
      expect(find.byKey(const ValueKey('price-chart-own')), findsNothing);
      expect(
        find.text('Vùng tô: từ giá thấp nhất tới cao nhất ghi được mỗi ngày'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('price-chart-own-legend')),
        findsOneWidget,
      );
      expect(find.text('Dữ liệu mẫu'), findsOneWidget);
      // The user's 6 prices: hollow dots, before the lowest-price dot
      final data = tester
          .widget<LineChart>(
            find.descendant(of: chart, matching: find.byType(LineChart)),
          )
          .data;
      final own = data.lineBarsData[data.lineBarsData.length - 2];
      expect(own.spots, hasLength(6));
      expect(own.barWidth, 0);
      final dot =
          own.dotData.getDotPainter(own.spots.first, 0, own, 0)
              as PriceDotPainter;
      expect(dot.hollow, isTrue);
      expect(
        find.byKey(const ValueKey('price-community-too-few')),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('price-fullscreen')));
      await tester.pumpAndSettle();
      expect(find.byType(PriceHistoryScreen), findsOneWidget);
    });

    testWidgets('fewer than 5 days with a price: milestones only', (
      tester,
    ) async {
      await _pump(tester, _item(), _mine([600000]));

      expect(find.byKey(const ValueKey('price-too-few')), findsOneWidget);
      expect(find.byKey(const ValueKey('price-chart-card')), findsNothing);
      expect(find.byKey(const ValueKey('price-milestones')), findsOneWidget);
      expect(find.text('Ghi thêm giá để xem biến động'), findsOneWidget);
    });

    testWidgets('no price and no link: only "Thêm link Shopee"', (
      tester,
    ) async {
      await _pump(tester, _item(hasPrice: false), const []);

      expect(find.byKey(const ValueKey('price-history')), findsNothing);
      expect(find.byKey(const ValueKey('price-add-link')), findsOneWidget);
    });
  });
}
