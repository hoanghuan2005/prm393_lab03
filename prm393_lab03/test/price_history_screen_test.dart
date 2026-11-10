import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/app/routes.dart';
import 'package:prm393_lab03/models/price_history.dart';
import 'package:prm393_lab03/models/price_insights.dart';
import 'package:prm393_lab03/models/price_snapshot.dart';
import 'package:prm393_lab03/models/wishlist_item.dart';
import 'package:prm393_lab03/screens/dev/price_chart_gallery.dart';
import 'package:prm393_lab03/screens/price_history_screen.dart';
import 'package:prm393_lab03/services/analytics_service.dart';
import 'package:prm393_lab03/services/crashlytics_service.dart';
import 'package:prm393_lab03/services/demo_price_history_service.dart';
import 'package:prm393_lab03/services/price_history_service.dart';
import 'package:prm393_lab03/services/user_service.dart';
import 'package:prm393_lab03/viewmodels/price_history_demo_viewmodel.dart';
import 'package:prm393_lab03/widgets/price_history_chart.dart';
import 'package:prm393_lab03/widgets/price_history_demo_section.dart';
import 'package:prm393_lab03/widgets/price_history_entry_card.dart';
import 'package:provider/provider.dart';

import 'support/linked_auth_fakes.dart';
import 'support/test_theme.dart';

class _Analytics extends Fake implements AppAnalyticsService {
  final views = <(String, int, bool)>[];

  @override
  Future<void> logViewPriceHistory({
    required String mode,
    required int rangeDays,
    required bool isDemo,
  }) async => views.add((mode, rangeDays, isDemo));
}

const _keys = InMemoryPriceHistoryService.keys;

/// Opens [route] with [args] from a button, under the app's services
Future<_Analytics> _open(
  WidgetTester tester,
  PriceHistoryService service, {
  Widget? home,
  String route = AppRoutes.priceHistory,
  Object? args,
}) async {
  tester.view.physicalSize = const Size(412, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final analytics = _Analytics();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<PriceHistoryService>.value(value: service),
        Provider<AppAnalyticsService>.value(value: analytics),
        Provider<CrashlyticsService>.value(value: CountingCrashlytics()),
      ],
      child: MaterialApp(
        theme: testAppTheme,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home:
            home ??
            Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, route, arguments: args),
                child: const Text('Mở'),
              ),
            ),
      ),
    ),
  );
  if (home == null) {
    await tester.tap(find.text('Mở'));
  }
  await tester.pumpAndSettle();
  return analytics;
}

/// Neutral wording only
void _expectNeutral() {
  for (final word in ['Nên mua', 'nên mua', 'nên chọn', 'rẻ nhất', 'Rẻ nhất']) {
    expect(find.textContaining(word), findsNothing, reason: word);
  }
}

void main() {
  testWidgets('product → switch to the whole group; analytics per result', (
    tester,
  ) async {
    final service = InMemoryPriceHistoryService.sample(DateTime.now());
    final analytics = await _open(
      tester,
      service,
      args: PriceHistoryArgs(productKey: _keys.first),
    );

    expect(find.text('Giá tham khảo'), findsOneWidget);
    expect(find.text('Tai nghe Sonora Air 2'), findsOneWidget);
    expect(find.byType(PriceHistoryChart), findsOneWidget);
    expect(find.text('Chỉ món này'), findsOneWidget);
    expect(find.text('Giá gần nhất theo shop'), findsNothing);
    expect(find.text('Dữ liệu mẫu'), findsOneWidget);
    expect(analytics.views, [('product', 30, true)]);

    await tester.tap(find.text('Cả nhóm'));
    await tester.pumpAndSettle();

    expect(find.text('Giá gần nhất theo shop'), findsOneWidget);
    for (final key in _keys) {
      expect(find.byKey(ValueKey('shop-latest-$key')), findsOneWidget);
    }
    expect(find.text('Nhà Tai Nghe Mây'), findsWidgets);
    expect(find.textContaining('★ 4,9'), findsWidgets);
    expect(analytics.views.last, ('group', 30, true));

    await tester.tap(find.text('90N'));
    await tester.pumpAndSettle();
    expect(analytics.views.last, ('group', 90, true));
    _expectNeutral();

    await tester.tap(find.text('Chỉ món này'));
    await tester.pumpAndSettle();
    expect(find.text('Giá gần nhất theo shop'), findsNothing);
  });

  testWidgets('fits 320 dp with text at 150%', (tester) async {
    tester.view.physicalSize = const Size(320, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<PriceHistoryService>.value(
            value: InMemoryPriceHistoryService.sample(DateTime.now()),
          ),
          Provider<AppAnalyticsService>.value(value: _Analytics()),
          Provider<CrashlyticsService>.value(value: CountingCrashlytics()),
        ],
        child: MaterialApp(
          theme: testAppTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: PriceHistoryScreen.withViewModel(productKey: _keys.first),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cả nhóm'));
    await tester.pumpAndSettle();

    expect(find.text('Giá gần nhất theo shop'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opened on a group: no product switch', (tester) async {
    await _open(
      tester,
      InMemoryPriceHistoryService.sample(DateTime.now()),
      args: const PriceHistoryArgs(
        groupId: InMemoryPriceHistoryService.groupId,
      ),
    );

    expect(find.text('Giá gần nhất theo shop'), findsOneWidget);
    expect(find.byKey(const ValueKey('price-scope')), findsNothing);
    _expectNeutral();
  });

  testWidgets('not enough data: message and a way to see 90 days', (
    tester,
  ) async {
    final service = InMemoryPriceHistoryService(
      products: const {},
      reports: const {},
    );
    await _open(tester, service, args: const PriceHistoryArgs(productKey: 'x'));

    expect(find.text('Chưa đủ dữ liệu'), findsOneWidget);
    expect(find.text('Xem 90 ngày'), findsOneWidget);
  });

  group('Chi tiết món card', () {
    Widget card(String key) => Scaffold(
      body: SingleChildScrollView(
        child: PriceHistoryEntryCard(productKey: key),
      ),
    );

    testWidgets('with data: lowest of 30 days, days with data; opens chart', (
      tester,
    ) async {
      final analytics = await _open(
        tester,
        InMemoryPriceHistoryService.sample(DateTime.now()),
        home: card(_keys.first),
      );

      expect(find.text('Giá tham khảo'), findsOneWidget);
      expect(find.textContaining('Thấp nhất 30 ngày: '), findsOneWidget);
      expect(
        find.textContaining(RegExp(r'^Có dữ liệu \d+/30 ngày$')),
        findsOneWidget,
      );
      expect(analytics.views, isEmpty, reason: 'the card is not a chart view');

      await tester.tap(find.byKey(const ValueKey('price-history-entry')));
      await tester.pumpAndSettle();
      expect(find.byType(PriceHistoryScreen), findsOneWidget);
      expect(analytics.views, [('product', 30, true)]);
    });

    testWidgets('without data: nothing', (tester) async {
      await _open(
        tester,
        InMemoryPriceHistoryService(products: const {}, reports: const {}),
        home: card('shopee:1:2'),
      );
      expect(find.byKey(const ValueKey('price-history-entry')), findsNothing);
      expect(find.text('Giá tham khảo'), findsNothing);
    });

    testWidgets('without the service (old screens / tests): nothing', (
      tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: card('shopee:1:2')));
      await tester.pump();
      expect(find.text('Giá tham khảo'), findsNothing);
    });
  });

  group('"Giá lúc bạn lưu" from Chi tiết món (G5c)', () {
    final savedAt = DateTime.utc(2026, 10, 1, 3);
    WishlistItem item({String? variant = 'Đen'}) => WishlistItem(
      id: 'i',
      title: 'Tai nghe',
      createdAt: savedAt,
      productKey: _keys.first,
      variantLabel: variant,
      latestPriceVnd: 600000,
    );
    PriceInsights insights(List<PriceSnapshot> snapshots) =>
        PriceInsights(snapshots, now: DateTime.utc(2026, 11, 12));
    PriceSnapshot snap(
      int vnd, {
      int days = 0,
      PriceType type = PriceType.single,
      PriceSource source = PriceSource.manual,
      String? variant = 'Đen',
      int? max,
    }) => PriceSnapshot(
      id: 's$vnd-$days',
      amountVnd: vnd,
      observedAt: savedAt.add(Duration(days: days)),
      priceType: type,
      source: source,
      variantLabel: variant,
      minVnd: max == null ? null : vnd,
      maxVnd: max,
    );

    test('the first list price, for the variant the item has', () {
      final saved = savedPriceOf(
        item(),
        insights([snap(650000), snap(600000, days: 5)]),
      );
      expect((saved!.vnd, saved.savedAt), (650000, savedAt));
    });

    test('left out when it does not compare', () {
      expect(savedPriceOf(item(), null), isNull);
      expect(
        savedPriceOf(item(variant: 'Trắng'), insights([snap(650000)])),
        isNull,
        reason: 'another variant',
      );
      expect(
        savedPriceOf(
          item(),
          insights([snap(600000, type: PriceType.range, max: 700000)]),
        ),
        isNull,
        reason: 'a range',
      );
      expect(
        savedPriceOf(
          item(),
          insights([snap(580000, type: PriceType.afterVoucher)]),
        ),
        isNull,
        reason: 'after voucher only',
      );
      expect(
        savedPriceOf(
          item(),
          insights([snap(600000, source: PriceSource.community)]),
        ),
        isNull,
        reason: 'a price from other people',
      );
    });

    testWidgets('the route passes it to the chart', (tester) async {
      await _open(
        tester,
        InMemoryPriceHistoryService.sample(DateTime.now()),
        args: PriceHistoryArgs(
          productKey: _keys.first,
          savedPrice: SavedPrice(
            vnd: 640000,
            savedAt: DateTime.now().subtract(const Duration(days: 40)),
          ),
        ),
      );

      final chart = tester.widget<PriceHistoryChart>(
        find.byType(PriceHistoryChart),
      );
      expect(chart.savedPrice?.vnd, 640000);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('price-milestone-saved')),
          matching: find.text('640.000 ₫'),
        ),
        findsOneWidget,
      );
      _expectNeutral();
    });
  });

  testWidgets('Firebase Demo Area (admin): sample groups open the chart', (
    tester,
  ) async {
    final users = _Users();
    final demo = _Demo()
      ..groups = const [
        ProductGroup(
          id: InMemoryPriceHistoryService.groupId,
          name: 'Tai nghe Sonora Air 2',
          productKeys: ['a', 'b', 'c'],
          isDemo: true,
        ),
      ];
    final vm = PriceHistoryDemoViewModel(demoService: demo, userService: users)
      ..updateUid('ada');
    addTearDown(vm.dispose);
    addTearDown(users.roles.close);
    await _open(
      tester,
      InMemoryPriceHistoryService.sample(DateTime.now()),
      home: ChangeNotifierProvider.value(
        value: vm,
        child: const Scaffold(
          body: SingleChildScrollView(child: PriceHistoryDemoSection()),
        ),
      ),
    );
    expect(find.text('Mở biểu đồ nhóm mẫu'), findsNothing);

    users.roles.add('admin');
    await tester.pumpAndSettle();
    expect(find.text('Tai nghe Sonora Air 2'), findsOneWidget);
    expect(find.text('3 shop'), findsOneWidget);

    await tester.tap(find.text('Tai nghe Sonora Air 2'));
    await tester.pumpAndSettle();
    expect(find.byType(PriceHistoryScreen), findsOneWidget);
    expect(find.text('Giá gần nhất theo shop'), findsOneWidget);
  });
}

class _Users extends Fake implements UserService {
  final roles = StreamController<String>.broadcast(sync: true);

  @override
  Stream<String> watchRole(String uid) => roles.stream;
}

class _Demo extends Fake implements DemoPriceHistoryService {
  List<ProductGroup> groups = const [];

  @override
  Future<List<ProductGroup>> demoGroups() async => groups;
}
