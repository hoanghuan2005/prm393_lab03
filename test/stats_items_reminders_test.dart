import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/app/routes.dart';
import 'package:prm393_lab03/models/buying_motive.dart';
import 'package:prm393_lab03/models/purchase_draft.dart';
import 'package:prm393_lab03/models/purchase_item.dart';
import 'package:prm393_lab03/models/wishlist_status.dart';
import 'package:prm393_lab03/screens/patterns_screen.dart';
import 'package:prm393_lab03/services/review_reminder_service.dart';
import 'package:prm393_lab03/services/wishlist_service.dart';
import 'package:prm393_lab03/viewmodels/purchase_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/wishlist_viewmodel.dart';

import 'support/purchase_harness.dart';

const _path = 'users/${PurchaseHarness.uid}';

PurchaseItem _p(String id, int amount, BuyingMotive motive, DateTime at) =>
    PurchaseItem(
      id: id,
      title: id,
      amountVnd: amount,
      motive: motive,
      occurredAt: at,
    );

class FakeReminders implements ReviewReminderService {
  final scheduled = <String, DateTime>{};
  int cancelAllCalls = 0;
  bool grant = true;

  @override
  bool get isSupported => true;

  @override
  Future<void> initialize({VoidCallback? onOpen}) async {}

  @override
  bool consumeLaunchedFromReminder() => false;

  @override
  Future<bool> requestPermission() async => grant;

  @override
  Future<void> schedule({
    required String itemId,
    required String title,
    required DateTime at,
  }) async => scheduled[itemId] = at;

  @override
  Future<void> cancel(String itemId) async => scheduled.remove(itemId);

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
    scheduled.clear();
  }
}

/// Lets Firestore snapshots and the async reminder sync run
Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// The fake Firestore streams were opened in setUp, outside the widget test's fake
/// clock; give them real time to deliver, then rebuild
Future<void> _deliverFirestore(WidgetTester tester) async {
  await tester.runAsync(_settle);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Item 7: one period for every number', () {
    final all = [
      _p('mon', 200000, BuyingMotive.sale, DateTime(2025, 3, 3, 10)),
      _p('late', 100000, BuyingMotive.need, DateTime(2025, 3, 20, 23)),
      _p('jan', 999000, BuyingMotive.ads, DateTime(2025, 1, 5, 9)),
    ];

    test('month stats ignore other months; motive shares add up to 100%', () {
      final s = PeriodStats(DateTime(2025, 3), DateTime(2025, 4), all);
      expect(s.total, 300000);
      expect(s.count, 2);
      expect(s.motives.map((m) => m.motive), [
        BuyingMotive.sale,
        BuyingMotive.need,
      ]);
      final shares = s.motives.fold(0.0, (acc, m) => acc + s.shareOf(m.totalVnd));
      expect(shares, closeTo(1, 1e-9));
      expect(s.timeSlots.fold(0, (acc, t) => acc + t.count), 2);
    });

    test('a week is Monday 00:00 to the next Monday, exclusive', () {
      final monday = PurchaseViewModel.weekStartOf(DateTime(2025, 3, 6));
      expect(monday, DateTime(2025, 3, 3));
      final s = PeriodStats(monday, DateTime(2025, 3, 10), all);
      expect(s.count, 1);
      expect(s.total, 200000);
    });

    testWidgets('Tuần / Tháng really switches the data on Mô hình', (tester) async {
      final h = PurchaseHarness();
      await h.initialize();
      for (final p in all) {
        await h.db.doc('$_path/purchases/${p.id}').set(p.toMap());
      }
      h.purchases.setSelectedMonth(DateTime(2025, 3));
      await tester.pumpWidget(h.app(const PatternsScreen()));
      await tester.pumpAndSettle();

      // Starts on the current week, which has none of these purchases
      expect(find.text('Tổng chi tiêu trong tuần'), findsOneWidget);
      expect(find.text('0 khoản đã ghi nhận'), findsOneWidget);

      await tester.tap(find.text('Tháng'));
      await tester.pumpAndSettle();
      expect(find.text('Tổng chi tiêu trong tháng'), findsOneWidget);
      expect(find.text('2 khoản đã ghi nhận'), findsOneWidget);
      expect(find.text('67%'), findsOneWidget);
      expect(find.text('33%'), findsOneWidget);
      // January's "Quảng cáo" purchase is not part of March
      expect(find.text('Quảng cáo'), findsNothing);
      h.dispose();
    });
  });

  group('Item 8: managing a wishlist item', () {
    late PurchaseHarness h;
    setUp(() async {
      h = PurchaseHarness();
      await h.initialize(item: sampleWishlist());
    });
    tearDown(() => h.dispose());

    Future<Map<String, dynamic>> item() async =>
        (await h.db.doc('$_path/wishlistItems/headphones').get()).data()!;

    test('edit changes details, can clear the link, keeps price and status', () async {
      await h.db.doc('$_path/wishlistItems/headphones').update({
        'url': 'https://shopee.vn/x',
      });
      expect(
        await h.wishlist.updateDetails(
          sampleWishlist(),
          title: '  Tai nghe chống ồn  ',
          url: '',
          motive: BuyingMotive.need,
          budgetGroupId: 'study',
        ),
        isTrue,
      );
      final data = await item();
      expect(data['title'], 'Tai nghe chống ồn');
      expect(data['url'], isNull);
      expect(data['motive'], 'need');
      expect(data['budgetGroupId'], 'study');
      expect(data['latestPriceVnd'], 420000);
      expect(data['status'], WishlistStatus.considering.key);
    });

    test('price update adds a dated snapshot and fills in an unknown price', () async {
      expect(await h.wishlist.updatePrice(sampleWishlist(), 399000), isTrue);
      final data = await item();
      expect(data['latestPriceVnd'], 399000);
      expect(data['latestPriceAt'], isA<Timestamp>());
      final snapshots = await h.db
          .collection('$_path/wishlistItems/headphones/priceSnapshots')
          .get();
      expect(snapshots.docs.map((d) => d.data()['amountVnd']), [399000]);
    });

    test('delete removes the item and its price history', () async {
      await h.wishlist.updatePrice(sampleWishlist(), 399000);
      expect(await h.wishlist.deleteItem(sampleWishlist()), isTrue);
      expect(
        (await h.db.doc('$_path/wishlistItems/headphones').get()).exists,
        isFalse,
      );
      expect(
        (await h.db
                .collection('$_path/wishlistItems/headphones/priceSnapshots')
                .get())
            .docs,
        isEmpty,
      );
    });

    Future<void> openDetail(WidgetTester tester) async {
      await tester.pumpWidget(
        h.app(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.itemDetail,
                arguments: ItemDetailArgs(sampleWishlist()),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await _deliverFirestore(tester);
    }

    testWidgets('detail shows the price date and updates the price', (tester) async {
      await openDetail(tester);
      // Legacy item: a price without its date
      expect(find.text('Giá bạn đã ghi.'), findsOneWidget);
      await tester.tap(find.text('Cập nhật giá'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('price-update-amount')),
          matching: find.byType(TextFormField),
        ),
        '350000',
      );
      await tester.tap(find.text('Lưu giá'));
      await tester.pumpAndSettle();
      expect((await item())['latestPriceVnd'], 350000);
      await _deliverFirestore(tester);
      expect(find.text('350.000 ₫'), findsOneWidget);
      expect(find.textContaining('Giá ghi ngày'), findsOneWidget);
    });

    testWidgets('delete asks for confirmation and leaves the screen after deleting', (
      tester,
    ) async {
      await openDetail(tester);
      await tester.tap(find.byTooltip('Xoá món'));
      await tester.pumpAndSettle();
      expect(find.text('Xoá món này?'), findsOneWidget);
      await tester.tap(find.text('Huỷ'));
      await tester.pumpAndSettle();
      expect((await h.db.doc('$_path/wishlistItems/headphones').get()).exists, isTrue);

      await tester.tap(find.byTooltip('Xoá món'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Xoá'));
      await tester.pumpAndSettle();
      expect(find.text('open'), findsOneWidget);
      expect((await h.db.doc('$_path/wishlistItems/headphones').get()).exists, isFalse);
    });

    testWidgets('edit screen saves new details', (tester) async {
      await openDetail(tester);
      await tester.tap(find.byTooltip('Sửa thông tin món'));
      await tester.pumpAndSettle();
      expect(find.text('Sửa thông tin món'), findsWidgets);
      // The price is not edited here, it goes through "Cập nhật giá"
      expect(find.textContaining('Giá dự kiến'), findsNothing);
      await tester.enterText(find.byType(TextFormField).first, 'Tai nghe mới');
      await tester.ensureVisible(find.text('Lưu thay đổi'));
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();
      expect((await item())['title'], 'Tai nghe mới');
    });

    test('an item without a price is never shown or stored as 0', () async {
      await h.db.doc('$_path/wishlistItems/headphones').update({
        'latestPriceVnd': null,
      });
      await _settle();
      final current = h.wishlist.allItems.single;
      expect(current.hasPrice, isFalse);
      expect(current.latestPriceVnd, isNull);
    });
  });

  group('Item 9: review reminders and "Cần xem lại"', () {
    late PurchaseHarness h;
    late FakeReminders reminders;
    late WishlistViewModel vm;

    setUp(() async {
      h = PurchaseHarness();
      await h.initialize(item: sampleWishlist());
      reminders = FakeReminders();
      vm = WishlistViewModel(
        wishlistService: FirestoreWishlistService(h.db),
        analyticsService: h.analytics,
        reminderService: reminders,
      )..updateUid(PurchaseHarness.uid);
      await _settle();
    });
    tearDown(() {
      vm.dispose();
      h.dispose();
    });

    test('Chờ schedules one reminder on the chosen date', () async {
      final reviewAt = DateTime.now().add(const Duration(days: 3));
      await vm.wait(sampleWishlist(), reviewAt);
      await _settle();
      expect(reminders.scheduled, {'headphones': reviewAt});
    });

    test('Bỏ qua, Mua and delete each cancel the reminder', () async {
      Future<void> waitAgain() async {
        await vm.wait(sampleWishlist(), DateTime.now().add(const Duration(days: 3)));
        await _settle();
        expect(reminders.scheduled, contains('headphones'));
      }

      await waitAgain();
      await vm.skip(sampleWishlist());
      await _settle();
      expect(reminders.scheduled, isEmpty);

      await vm.reconsider(sampleWishlist());
      await waitAgain();
      await h.service.buyFromWishlist(
        PurchaseHarness.uid,
        sampleWishlist(),
        const PurchaseDraft(amountVnd: 389000, fromWishlistId: 'headphones'),
      );
      await _settle();
      expect(reminders.scheduled, isEmpty);
    });

    test('signing out cancels every reminder of the account', () async {
      await vm.wait(sampleWishlist(), DateTime.now().add(const Duration(days: 3)));
      await _settle();
      vm.updateUid(null);
      await _settle();
      expect(reminders.scheduled, isEmpty);
    });

    test('an arrived review date appears in "Cần xem lại"', () async {
      await h.db.doc('$_path/wishlistItems/headphones').update({
        'reviewAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 1)),
        ),
      });
      await _settle();
      expect(vm.reviewDueCount, 1);
      vm.setReviewDueFilter(true);
      expect(vm.filteredItems.single.id, 'headphones');
      // A past date is never scheduled as a notification
      expect(reminders.scheduled, isEmpty);
    });

    test('permission result tells the screen which message to show', () async {
      reminders.grant = false;
      expect(await vm.requestReminderPermission(), ReminderPermission.denied);
      final noReminders = WishlistViewModel(
        wishlistService: FirestoreWishlistService(h.db),
        analyticsService: h.analytics,
      );
      expect(
        await noReminders.requestReminderPermission(),
        ReminderPermission.unsupported,
      );
      noReminders.dispose();
    });

    test('notification ids are stable across runs', () {
      expect(
        LocalReviewReminderService.idFor('headphones'),
        LocalReviewReminderService.idFor('headphones'),
      );
      expect(
        LocalReviewReminderService.idFor('headphones'),
        isNot(LocalReviewReminderService.idFor('keyboard')),
      );
      expect(LocalReviewReminderService.idFor('headphones'), greaterThan(0));
    });
  });
}
