import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/app/routes.dart';
import 'package:prm393_lab03/models/available_budget.dart';
import 'package:prm393_lab03/models/budget_group.dart';
import 'package:prm393_lab03/models/buying_motive.dart';
import 'package:prm393_lab03/models/decision_rules.dart';
import 'package:prm393_lab03/models/sale_event.dart';
import 'package:prm393_lab03/models/sale_plan.dart';
import 'package:prm393_lab03/models/wishlist_item.dart';
import 'package:prm393_lab03/screens/item_detail_screen.dart';
import 'package:prm393_lab03/screens/sale_screens.dart';
import 'package:prm393_lab03/services/ai_decision_service.dart';
import 'package:prm393_lab03/services/ai_service.dart';
import 'package:prm393_lab03/services/preferences_service.dart';
import 'package:prm393_lab03/services/remote_config_service.dart';
import 'package:prm393_lab03/services/wishlist_service.dart';
import 'package:prm393_lab03/viewmodels/decision_support_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/purchase_harness.dart';

final _now = DateTime(2026, 10, 31, 12);

/// Spec 7.1 example: limit 1.500.000, spent 400.000, 10.000/day × 14 days → 864.000
const _fashionExample = AvailableBudget(
  limit: 1500000,
  spent: 400000,
  windowDays: 30,
  dailyAverage: 10000,
  daysLeft: 14,
  hasEnoughHistory: true,
);

WishlistItem _item({
  int? price = 420000,
  int priceAgeDays = 0,
  int savedDaysAgo = 10,
  BuyingMotive motive = BuyingMotive.want,
  DateTime? cooldownUntil,
  int priority = 3,
  String? group = 'tech',
}) => WishlistItem(
  id: 'i1',
  title: 'Tai nghe Sony',
  motive: motive,
  priority: priority,
  budgetGroupId: group,
  latestPriceVnd: price,
  latestPriceAt: price == null
      ? null
      : _now.subtract(Duration(days: priceAgeDays)),
  cooldownUntil: cooldownUntil,
  createdAt: _now.subtract(Duration(days: savedDaysAgo)),
);

DecisionAssessment _assess(
  WishlistItem item, {
  AvailableBudget? available,
  int? saved,
  SaleEvent? sale,
  int sameGroup = 0,
}) => DecisionRules.assess(
  DecisionInput(
    item: item,
    now: _now,
    groupName: 'Công nghệ',
    available: available,
    savedPriceVnd: saved,
    sameGroupCount: sameGroup,
    upcomingSale: sale,
  ),
);

final _sale1111 = SaleEvent(
  id: '2026-11-11',
  name: '11.11',
  date: DateTime(2026, 11, 11),
  type: SaleType.doubleDay,
  confirmed: true,
);

class _FakeAi implements AiService {
  String response = '{}';
  Object? error;
  int calls = 0;

  @override
  Future<String> generateFields({
    required String systemInstruction,
    required String prompt,
    required List<String> fields,
  }) async {
    calls++;
    if (error != null) throw error!;
    return response;
  }

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
}

class _FakeRemoteConfig extends Fake implements FirebaseRemoteConfig {
  @override
  bool getBool(String key) => true;

  @override
  String getString(String key) => '';
}

void main() {
  group('Rules Engine v1 (spec 7.4): first matching label wins', () {
    test(
      'spec example: 420.000 ₫ in 864.000 ₫ available is "Trong ngân sách"',
      () {
        final a = _assess(_item(), available: _fashionExample, sameGroup: 2);
        expect(_fashionExample.available, 864000);
        expect(a.label, DecisionLabel.withinBudget);
        expect(a.percentOfAvailable, 49);
        expect(a.signals, [
          'Chiếm khoảng 49% phần khả dụng của nhóm Công nghệ tháng này.',
          'Bạn đang cân nhắc thêm 2 món cùng nhóm.',
        ]);
      },
    );

    test('1 · no price, or a price older than 3 days: "Cần giá gần đây"', () {
      final none = _assess(_item(price: null), available: _fashionExample);
      expect(none.label, DecisionLabel.needsRecentPrice);
      expect(none.templateReason, contains('chưa có giá'));
      // S1–S3 are not computed without a recent price (spec 7.7)
      expect(none.percentOfAvailable, isNull);

      final old = _assess(_item(priceAgeDays: 5), available: _fashionExample);
      expect(old.label, DecisionLabel.needsRecentPrice);
      expect(old.templateReason, contains('26/10/2026'));
    });

    test('2 · cooling-off period: "Có thể chờ" (not for Nhu cầu)', () {
      final until = _now.add(const Duration(days: 2));
      final a = _assess(
        _item(cooldownUntil: until, savedDaysAgo: 1),
        available: _fashionExample,
      );
      expect(a.label, DecisionLabel.waitCooldown);
      expect(a.signals, contains('Bạn mới lưu 1 ngày.'));

      final need = _assess(
        _item(cooldownUntil: until, motive: BuyingMotive.need),
        available: _fashionExample,
      );
      expect(need.label, DecisionLabel.withinBudget);
    });

    test('3 · confirmed sale within 7 days: "Có thể chờ"', () {
      final a = _assess(_item(), available: _fashionExample, sale: _sale1111);
      expect(a.label, DecisionLabel.waitSale);
      expect(a.templateReason, 'Đợt 11.11 còn 11 ngày, có thể có giá tốt hơn.');
    });

    test('4 · price above the available amount: "Vượt phần khả dụng"', () {
      final a = _assess(_item(price: 1000000), available: _fashionExample);
      expect(a.label, DecisionLabel.overAvailable);
      expect(a.overBy, 136000);
      expect(
        a.signals,
        contains('Vượt phần khả dụng của nhóm Công nghệ khoảng 136.000 ₫.'),
      );
    });

    test('5 · saved over 60 days with priority ≤ 2: "Có thể cân nhắc bỏ"', () {
      final a = _assess(_item(savedDaysAgo: 61, priority: 2));
      expect(a.label, DecisionLabel.considerSkipping);
    });

    test('6 needs a price that did not rise since saving; otherwise 7', () {
      final cheaper = _assess(
        _item(),
        available: _fashionExample,
        saved: 500000,
      );
      expect(cheaper.label, DecisionLabel.withinBudget);
      expect(cheaper.signals, contains('Thấp hơn lúc lưu 16%.'));

      final dearer = _assess(
        _item(),
        available: _fashionExample,
        saved: 300000,
      );
      expect(dearer.label, DecisionLabel.notEnoughData);
      expect(dearer.signals, contains('Cao hơn lúc lưu 40%.'));
    });

    test('7 · without a budget: "Chưa đủ dữ liệu" and what is missing', () {
      final a = _assess(_item());
      expect(a.label, DecisionLabel.notEnoughData);
      expect(a.signals.last, 'Chưa đủ dữ liệu về hạn mức tháng của nhóm.');
      final noGroup = _assess(_item(group: null));
      expect(noGroup.signals.last, contains('nhóm ngân sách của món'));
    });

    test('no label ever says "nên mua" / "không nên mua"', () {
      for (final label in DecisionLabel.values) {
        expect(label.text.toLowerCase(), isNot(contains('nên')));
      }
    });
  });

  group('AI feature 2: one sentence for the label', () {
    final a = _assess(_item(), available: _fashionExample);

    test('a sentence with only computed numbers is accepted', () {
      final raw = jsonEncode({
        'reason': 'Tai nghe chiếm khoảng 49% phần khả dụng 864.000 ₫ của nhóm Công nghệ; bạn muốn so với đồ đang có không?',
      });
      expect(AiDecisionService.parseReason(raw, a), isNotNull);
    });

    test(
      'an invented number, judgmental wording or broken JSON is dropped',
      () {
        for (final reason in [
          'Giá sẽ giảm 30% vào thứ Hai.',
          'Bạn chắc chắn không nên mua món này.',
        ]) {
          expect(
            AiDecisionService.parseReason(jsonEncode({'reason': reason}), a),
            isNull,
          );
        }
        expect(AiDecisionService.parseReason('not json', a), isNull);
      },
    );
  });

  group('Lịch sale (spec 8.2)', () {
    test(
      'public pattern days are "dự kiến"; Remote Config entries replace them',
      () {
        final events = SaleCalendar.upcoming(
          configured: SaleCalendar.parse(
            RemoteConfigService.defaultSaleCalendar,
          ),
          now: _now,
        );
        final names = events.map((e) => e.name).toList();
        expect(names.take(4), [
          '11.11',
          'Sale giữa tháng 15.11',
          'Sale ngày lương 25.11',
          '12.12',
        ]);
        expect(events.first.confirmed, isTrue);
        expect(events[1].confirmed, isFalse);
        expect(
          events.where((e) => SaleEvent.dayId(e.date) == '2026-11-11'),
          hasLength(1),
        );
      },
    );

    test(
      'only a confirmed sale within 7 days counts for the Decision Card',
      () {
        final events = SaleCalendar.upcoming(
          configured: [_sale1111],
          now: _now,
        );
        expect(SaleCalendar.nextConfirmed(events, _now, withinDays: 7), isNull);
        final nov5 = DateTime(2026, 11, 5);
        expect(
          SaleCalendar.nextConfirmed(events, nov5, withinDays: 7)?.name,
          '11.11',
        );
      },
    );

    test('invalid Remote Config values are ignored', () {
      expect(SaleCalendar.parse('not json'), isEmpty);
      expect(
        SaleCalendar.parse(
          '[{"date":"nope","name":"x"},{"date":"2026-12-12","name":"12.12"}]',
        ).map((e) => e.name),
        ['12.12'],
      );
    });
  });

  group('Lập kế hoạch cho đợt sale (spec 7.5)', () {
    test('0/1 knapsack picks the best value that fits', () {
      expect(SalePlanner.knapsack([5, 4, 3], [10, 40, 30], 7), [1, 2]);
      expect(SalePlanner.knapsack([5], [10], 0), isEmpty);
    });

    WishlistItem priced(
      String id,
      int price,
      BuyingMotive motive,
      int priority, {
      String? group = 'tech',
    }) => WishlistItem(
      id: id,
      title: id,
      motive: motive,
      priority: priority,
      budgetGroupId: group,
      latestPriceVnd: price,
      createdAt: _now.subtract(const Duration(days: 10)),
    );

    test('three options per group; "Giữ lại nhiều hơn" uses at most half', () {
      final result = SalePlanner.plan(
        items: [
          priced('headphones', 600000, BuyingMotive.need, 5),
          priced('keyboard', 500000, BuyingMotive.want, 3),
          priced('speaker', 450000, BuyingMotive.emotion, 1),
          WishlistItem(id: 'no-price', title: 'no-price', createdAt: _now),
          priced('shirt', 200000, BuyingMotive.want, 3, group: 'fashion'),
          priced('no-group', 100000, BuyingMotive.want, 3, group: null),
        ],
        groups: defaultBudgetGroups,
        available: {'tech': 1000000},
        now: _now,
      );
      List<String> chosen(PlanOption o) => result.plans
          .firstWhere((p) => p.option == o)
          .groups
          .expand((g) => g.chosen.map((i) => i.id))
          .toList();

      expect(chosen(PlanOption.balanced), ['keyboard', 'speaker']);
      expect(chosen(PlanOption.needsFirst), ['headphones']);
      expect(chosen(PlanOption.keepMore), ['keyboard']);
      for (final plan in result.plans) {
        expect(plan.total, lessThanOrEqualTo(plan.available));
      }
      expect(result.excluded.map((i, r) => MapEntry(i.id, r)), {
        'no-price': PlanExclusion.noPrice,
        'shirt': PlanExclusion.noLimit,
        'no-group': PlanExclusion.noGroup,
      });
    });

    test('prices are rounded up to 1.000 ₫ before fitting', () {
      final result = SalePlanner.plan(
        items: [priced('a', 500001, BuyingMotive.need, 5)],
        groups: defaultBudgetGroups,
        available: {'tech': 500500},
        now: _now,
      );
      expect(result.plans.first.itemCount, 0);
    });
  });

  group('DecisionSupportViewModel', () {
    late PurchaseHarness h;
    late _FakeAi ai;
    late DecisionSupportViewModel vm;
    var aiOnPlatform = true;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      h = PurchaseHarness();
      ai = _FakeAi();
      aiOnPlatform = true;
      await h.budgetService.ensureDefaultGroups(PurchaseHarness.uid);
      await h.budgetService.setGroupLimits(PurchaseHarness.uid, '2026-10', {
        'tech': 1000000,
      });
      vm = DecisionSupportViewModel(
        budgetService: h.budgetService,
        wishlistService: FirestoreWishlistService(h.db),
        aiDecisionService: AiDecisionService(generator: ai),
        remoteConfigService: RemoteConfigService(
          remoteConfig: _FakeRemoteConfig(),
        ),
        preferencesService: PreferencesService(),
        platformSupportsAi: () => aiOnPlatform,
        now: () => _now,
      )..updateUid(PurchaseHarness.uid);
      vm.updateSources(
        purchases: const [],
        wishlistItems: [_item()],
        groups: defaultBudgetGroups,
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });

    tearDown(() {
      vm.dispose();
      h.dispose();
    });

    test('uses this month\'s limit even when another month is browsed', () {
      expect(vm.availableFor('tech')?.limit, 1000000);
      expect(vm.assess(_item()).label, DecisionLabel.withinBudget);
    });

    test(
      'AI wording when allowed; template when off, failing or not acceptable',
      () async {
        final a = vm.assess(_item());
        ai.response = jsonEncode({
          'reason': 'Món chiếm khoảng 47% phần khả dụng của nhóm Công nghệ.',
        });
        final fromAi = await vm.reasonFor(a);
        expect(
          (fromAi.text, fromAi.fromAi),
          ('Món chiếm khoảng 47% phần khả dụng của nhóm Công nghệ.', true),
        );

        ai.response = jsonEncode({'reason': 'Giá sẽ giảm 30% tuần sau.'});
        final rejected = await vm.reasonFor(vm.assess(_item(price: 430000)));
        expect(rejected.fromAi, isFalse);

        aiOnPlatform = false;
        final off = await vm.reasonFor(vm.assess(_item(price: 440000)));
        expect(
          (off.text, off.fromAi),
          (vm.assess(_item(price: 440000)).templateReason, false),
        );
      },
    );
  });

  testWidgets('Lịch sale → Danh sách cho 11.11 → Lập kế hoạch', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(412, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = PurchaseHarness();
    addTearDown(h.dispose);
    await h.initialize(item: _item());
    await h.budgetService.setGroupLimits(PurchaseHarness.uid, '2026-10', {
      'tech': 1000000,
    });
    final vm = DecisionSupportViewModel(
      budgetService: h.budgetService,
      wishlistService: FirestoreWishlistService(h.db),
      aiDecisionService: AiDecisionService(generator: _FakeAi()),
      remoteConfigService: RemoteConfigService(
        remoteConfig: _FakeRemoteConfig(),
      ),
      preferencesService: PreferencesService(),
      platformSupportsAi: () => false,
      now: () => _now,
    )..updateUid(PurchaseHarness.uid);
    addTearDown(vm.dispose);
    vm.updateSources(
      purchases: const [],
      wishlistItems: [_item()],
      groups: defaultBudgetGroups,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: vm,
        child: h.app(const SaleCalendarScreen()),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    expect(find.text('11.11'), findsOneWidget);
    expect(find.text('Đã xác nhận'), findsOneWidget);
    expect(find.text('Dự kiến'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('sale-2026-11-11')));
    await tester.pumpAndSettle();
    expect(find.text('Danh sách cho 11.11'), findsOneWidget);
    expect(find.text('Tai nghe Sony'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sale-plan-button')));
    await tester.pumpAndSettle();
    expect(find.text('Kế hoạch cho 11.11'), findsOneWidget);
    expect(find.text('Cân bằng'), findsOneWidget);
    expect(find.text('Giữ lại nhiều hơn'), findsOneWidget);
    // AI off on this platform: every plan keeps its template explanation
    await tester.pumpAndSettle();
    expect(find.text('Câu mẫu'), findsNWidgets(3));
    expect(
      find.text(
        'Gồm 1 món, tổng 420.000 ₫, dùng khoảng 47% phần khả dụng; còn lại 480.000 ₫.',
      ),
      findsNWidgets(3),
    );
    expect(find.text('• Tai nghe Sony · 420.000 ₫'), findsNWidgets(3));
    expect(AppRoutes.salePlan, '/sales/plan');
  });

  testWidgets(
    'Chi tiết món shows the label, the template reason and the signals',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(412, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final h = PurchaseHarness();
      addTearDown(h.dispose);
      final item = _item();
      await h.initialize(item: item);
      await h.budgetService.setGroupLimits(PurchaseHarness.uid, '2026-10', {
        'tech': 1000000,
      });
      final vm = DecisionSupportViewModel(
        budgetService: h.budgetService,
        wishlistService: FirestoreWishlistService(h.db),
        aiDecisionService: AiDecisionService(generator: _FakeAi()),
        remoteConfigService: RemoteConfigService(
          remoteConfig: _FakeRemoteConfig(),
        ),
        preferencesService: PreferencesService(),
        platformSupportsAi: () => false,
        now: () => _now,
      )..updateUid(PurchaseHarness.uid);
      addTearDown(vm.dispose);
      vm.updateSources(
        purchases: const [],
        wishlistItems: [item],
        groups: defaultBudgetGroups,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: h.app(ItemDetailScreen(item: item)),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();

      // No spending history yet: buffer 0, so 1.000.000 × 90% = 900.000 available
      expect(find.text('Trong ngân sách'), findsOneWidget);
      expect(
        find.text(
          'Món chiếm khoảng 47% phần khả dụng của nhóm Công nghệ tháng này.',
        ),
        findsOneWidget,
      );
      expect(find.text('Câu mẫu'), findsOneWidget);
      // Mua · Chờ · Bỏ qua are still all there
      for (final label in ['Mua', 'Chờ', 'Bỏ qua']) {
        expect(find.text(label), findsOneWidget);
      }
    },
  );

  group('AI feature 5: explaining the sale plans', () {
    final plans = SalePlanner.plan(
      items: [
        WishlistItem(
          id: 'k',
          title: 'Bàn phím',
          motive: BuyingMotive.want,
          budgetGroupId: 'tech',
          latestPriceVnd: 500000,
          createdAt: _now.subtract(const Duration(days: 10)),
        ),
      ],
      groups: defaultBudgetGroups,
      available: {'tech': 1000000},
      now: _now,
    );
    final balanced = plans.plans.first;

    test('the template only uses numbers code computed', () {
      expect(
        balanced.templateExplanation,
        'Gồm 1 món, tổng 500.000 ₫, dùng khoảng 50% phần khả dụng; còn lại 500.000 ₫.',
      );
      expect(balanced.allowedNumbers, containsAll([1, 500000, 1000000, 50]));
    });

    test('each plan is checked on its own; a bad one keeps its template', () {
      final raw = jsonEncode({
        'balanced': 'Phương án xếp Bàn phím 500.000 ₫ vào phần khả dụng 1.000.000 ₫, còn lại 500.000 ₫.',
        'needsFirst': 'Giá sẽ giảm 20% nên chờ thêm.',
        'keepMore': 'Bạn chắc chắn nên mua ngay.',
      });
      final parsed = AiDecisionService.parsePlans(raw, plans.plans);
      expect(parsed.keys, [PlanOption.balanced]);
      expect(AiDecisionService.parsePlans('not json', plans.plans), isEmpty);
    });

    test(
      'view model: AI where accepted, template elsewhere or when AI fails',
      () async {
        SharedPreferences.setMockInitialValues({});
        final h = PurchaseHarness();
        final ai = _FakeAi()
          ..response = jsonEncode({
            'balanced': 'Phương án xếp Bàn phím 500.000 ₫, còn lại 500.000 ₫ trong phần khả dụng.',
          });
        final vm = DecisionSupportViewModel(
          budgetService: h.budgetService,
          wishlistService: FirestoreWishlistService(h.db),
          aiDecisionService: AiDecisionService(generator: ai),
          remoteConfigService: RemoteConfigService(
            remoteConfig: _FakeRemoteConfig(),
          ),
          preferencesService: PreferencesService(),
          platformSupportsAi: () => true,
          now: () => _now,
        );
        addTearDown(vm.dispose);
        addTearDown(h.dispose);

        final explained = await vm.explainPlans(plans);
        expect(explained[PlanOption.balanced]?.fromAi, isTrue);
        expect(explained[PlanOption.needsFirst]?.fromAi, isFalse);
        expect(
          explained[PlanOption.keepMore]?.text,
          plans.plans.last.templateExplanation,
        );
        expect(ai.calls, 1, reason: 'one request for all three plans');

        ai.error = Exception('offline');
        final other = SalePlanner.plan(
          items: [
            WishlistItem(
              id: 'm',
              title: 'Chuột',
              budgetGroupId: 'tech',
              latestPriceVnd: 300000,
              createdAt: _now,
            ),
          ],
          groups: defaultBudgetGroups,
          available: {'tech': 1000000},
          now: _now,
        );
        final failed = await vm.explainPlans(other);
        expect(failed.values.every((r) => !r.fromAi), isTrue);
      },
    );
  });
}
