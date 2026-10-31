import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/models/buying_motive.dart';
import 'package:prm393_lab03/models/notification_target.dart';
import 'package:prm393_lab03/models/ui_state.dart';
import 'package:prm393_lab03/models/wishlist_item.dart';
import 'package:prm393_lab03/models/wishlist_status.dart';
import 'package:prm393_lab03/screens/add_item_screen.dart';
import 'package:prm393_lab03/services/notification_service.dart';
import 'package:prm393_lab03/services/wishlist_service.dart';
import 'package:prm393_lab03/viewmodels/wishlist_viewmodel.dart';

import 'support/purchase_harness.dart';

Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('Tapped push notification (FCM custom data)', () {
    test('type picks the screen; a sale needs sale_reminder_enabled', () {
      NotificationTarget target(
        Map<String, dynamic> data, {
        bool sale = true,
      }) => NotificationRoute.targetFor(data, saleRemindersEnabled: sale);

      expect(target({'type': 'sale'}), NotificationTarget.saleConsidering);
      expect(target({'type': 'sale'}, sale: false), NotificationTarget.none);
      expect(target({'type': 'review'}), NotificationTarget.reviewDue);
      expect(target({'type': 'reflection'}), NotificationTarget.reflection);
      expect(target({}), NotificationTarget.none);
      expect(target({'type': 'something-else'}), NotificationTarget.none);
    });

    test('only the planned sale_type values reach Analytics', () {
      expect(NotificationRoute.saleTypeOf({'sale_type': 'payday'}), 'payday');
      expect(
        NotificationRoute.saleTypeOf({'sale_type': 'black friday'}),
        'other',
      );
      expect(NotificationRoute.saleTypeOf({}), 'other');
    });

    test(
      'with sale reminders off, sale messages stay out of the in-app list',
      () {
        var enabled = false;
        final service = NotificationService(
          saleRemindersEnabled: () => enabled,
        );
        service.recordNotification(
          const RemoteMessage(messageId: 's1', data: {'type': 'sale'}),
        );
        service.recordNotification(
          const RemoteMessage(messageId: 'r1', data: {'type': 'review'}),
        );
        expect(service.receivedNotifications.map((n) => n.id), ['r1']);

        enabled = true;
        service.recordNotification(
          const RemoteMessage(messageId: 's2', data: {'type': 'sale'}),
        );
        expect(service.receivedNotifications.map((n) => n.id), ['s2', 'r1']);
      },
    );
  });

  group('Remote Config max_wishlist_items_shown', () {
    late FakeFirebaseFirestore db;
    late WishlistViewModel vm;

    setUp(() async {
      db = FakeFirebaseFirestore();
      for (var i = 0; i < 5; i++) {
        await db
            .doc('users/u1/wishlistItems/w$i')
            .set(
              WishlistItem(
                id: 'w$i',
                title: 'Món $i',
                motive: BuyingMotive.want,
                status: i == 4
                    ? WishlistStatus.skipped
                    : WishlistStatus.considering,
                createdAt: DateTime(2026, 10, 1 + i),
              ).toMap(),
            );
      }
      vm = WishlistViewModel(
        wishlistService: FirestoreWishlistService(db),
        analyticsService: TestAnalytics(),
      )..updateUid('u1');
      await _settle();
    });

    tearDown(() => vm.dispose());

    List<WishlistItem> items() =>
        (vm.state as UiSuccess<List<WishlistItem>>).data;

    test('the list shows the configured number until "Xem thêm"', () async {
      vm.updateMaxShown(2);
      await _settle();
      expect(vm.visibleOf(items()), hasLength(2));

      vm.showAllItems();
      expect(vm.visibleOf(items()), hasLength(5));

      // A new filter starts collapsed again
      vm.setMotiveFilter(BuyingMotive.want);
      expect(vm.visibleOf(items()), hasLength(2));
    });

    test('a value below 1 still shows one item', () {
      vm.updateMaxShown(0);
      expect(vm.maxShown, 1);
    });

    test('sale reminder opens the items still being considered', () {
      vm.setReviewDueFilter(true);
      vm.showConsidering();
      expect(vm.reviewDueOnly, isFalse);
      expect(vm.selectedStatusFilter, WishlistStatus.considering);
      expect(items().map((i) => i.id), isNot(contains('w4')));
    });
  });

  group('Small UI fixes', () {
    test('cooldown countdown is rounded up', () {
      WishlistItem withCooldown(Duration left) => WishlistItem(
        id: 'x',
        title: 'x',
        createdAt: DateTime.now(),
        cooldownUntil: DateTime.now().add(left),
      );
      // Saved a minute ago with a 3-day cooldown
      expect(
        withCooldown(const Duration(days: 3) - const Duration(minutes: 1))
            .remainingCooldownLabel,
        '3 ngày',
      );
      expect(
        withCooldown(const Duration(hours: 5, minutes: 30))
            .remainingCooldownLabel,
        '6 giờ',
      );
      expect(
        withCooldown(const Duration(minutes: 10)).remainingCooldownLabel,
        '1 giờ',
      );
    });

    testWidgets('Thêm món price field groups digits and saves the VND amount', (
      tester,
    ) async {
      final h = PurchaseHarness();
      addTearDown(h.dispose);
      tester.view.physicalSize = const Size(412, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await h.initialize();
      await tester.pumpWidget(h.app(const AddItemScreen()));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Máy ảnh film');
      final price = find.descendant(
        of: find.byKey(const ValueKey('wishlist-price')),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(price, '5000000');
      await tester.pump();
      expect(find.text('5.000.000'), findsOneWidget);
      expect(find.text('₫'), findsOneWidget);

      await tester.tap(find.text('Lưu vào Wishlist'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      final saved = await h.db
          .collection('users/${PurchaseHarness.uid}/wishlistItems')
          .get();
      expect(saved.docs.single.data()['latestPriceVnd'], 5000000);
    });
  });
}
