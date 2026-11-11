import 'dart:async';
import 'dart:typed_data';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/app/app.dart';
import 'package:prm393_lab03/app/routes.dart';
import 'package:prm393_lab03/models/buying_motive.dart';
import 'package:prm393_lab03/models/notification_target.dart';
import 'package:prm393_lab03/models/purchase_item.dart';
import 'package:prm393_lab03/models/reflection.dart';
import 'package:prm393_lab03/models/ui_state.dart';
import 'package:prm393_lab03/models/wishlist_item.dart';
import 'package:prm393_lab03/services/analytics_service.dart';
import 'package:prm393_lab03/services/reflection_service.dart';
import 'package:prm393_lab03/services/report_metadata_service.dart';
import 'package:prm393_lab03/services/report_service.dart';
import 'package:prm393_lab03/services/report_share_service.dart';
import 'package:prm393_lab03/services/review_reminder_service.dart';
import 'package:prm393_lab03/theme/app_theme.dart';
import 'package:prm393_lab03/viewmodels/reflection_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/report_viewmodel.dart';

import 'ui/ui_audit_harness.dart';

Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

ReflectionViewModel _vm(FakeFirebaseFirestore db, DateTime month) =>
    ReflectionViewModel(reflectionService: FirestoreReflectionService(db))
      ..updateUid('user-a')
      ..updateMonth(month);

/// Fails every call, as Firestore does when the rules refuse or the network drops
class _BrokenService implements ReflectionService {
  @override
  Stream<Reflection?> watch(String uid, String monthKey) =>
      Stream.error(Exception('offline'));

  @override
  Future<void> save(String uid, Reflection reflection) async =>
      throw Exception('offline');
}

class _FakePdf extends ReportService {
  @override
  Future<Uint8List> generateMonthlyReportPdf({
    required String userName,
    required DateTime month,
    required List<PurchaseItem> purchases,
    required List<WishlistItem> decidedItems,
  }) async => Uint8List(3000);
}

class _Share extends Fake implements ReportShareService {
  final bool accept;
  _Share({this.accept = true});

  @override
  Future<bool> sharePdf(Uint8List bytes, String fileName) async => accept;
}

class _Analytics extends Fake implements AppAnalyticsService {
  @override
  Future<void> logExportReport({
    required String fileFormat,
    required int itemCount,
  }) async {}
}

class _BrokenMetadata implements ReportMetadataService {
  @override
  Future<void> record(String uid, ReportRecord report) async =>
      throw Exception('permission-denied');
}

void main() {
  group('R-5: ReflectionViewModel', () {
    test('loads the saved reflection and starts from its rating', () async {
      final db = FakeFirebaseFirestore();
      await db.doc('users/user-a/reflections/2026-10').set({
        'rating': 4,
        'goal': 'Ít mua sau 22 giờ',
      });
      final vm = _vm(db, DateTime(2026, 10, 15));
      expect(vm.state, isA<UiLoading<Reflection?>>());
      await _settle();

      expect(vm.state, isA<UiSuccess<Reflection?>>());
      expect(vm.saved?.goal, 'Ít mua sau 22 giờ');
      expect(vm.rating, 4);
      expect(vm.nextMonth, DateTime(2026, 11));
      vm.dispose();
    });

    test(
      'a month without a reflection: no rating, so saving is refused',
      () async {
        final db = FakeFirebaseFirestore();
        final vm = _vm(db, DateTime(2026, 10));
        await _settle();

        expect(vm.saved, isNull);
        expect(vm.rating, isNull);
        expect(await vm.save('Mục tiêu'), isFalse);
        expect(
          (await db.doc('users/user-a/reflections/2026-10').get()).exists,
          isFalse,
        );
        vm.dispose();
      },
    );

    test('saving trims the goal and cuts it to 200 characters', () async {
      final db = FakeFirebaseFirestore();
      final vm = _vm(db, DateTime(2026, 10));
      await _settle();
      vm.selectRating(9); // clamped to 5
      expect(await vm.save('  ${'a' * 250}  '), isTrue);

      final doc = await db.doc('users/user-a/reflections/2026-10').get();
      expect(doc.data()!['rating'], 5);
      expect((doc.data()!['goal'] as String).length, 200);
      expect(doc.data()!['updatedAt'], isNotNull);
      vm.dispose();
    });

    test('an empty goal is saved as no goal', () async {
      final db = FakeFirebaseFirestore();
      final vm = _vm(db, DateTime(2026, 10));
      await _settle();
      vm.selectRating(3);
      expect(await vm.save('   '), isTrue);
      final doc = await db.doc('users/user-a/reflections/2026-10').get();
      expect(doc.data()!['goal'], isNull);
      vm.dispose();
    });

    test('editing a saved reflection again overwrites it', () async {
      final db = FakeFirebaseFirestore();
      final vm = _vm(db, DateTime(2026, 10));
      await _settle();
      vm.selectRating(2);
      await vm.save('Lần đầu');
      await _settle();
      vm.selectRating(5);
      await vm.save('Sửa lại');
      await _settle();

      expect(vm.saved?.rating, 5);
      expect(vm.saved?.goal, 'Sửa lại');
      vm.dispose();
    });

    test('CR-08: "Bỏ thay đổi" puts the saved rating back', () async {
      final db = FakeFirebaseFirestore();
      await db.doc('users/user-a/reflections/2026-10').set({'rating': 5});
      final vm = _vm(db, DateTime(2026, 10));
      await _settle();

      vm.selectRating(3);
      expect(vm.rating, 3);
      vm.discardChanges();
      expect(vm.rating, 5);

      // With nothing saved, discarding clears the choice
      vm.updateMonth(DateTime(2026, 9));
      await _settle();
      vm.selectRating(2);
      vm.discardChanges();
      expect(vm.rating, isNull);
      vm.dispose();
    });

    test(
      'R-2: the goal written last month is the goal of this month',
      () async {
        final db = FakeFirebaseFirestore();
        await db.doc('users/user-a/reflections/2026-09').set({
          'rating': 4,
          'goal': 'Chờ 3 ngày trước món trên 500k',
        });
        final vm = _vm(db, DateTime(2026, 10));
        await _settle();
        expect(vm.previousMonth, DateTime(2026, 9));
        expect(vm.goalForMonth, 'Chờ 3 ngày trước món trên 500k');

        // Follows the month: November has no goal from October yet
        vm.updateMonth(DateTime(2026, 11));
        await _settle();
        expect(vm.goalForMonth, isNull);

        // Saving October's goal shows it in November at once
        final october = _vm(db, DateTime(2026, 10));
        await _settle();
        october.selectRating(3);
        await october.save('Ghi lại mọi khoản mua');
        await _settle();
        expect(vm.goalForMonth, 'Ghi lại mọi khoản mua');
        vm.dispose();
        october.dispose();
      },
    );

    test('a read error becomes an error state with a retry', () async {
      final vm = ReflectionViewModel(reflectionService: _BrokenService())
        ..updateUid('user-a');
      await _settle();
      expect(vm.state, isA<UiError<Reflection?>>());
      expect((vm.state as UiError<Reflection?>).onRetry, isNotNull);
      vm.dispose();
    });

    test('a failed save returns false with a message', () async {
      final db = FakeFirebaseFirestore();
      final vm = ReflectionViewModel(reflectionService: _BrokenService())
        ..updateUid('user-a');
      await _settle();
      vm.selectRating(4);
      expect(await vm.save('x'), isFalse);
      expect(vm.actionError, isNotEmpty);
      expect(vm.isSaving, isFalse);
      expect(db, isNotNull);
      vm.dispose();
    });

    test('signing out clears everything', () async {
      final db = FakeFirebaseFirestore();
      await db.doc('users/user-a/reflections/2026-10').set({'rating': 4});
      final vm = _vm(db, DateTime(2026, 10));
      await _settle();
      vm.updateUid(null);
      await _settle();
      expect(vm.state, isA<UiInitial<Reflection?>>());
      expect(vm.saved, isNull);
      expect(vm.rating, isNull);
      vm.dispose();
    });
  });

  group('R-1: month-end reminder', () {
    test('20:00 on the last day of this month and the next ones', () {
      expect(reflectionReminderTimes(DateTime(2026, 11, 11, 9)), [
        DateTime(2026, 11, 30, 20),
        DateTime(2026, 12, 31, 20),
        DateTime(2027, 1, 31, 20),
      ]);
      // February in a leap year; the year rolls over
      expect(reflectionReminderTimes(DateTime(2028, 2, 1), count: 1), [
        DateTime(2028, 2, 29, 20),
      ]);
    });

    test('a time already past is skipped, still 3 reminders', () {
      expect(reflectionReminderTimes(DateTime(2026, 11, 30, 21)), [
        DateTime(2026, 12, 31, 20),
        DateTime(2027, 1, 31, 20),
        DateTime(2027, 2, 28, 20),
      ]);
    });

    test('a tapped reminder carries its month', () {
      final data = LocalReviewReminderService.reflectionDataFrom(
        'reflection:2026-11',
      )!;
      expect(
        NotificationRoute.targetFor(data, saleRemindersEnabled: false),
        NotificationTarget.reflection,
      );
      expect(NotificationRoute.monthOf(data), DateTime(2026, 11));
      expect(LocalReviewReminderService.reflectionDataFrom('item-1'), isNull);
      expect(NotificationRoute.monthOf({'month': '2026-13'}), isNull);
      expect(NotificationRoute.monthOf({'month': 'x'}), isNull);
      expect(NotificationRoute.monthOf(const {}), isNull);
    });
  });

  group('R-4: PDF metadata in Firestore', () {
    ReportViewModel report(
      ReportMetadataService? metadata, {
      bool accept = true,
    }) =>
        ReportViewModel(
            reportService: _FakePdf(),
            shareService: _Share(accept: accept),
            analyticsService: _Analytics(),
            metadataService: metadata,
          )
          ..updateUid('user-a')
          ..updateSources(
            userName: 'A',
            purchases: [
              PurchaseItem(
                id: 'p1',
                title: 'Trà sữa',
                amountVnd: 45000,
                motive: BuyingMotive.want,
                occurredAt: DateTime(2026, 10, 3),
              ),
            ],
            wishlistItems: const [],
          );

    test('a shared report saves month, item count, size and shared', () async {
      final db = FakeFirebaseFirestore();
      final vm = report(FirestoreReportMetadataService(db));
      expect(await vm.generateAndShare(DateTime(2026, 10)), isTrue);

      final docs = (await db.collection('users/user-a/reports').get()).docs;
      expect(docs, hasLength(1));
      final data = docs.single.data();
      expect(data['month'], '2026-10');
      expect(data['itemCount'], 1);
      expect(data['sizeKb'], 3); // 3000 bytes, rounded up
      expect(data['shared'], isTrue);
      expect(data['createdAt'], isNotNull);
    });

    test('a share the system refused is recorded as not shared', () async {
      final db = FakeFirebaseFirestore();
      final vm = report(FirestoreReportMetadataService(db), accept: false);
      expect(await vm.generateAndShare(DateTime(2026, 10)), isFalse);
      final docs = (await db.collection('users/user-a/reports').get()).docs;
      expect(docs.single.data()['shared'], isFalse);
    });

    test('a metadata write that fails never blocks the share', () async {
      final vm = report(_BrokenMetadata());
      expect(await vm.generateAndShare(DateTime(2026, 10)), isTrue);
      expect(vm.status, ReportStatus.shared);
    });
  });

  group('R-3 / R-5: the Save button', () {
    testWidgets('says a rating is needed, then enables Save', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final h = UiAuditHarness(false);
      addTearDown(h.dispose);
      await tester.pumpWidget(
        await h.app('monthly_reflection', AppTheme.lightTheme, 1),
      );
      await tester.pumpAndSettle();

      final hint = find.text('Chọn mức độ hài lòng để lưu chiêm nghiệm.');
      await tester.scrollUntilVisible(
        hint,
        300,
        scrollable: find
            .descendant(
              of: find.byType(SingleChildScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(hint, findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, '4'));
      await tester.pumpAndSettle();
      expect(hint, findsNothing);
      expect(find.text('Lưu chiêm nghiệm'), findsOneWidget);
    });
  });

  test('the reflection route exists for notification taps', () {
    expect(AppRoutes.reflection, '/reflection');
    expect(appNavigatorKey, isNotNull);
  });
}
