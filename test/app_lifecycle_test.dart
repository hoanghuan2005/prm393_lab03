import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/app/app_lifecycle_bridge.dart';
import 'package:prm393_lab03/models/app_notification_item.dart';
import 'package:prm393_lab03/services/notification_service.dart';
import 'package:provider/provider.dart';

import 'support/in_memory_notification_history_store.dart';

void main() {
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
