import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/models/buying_motive.dart';
import 'package:prm393_lab03/models/purchase_item.dart';
import 'package:prm393_lab03/models/sale_event.dart';
import 'package:prm393_lab03/models/wishlist_item.dart';
import 'package:prm393_lab03/models/wishlist_status.dart';
import 'package:prm393_lab03/services/ai_decision_service.dart';
import 'package:prm393_lab03/services/ai_service.dart';
import 'package:prm393_lab03/services/preferences_service.dart';
import 'package:prm393_lab03/services/remote_config_service.dart';
import 'package:prm393_lab03/services/review_reminder_service.dart';
import 'package:prm393_lab03/services/wishlist_service.dart';
import 'package:prm393_lab03/viewmodels/decision_support_viewmodel.dart';
import 'package:prm393_lab03/widgets/price_update_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/purchase_harness.dart';
import 'support/test_theme.dart';

final _now = DateTime(2026, 11, 2, 12);

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

/// Remote Config with the sale calendar from the console
class _Config extends Fake implements FirebaseRemoteConfig {
  bool saleReminders = true;

  @override
  bool getBool(String key) =>
      key == RemoteConfigService.keySaleReminderEnabled ? saleReminders : true;

  @override
  String getString(String key) => key == RemoteConfigService.keySaleCalendar
      ? '[{"date":"2026-11-11","name":"11.11","type":"double_day","confirmed":true},'
            '{"date":"2026-11-25","name":"Sale ngày lương 25.11","type":"payday","confirmed":true},'
            '{"date":"2026-12-12","name":"12.12","type":"double_day","confirmed":false}]'
      : '';
}

class _Reminders implements ReviewReminderService {
  List<({String saleId, String saleType, String body, DateTime at})> sales =
      const [];
  int saleSyncs = 0;
  bool grant = true;

  @override
  bool get isSupported => true;

  @override
  Future<void> scheduleSaleReminders(
    List<({String saleId, String saleType, String body, DateTime at})>
    reminders,
  ) async {
    saleSyncs++;
    sales = reminders;
  }

  @override
  Future<bool> requestPermission() async => grant;

  @override
  Future<void> initialize({
    VoidCallback? onOpen,
    VoidCallback? onOpenDaily,
    void Function(Map<String, dynamic> data)? onOpenSale,
  }) async {}

  @override
  bool consumeLaunchedFromReminder() => false;

  @override
  bool consumeLaunchedFromDailyReminder() => false;

  @override
  Future<void> schedule({
    required String itemId,
    required String title,
    required DateTime at,
  }) async {}

  @override
  Future<void> cancel(String itemId) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> scheduleDaily({required int hour, required int minute}) async {}

  @override
  Future<void> cancelDaily() async {}

  @override
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {}
}

WishlistItem _considering(String id) =>
    WishlistItem(id: id, title: 'Món $id', createdAt: DateTime(2026, 10, 20));

void main() {
  group('A-10: Lịch sử filter "Mua từ Wishlist"', () {
    late PurchaseHarness h;

    setUp(() async {
      h = PurchaseHarness();
      final now = DateTime.now();
      for (final p in [
        PurchaseItem(
          id: 'p1',
          title: 'Tai nghe',
          amountVnd: 420000,
          motive: BuyingMotive.sale,
          occurredAt: now,
          wishlistItemId: 'w1',
        ),
        PurchaseItem(
          id: 'p2',
          title: 'Cơm tấm',
          amountVnd: 40000,
          motive: BuyingMotive.need,
          occurredAt: now,
        ),
        PurchaseItem(
          id: 'p3',
          title: 'Áo',
          amountVnd: 200000,
          motive: BuyingMotive.want,
          occurredAt: now,
          wishlistItemId: 'w2',
        ),
      ]) {
        await h.db
            .doc('users/${PurchaseHarness.uid}/purchases/${p.id}')
            .set(p.toMap());
      }
      await h.initialize();
      await _settle();
    });

    tearDown(() => h.dispose());

    List<String> ids() =>
        h.purchases.filteredPurchases.map((p) => p.id).toList()..sort();

    test(
      'only purchases recorded from a Wishlist item; combines with motive',
      () {
        expect(ids(), ['p1', 'p2', 'p3']);
        expect(h.purchases.hasActiveFilter, isFalse);

        h.purchases.setFromWishlistOnly(true);
        expect(ids(), ['p1', 'p3']);
        expect(h.purchases.hasActiveFilter, isTrue);

        h.purchases.setMotiveFilter(BuyingMotive.want);
        expect(ids(), ['p3']);

        // "Tất cả" turns every filter off
        h.purchases.clearFilters();
        expect(ids(), ['p1', 'p2', 'p3']);
        expect(h.purchases.fromWishlistOnly, isFalse);
      },
    );

    test('signing in as someone else resets the filter', () {
      h.purchases.setFromWishlistOnly(true);
      h.purchases.updateUid('user-b');
      expect(h.purchases.fromWishlistOnly, isFalse);
    });
  });

  testWidgets('22.1: "Giá vẫn là …" confirms the recorded price in one tap', (
    tester,
  ) async {
    int? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: testAppTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => result = await PriceUpdateSheet.show(
                context,
                currentPrice: 389000,
                currentPriceAt: DateTime(2026, 10, 20),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Giá vẫn là 389.000 ₫'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('price-confirm-same')));
    await tester.pumpAndSettle();
    expect(result, 389000);
  });

  testWidgets('a first price has no confirm button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: testAppTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => PriceUpdateSheet.show(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('price-confirm-same')), findsNothing);
  });

  group('A-13: "Nhắc đợt sale" at 20:00 the evening before (spec 8.2)', () {
    final events = SaleCalendar.parse(_Config().getString('sale_calendar'));

    test('only confirmed sales; "Chỉ đợt lớn" keeps double days', () {
      final big = SaleCalendar.remindersFor(
        events,
        SaleReminderLevel.bigOnly,
        _now,
      );
      expect(big.map((r) => r.sale.name), ['11.11']);
      expect(big.single.at, DateTime(2026, 11, 10, 20));

      final all = SaleCalendar.remindersFor(
        events,
        SaleReminderLevel.all,
        _now,
      );
      expect(all.map((r) => r.sale.name), ['11.11', 'Sale ngày lương 25.11']);

      expect(
        SaleCalendar.remindersFor(events, SaleReminderLevel.off, _now),
        isEmpty,
      );
    });

    test('a reminder time already past is not scheduled', () {
      final late = DateTime(2026, 11, 10, 20, 30);
      expect(
        SaleCalendar.remindersFor(events, SaleReminderLevel.bigOnly, late),
        isEmpty,
      );
    });

    test(
      'level is stored on the device; unknown values fall back to big only',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = PreferencesService();
        expect(await prefs.getSaleReminderLevel(), 'big_only');
        await prefs.setSaleReminderLevel(SaleReminderLevel.all.key);
        expect(await prefs.getSaleReminderLevel(), 'all');
        expect(
          SaleReminderLevel.fromKey('nonsense'),
          SaleReminderLevel.bigOnly,
        );
      },
    );

    group('view model sync', () {
      late PurchaseHarness h;
      late _Config config;
      late _Reminders reminders;
      late DecisionSupportViewModel vm;

      setUp(() async {
        SharedPreferences.setMockInitialValues({});
        h = PurchaseHarness();
        config = _Config();
        reminders = _Reminders();
        vm = DecisionSupportViewModel(
          budgetService: h.budgetService,
          wishlistService: FirestoreWishlistService(h.db),
          aiDecisionService: AiDecisionService(generator: _NoAi()),
          remoteConfigService: RemoteConfigService(remoteConfig: config),
          preferencesService: PreferencesService(),
          reminderService: reminders,
          platformSupportsAi: () => false,
          now: () => _now,
        )..updateUid(PurchaseHarness.uid);
        await _settle();
      });

      tearDown(() {
        vm.dispose();
        h.dispose();
      });

      void feed(List<WishlistItem> items) => vm.updateSources(
        purchases: const [],
        wishlistItems: items,
        groups: const [],
      );

      test('one neutral notification per sale, with the number of items', () {
        feed([
          _considering('a'),
          _considering('b'),
          _considering('c').copyWith(status: WishlistStatus.skipped),
        ]);
        expect(reminders.sales, hasLength(1));
        final r = reminders.sales.single;
        expect(r.saleId, '2026-11-11');
        expect(r.saleType, 'double_day');
        expect(r.at, DateTime(2026, 11, 10, 20));
        expect(
          r.body,
          'Mai là 11.11. Bạn có 2 món trong danh sách. Mở xem nhé?',
        );
      });

      test('nothing when no item is being considered or the flag is off', () {
        feed([]);
        expect(reminders.sales, isEmpty);

        config.saleReminders = false;
        feed([_considering('a')]);
        expect(reminders.sales, isEmpty);
      });

      test('the same plan is not handed to the plugin twice', () {
        feed([_considering('a')]);
        final syncs = reminders.saleSyncs;
        feed([_considering('a')]);
        expect(reminders.saleSyncs, syncs);
      });

      test('changing the level asks permission and reschedules', () async {
        feed([_considering('a')]);
        expect(await vm.setSaleReminderLevel(SaleReminderLevel.all), isTrue);
        expect(reminders.sales.map((r) => r.saleId), [
          '2026-11-11',
          '2026-11-25',
        ]);

        reminders.grant = false;
        expect(
          await vm.setSaleReminderLevel(SaleReminderLevel.bigOnly),
          isFalse,
        );

        await vm.setSaleReminderLevel(SaleReminderLevel.off);
        expect(reminders.sales, isEmpty);
      });

      test('signing out cancels the account\'s sale reminders', () {
        feed([_considering('a')]);
        expect(reminders.sales, isNotEmpty);
        vm.updateUid(null);
        expect(reminders.sales, isEmpty);
      });
    });

    test('a tapped sale reminder carries the same data as a sale push', () {
      final payload = LocalReviewReminderService.salePayload(
        '2026-11-11',
        'double_day',
      );
      expect(LocalReviewReminderService.saleDataFrom(payload), {
        'type': 'sale',
        'sale_id': '2026-11-11',
        'sale_type': 'double_day',
      });
      expect(LocalReviewReminderService.saleDataFrom('item-1'), isNull);
      expect(
        LocalReviewReminderService.saleDataFrom(
          LocalReviewReminderService.dailyPayload,
        ),
        isNull,
      );
    });
  });
}
