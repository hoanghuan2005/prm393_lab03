import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/models/app_notification_item.dart';
import 'package:prm393_lab03/services/notification_service.dart';

void main() {
  group('notificationItemFromMessage', () {
    final sentTime = DateTime(2026, 11, 2, 20, 0);

    test('copies fields; receivedAt is the send time', () {
      final item = notificationItemFromMessage(
        RemoteMessage(
          messageId: 'm1',
          sentTime: sentTime,
          notification: const RemoteNotification(
            title: 'Sắp tới đợt sale',
            body: 'Xem lại danh sách',
          ),
          data: const {'type': 'sale', 'sale_id': '2026-11-11'},
        ),
        NotificationSource.background,
      );
      expect(item.id, 'm1');
      expect(item.title, 'Sắp tới đợt sale');
      expect(item.body, 'Xem lại danh sách');
      expect(item.receivedAt, sentTime);
      expect(item.data, {'type': 'sale', 'sale_id': '2026-11-11'});
      expect(item.source, NotificationSource.background);
    });

    test('no messageId → id from sentTime, else from now', () {
      final fromSent = notificationItemFromMessage(
        RemoteMessage(sentTime: sentTime),
        NotificationSource.tapTerminated,
      );
      expect(fromSent.id, '${sentTime.millisecondsSinceEpoch}');
      expect(fromSent.source, NotificationSource.tapTerminated);

      final before = DateTime.now();
      final fromNow = notificationItemFromMessage(
        const RemoteMessage(),
        NotificationSource.foreground,
      );
      final after = DateTime.now();
      final idMillis = int.parse(fromNow.id);
      expect(
        idMillis,
        inInclusiveRange(
          before.millisecondsSinceEpoch,
          after.millisecondsSinceEpoch,
        ),
      );
      expect(fromNow.receivedAt.isBefore(before), isFalse);
      expect(fromNow.receivedAt.isAfter(after), isFalse);
    });

    test('no notification → default title, empty body', () {
      final item = notificationItemFromMessage(
        const RemoteMessage(messageId: 'm2'),
        NotificationSource.background,
      );
      expect(item.title, 'Thông báo Why I Buy');
      expect(item.body, '');
    });

    test('data values become strings, nulls dropped', () {
      final item = notificationItemFromMessage(
        const RemoteMessage(
          messageId: 'm3',
          data: {'type': 'review', 'count': 2, 'flag': true, 'empty': null},
        ),
        NotificationSource.background,
      );
      expect(item.data, {'type': 'review', 'count': '2', 'flag': 'true'});
    });
  });
}
