import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/errors/app_exception.dart';
import 'package:prm393_lab03/models/budget_group.dart';
import 'package:prm393_lab03/models/buying_motive.dart';
import 'package:prm393_lab03/models/decision_rules.dart';
import 'package:prm393_lab03/models/item_suggestion.dart';
import 'package:prm393_lab03/models/owned_item.dart';
import 'package:prm393_lab03/models/price_insights.dart';
import 'package:prm393_lab03/models/price_snapshot.dart';
import 'package:prm393_lab03/models/purchase_item.dart';
import 'package:prm393_lab03/models/sale_plan.dart';
import 'package:prm393_lab03/models/spending_insight.dart';
import 'package:prm393_lab03/models/wishlist_item.dart';
import 'package:prm393_lab03/models/wishlist_status.dart';
import 'package:prm393_lab03/screens/compare_items_screen.dart';
import 'package:prm393_lab03/screens/shopping_profile_screen.dart';
import 'package:prm393_lab03/services/ai_decision_service.dart';
import 'package:prm393_lab03/services/ai_service.dart';
import 'package:prm393_lab03/services/ai_suggestion_service.dart';
import 'package:prm393_lab03/services/preferences_service.dart';
import 'package:prm393_lab03/services/purchase_service.dart';
import 'package:prm393_lab03/services/remote_config_service.dart';
import 'package:prm393_lab03/services/shopping_profile_service.dart';
import 'package:prm393_lab03/services/wishlist_service.dart';
import 'package:prm393_lab03/viewmodels/decision_support_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/item_suggestion_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/shopping_profile_viewmodel.dart';
import 'package:prm393_lab03/widgets/satisfaction_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/purchase_harness.dart';

final _now = DateTime(2026, 10, 31, 12);

Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _NoAi implements AiService {
  @override
  Future<String> generateJson({
    required String systemInstruction,
    required String prompt,
    required List<String> cardIds,
  }) => throw UnimplementedError();

  @override
  Future<String> generateChoice({
    required String systemInstruction,
    required String prompt,
    required AiChoiceSchema schema,
  }) => throw UnimplementedError();

  @override
  Future<String> generateFields({
    required String systemInstruction,
    required String prompt,
    required List<String> fields,
  }) => throw UnimplementedError();
}

class _FakeRemoteConfig extends Fake implements FirebaseRemoteConfig {
  @override
  bool getBool(String key) => true;

  @override
  String getString(String key) => '';
}

OwnedItem _owned(
  String name, {
  String? group,
  List<String> tags = const [],
  String? note,
}) => OwnedItem(
  id: name,
  name: name,
  budgetGroupId: group,
  tags: tags,
  note: note,
  createdAt: DateTime(2026, 1, 1),
);

WishlistItem _wish(
  String id, {
  String title = 'Tai nghe Sony',
  String? group = 'tech',
  int? price = 420000,
  int priority = 3,
  WishlistStatus status = WishlistStatus.considering,
  bool confirmedDuplicate = false,
}) => WishlistItem(
  id: id,
  title: title,
  motive: BuyingMotive.want,
  budgetGroupId: group,
  latestPriceVnd: price,
  latestPriceAt: price == null ? null : _now,
  priority: priority,
  status: status,
  confirmedDuplicate: confirmedDuplicate,
  createdAt: _now.subtract(const Duration(days: 5)),
);

PurchaseItem _purchase(
  String id, {
  int daysAgo = 10,
  BuyingMotive motive = BuyingMotive.sale,
  int? satisfaction,
  bool skipped = false,
}) => PurchaseItem(
  id: id,
  title: 'Khoản $id',
  amountVnd: 100000,
  motive: motive,
  occurredAt: _now.subtract(Duration(days: daysAgo)),
  satisfaction: satisfaction,
  satisfactionSkipped: skipped,
);

PriceSnapshot _price(int amount, int daysAgo) => PriceSnapshot(
  id: '$amount-$daysAgo',
  amountVnd: amount,
  observedAt: _now.subtract(Duration(days: daysAgo)),
);

void main() {
  group('A-12 Hồ sơ mua sắm', () {
    test('an owned item matches by group or by tag (spec 7.2)', () {
      final airpods = _owned('AirPods', tags: ['tai nghe', 'hệ Apple']);
      expect(airpods.matches(title: 'Tai nghe Sony WH-1000'), isTrue);
      expect(airpods.matches(title: 'Ốp lưng iPhone'), isFalse);
      expect(
        _owned(
          'Laptop',
          group: 'tech',
        ).matches(title: 'Bàn phím', budgetGroupId: 'tech'),
        isTrue,
      );
      expect(OwnedItem.parseTags(' tai nghe, Tai Nghe ,, hệ Apple '), [
        'tai nghe',
        'hệ Apple',
      ]);
    });

    test(
      'view model saves, lists and deletes owned items, and saves style tags',
      () async {
        final db = FakeFirebaseFirestore();
        final vm = ShoppingProfileViewModel(
          service: FirestoreShoppingProfileService(db),
        )..updateUid('u1');
        addTearDown(vm.dispose);
        await _settle();

        expect(
          await vm.saveOwnedItem(
            name: 'AirPods',
            budgetGroupId: 'tech',
            tagsText: 'tai nghe',
            note: 'dùng 2 năm',
          ),
          isTrue,
        );
        expect(
          await vm.saveTags(
            stylesText: 'tối giản',
            brandsText: 'Apple, Uniqlo',
          ),
          isTrue,
        );
        await _settle();
        expect(vm.ownedItems.single.label, 'AirPods (dùng 2 năm)');
        expect(vm.tags.brands, ['Apple', 'Uniqlo']);
        expect(vm.matchesFor(title: 'Tai nghe JBL').single.name, 'AirPods');

        expect(await vm.saveOwnedItem(name: '  ', tagsText: ''), isFalse);
        expect(vm.actionError, contains('1 đến 60'));

        expect(await vm.deleteOwnedItem(vm.ownedItems.single), isTrue);
        await _settle();
        expect(vm.ownedItems, isEmpty);
      },
    );

    test('Decision Card S5 and the "trùng" branch of label 5', () {
      DecisionAssessment assess(WishlistItem item, List<OwnedItem> owned) =>
          DecisionRules.assess(
            DecisionInput(item: item, now: _now, ownedMatches: owned),
          );
      final one = assess(_wish('a'), [_owned('AirPods', note: 'dùng 2 năm')]);
      expect(
        one.signals,
        contains(
          'Bạn đã ghi có AirPods (dùng 2 năm). Bạn muốn thay hay mua thêm?',
        ),
      );
      expect(one.toPromptData()['doDangCo'], ['AirPods (dùng 2 năm)']);
      final two = assess(_wish('a'), [
        _owned('AirPods'),
        _owned('Galaxy Buds'),
      ]);
      expect(
        two.signals,
        contains(
          'Bạn đã ghi có 2 đồ đang dùng cùng nhóm hoặc cùng thẻ: AirPods, Galaxy Buds.',
        ),
      );

      final confirmed = assess(_wish('a', confirmedDuplicate: true), const []);
      expect(confirmed.label, DecisionLabel.considerSkipping);
    });

    test('owned items are duplicate candidates too (AI feature 4)', () async {
      SharedPreferences.setMockInitialValues({});
      final vm =
          ItemSuggestionViewModel(
            aiSuggestionService: AiSuggestionService(generator: _NoAi()),
            remoteConfigService: RemoteConfigService(
              remoteConfig: _FakeRemoteConfig(),
            ),
            preferencesService: PreferencesService(),
            platformSupportsAi: () => false,
            now: () => _now,
          )..updateSources(
            purchases: const [],
            wishlistItems: const [],
            ownedItems: [_owned('Tai nghe AirPods', group: 'tech')],
          );
      final matches = await vm.findDuplicates('Tai nghe Sony');
      expect(matches.single.candidate.source, DuplicateSource.owned);
    });
  });

  group('A-14 Lịch sử giá', () {
    test('freshness: ≤ 3 days "Mới", 4–7 days with date, older "Cũ"', () {
      expect(PriceInsights.freshnessLabel(_price(1, 3), _now), 'Mới');
      expect(
        PriceInsights.freshnessLabel(_price(1, 5), _now),
        'Ghi ngày 26/10/2026',
      );
      expect(
        PriceInsights.freshnessLabel(_price(1, 9), _now),
        'Cũ · 22/10/2026',
      );
    });

    test('compares with the saved price only when the latest is fresh', () {
      final cheaper = PriceInsights([
        _price(500000, 20),
        _price(420000, 1),
      ], now: _now);
      expect(cheaper.saved?.amountVnd, 500000);
      expect(cheaper.changeSinceSavedPercent, -16);
      expect(cheaper.notes, ['Thấp hơn lúc lưu 16%.']);

      final dearer = PriceInsights([
        _price(400000, 20),
        _price(460000, 2),
      ], now: _now);
      expect(dearer.notes, ['Giá đang cao hơn lúc lưu 15%.']);

      final stale = PriceInsights([
        _price(500000, 30),
        _price(420000, 10),
      ], now: _now);
      expect(stale.changeSinceSavedPercent, isNull);
      expect(stale.notes, [
        'Giá mới nhất không còn mới nên chưa so với lúc lưu.',
      ]);
    });

    test('"Thấp nhất đã ghi" needs three records', () {
      final two = PriceInsights([
        _price(500000, 20),
        _price(450000, 1),
      ], now: _now);
      expect(two.lowest, isNull);
      final three = PriceInsights([
        _price(500000, 20),
        _price(390000, 10),
        _price(450000, 1),
      ], now: _now);
      expect(three.lowest?.amountVnd, 390000);
      expect(three.notes.last, 'Thấp nhất đã ghi: 390.000 ₫ (21/10/2026).');
    });

    test(
      'history is read newest first and feeds S3 of the Decision Card',
      () async {
        SharedPreferences.setMockInitialValues({});
        final h = PurchaseHarness();
        addTearDown(h.dispose);
        final service = FirestoreWishlistService(h.db);
        final item = _wish('w1', price: 420000);
        await h.db
            .doc('users/${PurchaseHarness.uid}/wishlistItems/w1')
            .set(item.toMap());
        for (final p in [_price(500000, 20), _price(420000, 0)]) {
          await h.db
              .collection(
                'users/${PurchaseHarness.uid}/wishlistItems/w1/priceSnapshots',
              )
              .add(p.toMap());
        }
        final history = await service.priceHistory(PurchaseHarness.uid, 'w1');
        expect(history.map((p) => p.amountVnd), [420000, 500000]);

        final vm = DecisionSupportViewModel(
          budgetService: h.budgetService,
          wishlistService: service,
          aiDecisionService: AiDecisionService(generator: _NoAi()),
          remoteConfigService: RemoteConfigService(
            remoteConfig: _FakeRemoteConfig(),
          ),
          preferencesService: PreferencesService(),
          platformSupportsAi: () => false,
          now: () => _now,
        )..updateUid(PurchaseHarness.uid);
        addTearDown(vm.dispose);
        await vm.loadPriceHistory(item);
        expect(vm.priceInsightsFor(item)?.history, hasLength(2));
        expect(vm.assess(item).priceChangePercent, -16);
      },
    );
  });

  group('A-15 So sánh món cùng nhóm', () {
    test('same-group items still being considered, the opened item first', () {
      final vm = DecisionSupportViewModel(
        budgetService: PurchaseHarness().budgetService,
        wishlistService: FirestoreWishlistService(FakeFirebaseFirestore()),
        aiDecisionService: AiDecisionService(generator: _NoAi()),
        remoteConfigService: RemoteConfigService(
          remoteConfig: _FakeRemoteConfig(),
        ),
        preferencesService: PreferencesService(),
        now: () => _now,
      );
      addTearDown(vm.dispose);
      final opened = _wish('b', priority: 2);
      vm.updateSources(
        purchases: const [],
        wishlistItems: [
          _wish('a', priority: 5),
          opened,
          _wish('c', group: 'fashion'),
          _wish('d', status: WishlistStatus.skipped),
        ],
        groups: defaultBudgetGroups,
      );
      expect(vm.sameGroupItems(opened).map((i) => i.id), ['b', 'a']);
    });

    testWidgets('the table shows price, motive, days saved and priority', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final vm = DecisionSupportViewModel(
        budgetService: PurchaseHarness().budgetService,
        wishlistService: FirestoreWishlistService(FakeFirebaseFirestore()),
        aiDecisionService: AiDecisionService(generator: _NoAi()),
        remoteConfigService: RemoteConfigService(
          remoteConfig: _FakeRemoteConfig(),
        ),
        preferencesService: PreferencesService(),
        now: () => _now,
      );
      addTearDown(vm.dispose);
      final opened = _wish('a', title: 'Tai nghe Sony', priority: 4);
      vm.updateSources(
        purchases: const [],
        wishlistItems: [
          opened,
          _wish('b', title: 'Loa JBL', price: null, priority: 2),
        ],
        groups: defaultBudgetGroups,
      );
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: MaterialApp(home: CompareItemsScreen(item: opened)),
        ),
      );
      expect(find.text('Loa JBL'), findsOneWidget);
      expect(find.text('Chưa có giá'), findsOneWidget);
      expect(find.text('420.000 ₫'), findsOneWidget);
      expect(find.text('★★★★☆'), findsOneWidget);
      expect(find.text('5 ngày'), findsNWidgets(2));
      expect(find.textContaining('Công nghệ'), findsOneWidget);
    });
  });

  group('A-16 Hỏi mức hài lòng sau 7 ngày', () {
    test(
      'asked from day 7 to day 30, once answered or skipped never again',
      () {
        expect(_purchase('a', daysAgo: 6).isSatisfactionDue(_now), isFalse);
        expect(_purchase('a', daysAgo: 7).isSatisfactionDue(_now), isTrue);
        expect(_purchase('a', daysAgo: 31).isSatisfactionDue(_now), isFalse);
        expect(
          _purchase('a', satisfaction: 4).isSatisfactionDue(_now),
          isFalse,
        );
        expect(_purchase('a', skipped: true).isSatisfactionDue(_now), isFalse);
      },
    );

    test('stars are saved on the purchase; "Bỏ qua" stops asking', () async {
      final db = FakeFirebaseFirestore();
      final service = FirestorePurchaseService(db);
      await db.doc('users/u1/purchases/p1').set(_purchase('p1').toMap());
      await service.setSatisfaction('u1', 'p1', 4);
      var data = (await db.doc('users/u1/purchases/p1').get()).data()!;
      expect((data['satisfaction'], data['satisfactionSkipped']), (4, false));

      await service.setSatisfaction('u1', 'p1', null);
      data = (await db.doc('users/u1/purchases/p1').get()).data()!;
      expect((data['satisfaction'], data['satisfactionSkipped']), (null, true));

      expect(
        () => service.setSatisfaction('u1', 'p1', 6),
        throwsA(isA<AppException>()),
      );
    });

    test(
      'Góc nhìn: average stars by motive, only motives with ≥ 2 ratings',
      () {
        final stats = MonthlySpendingStats.compute(
          month: DateTime(2026, 10),
          purchases: [
            _purchase('a', satisfaction: 4),
            _purchase('b', satisfaction: 5),
            _purchase('c', motive: BuyingMotive.need, satisfaction: 2),
          ],
          wishlistItems: const [],
        );
        expect(stats.satisfaction.single.motive, BuyingMotive.sale);
        expect(stats.satisfaction.single.averageText, '4,5');
        expect(
          stats.applicableKinds,
          contains(InsightKind.satisfactionByMotive),
        );
        expect(stats.allowedNumbers, containsAll([45, 2, 5]));
        expect((stats.toPromptData()['hailongTheoDongCo'] as List).single, {
          'dongCo': 'Khuyến mãi',
          'trungBinhText': '4,5/5',
          'soKhoanDaCham': 2,
        });
      },
    );

    test('sale plans use the stars as hopGu once a motive has 2 ratings', () {
      final fit = SalePlanner.fitByMotive([
        _purchase('a', satisfaction: 5),
        _purchase('b', satisfaction: 3),
        _purchase('c', motive: BuyingMotive.need, satisfaction: 1),
      ]);
      expect(fit, {BuyingMotive.sale: 0.75});
    });

    testWidgets('dialog: pick 4 stars, save, then the thank-you message', (
      tester,
    ) async {
      final h = PurchaseHarness();
      addTearDown(h.dispose);
      final purchase = _purchase('p1');
      await h.initialize(purchase: purchase);
      await tester.pumpWidget(
        h.app(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => SatisfactionDialog.ask(context, purchase),
                child: const Text('ask'),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('ask'));
      await tester.pumpAndSettle();
      expect(find.text('Bạn thấy thế nào về khoản mua này?'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('satisfaction-4')));
      await tester.pump();
      await tester.tap(find.text('Lưu'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Cảm ơn bạn! Góc nhìn sẽ dùng câu trả lời này.'),
        findsOneWidget,
      );
      final data = (await tester.runAsync(
        () => h.db.doc('users/${PurchaseHarness.uid}/purchases/p1').get(),
      ))!.data()!;
      expect(data['satisfaction'], 4);
    });
  });

  testWidgets('Hồ sơ mua sắm: empty state, add an owned item, see it listed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = PurchaseHarness();
    addTearDown(h.dispose);
    await h.initialize();
    final vm = ShoppingProfileViewModel(
      service: FirestoreShoppingProfileService(h.db),
    )..updateUid(PurchaseHarness.uid);
    addTearDown(vm.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: vm,
        child: h.app(const ShoppingProfileScreen()),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chưa ghi đồ đang dùng'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('owned-add')));
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(fields.at(0), 'AirPods');
    await tester.enterText(fields.at(1), 'tai nghe, hệ Apple');
    await tester.enterText(fields.at(2), 'dùng 2 năm');
    await tester.tap(find.byKey(const ValueKey('owned-save')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    expect(find.text('AirPods (dùng 2 năm)'), findsOneWidget);
    expect(find.textContaining('tai nghe, hệ Apple'), findsOneWidget);
  });
}
