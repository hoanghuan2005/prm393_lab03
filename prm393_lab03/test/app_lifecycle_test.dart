import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/app/app.dart';
import 'package:prm393_lab03/app/app_lifecycle_bridge.dart';
import 'package:prm393_lab03/models/app_notification_item.dart';
import 'package:prm393_lab03/services/notification_service.dart';
import 'package:prm393_lab03/services/review_reminder_service.dart';
import 'package:provider/provider.dart';

import 'support/in_memory_notification_history_store.dart';

/// Counts system notifications; any other call fails the test
class _CountingReminders implements ReviewReminderService {
  int immediateCalls = 0;

  @override
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async => immediateCalls++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Bridge inside a MaterialApp wired to [appScaffoldMessengerKey], as in WhyIBuyApp
Widget _app(NotificationService service, {ReviewReminderService? reminders}) =>
    MultiProvider(
      providers: [
        Provider<NotificationService>.value(value: service),
        if (reminders != null)
          Provider<ReviewReminderService>.value(value: reminders),
      ],
      child: AppLifecycleBridge(
        child: MaterialApp(
          scaffoldMessengerKey: appScaffoldMessengerKey,
          home: const Scaffold(body: SizedBox()),
        ),
      ),
    );

void main() {
  group('FCM message while the app is open → SnackBar', () {
    late InMemoryNotificationHistoryStore store;
    late NotificationService service;
    var saleReminders = true;

    setUp(() {
      saleReminders = true;
      store = InMemoryNotificationHistoryStore();
      service = NotificationService(
        historyStore: store,
        saleRemindersEnabled: () => saleReminders,
      );
    });

    Future<void> receive(
      WidgetTester tester,
      String id,
      Map<String, dynamic> data,
    ) async {
      await tester.runAsync(
        () => service.handleForegroundMessage(
          RemoteMessage(
            messageId: id,
            notification: const RemoteNotification(
              title: 'Đến hẹn xem lại',
              body: 'Có 2 món đang chờ bạn xem lại',
            ),
            data: data,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));
    }

    testWidgets('known type → title, body and "Xem"', (tester) async {
      await tester.pumpWidget(_app(service));
      await receive(tester, 'r1', {'type': 'review'});

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Đến hẹn xem lại'), findsOneWidget);
      expect(find.text('Có 2 món đang chờ bạn xem lại'), findsOneWidget);
      expect(find.widgetWithText(SnackBarAction, 'Xem'), findsOneWidget);
      expect(service.receivedNotifications.single.id, 'r1');
    });

    testWidgets('no type → SnackBar without "Xem"', (tester) async {
      await tester.pumpWidget(_app(service));
      await receive(tester, 'n1', {});

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Đến hẹn xem lại'), findsOneWidget);
      expect(find.byType(SnackBarAction), findsNothing);
    });

    testWidgets('SnackBar only, no duplicate system notification', (
      tester,
    ) async {
      final reminders = _CountingReminders();
      await tester.pumpWidget(_app(service, reminders: reminders));
      await receive(tester, 'd1', {'type': 'review'});

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Đến hẹn xem lại'), findsOneWidget);
      expect(reminders.immediateCalls, 0);
    });

    testWidgets('sale with sale_reminder_enabled off → no SnackBar', (
      tester,
    ) async {
      saleReminders = false;
      await tester.pumpWidget(_app(service));
      await receive(tester, 's1', {'type': 'sale'});

      expect(find.byType(SnackBar), findsNothing);
      // Still stored, only hidden
      expect(service.receivedNotifications, isEmpty);
      final stored = await tester.runAsync(store.load);
      expect(stored!.single.id, 's1');
    });
  });

  testWidgets('resume reloads messages saved while in the background', (
    tester,
  ) async {
    final store = InMemoryNotificationHistoryStore();
    final service = NotificationService(historyStore: store);
    await tester.pumpWidget(
      Provider<NotificationService>.value(
        value: service,
        child: const AppLifecycleBridge(child: SizedBox()),
      ),
    );
    expect(service.receivedNotifications, isEmpty);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    // Saved by the background isolate, not through the service
    await store.add(
      AppNotificationItem(
        id: 'bg1',
        title: 'Tin nền',
        body: '',
        receivedAt: DateTime(2026, 11, 2, 20),
        data: const {'type': 'review'},
        source: NotificationSource.background,
      ),
    );
    expect(service.receivedNotifications, isEmpty);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(service.receivedNotifications.single.id, 'bg1');
  });

  testWidgets('listener is removed with the widget', (tester) async {
    final store = InMemoryNotificationHistoryStore();
    final service = NotificationService(historyStore: store);
    await tester.pumpWidget(
      Provider<NotificationService>.value(
        value: service,
        child: const AppLifecycleBridge(child: SizedBox()),
      ),
    );
    await tester.pumpWidget(const SizedBox());

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await store.add(
      AppNotificationItem(
        id: 'bg2',
        title: 'Tin nền',
        body: '',
        receivedAt: DateTime(2026, 11, 2, 21),
        data: const {},
        source: NotificationSource.background,
      ),
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(service.receivedNotifications, isEmpty);
  });
}
