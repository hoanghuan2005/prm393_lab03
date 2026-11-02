import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/models/app_notification_item.dart';

void main() {
  group('AppNotificationItem JSON', () {
    final receivedAt = DateTime(2026, 11, 2, 20, 15, 30);

    AppNotificationItem item(NotificationSource source) => AppNotificationItem(
      id: 'msg-${source.key}',
      title: 'Sắp tới đợt sale 11.11',
      body: 'Xem lại danh sách cho đợt sale',
      receivedAt: receivedAt,
      data: const {'type': 'sale', 'sale_id': '2026-11-11'},
      source: source,
    );

    test('toJson then tryFromJson keeps every field, all four sources', () {
      for (final source in NotificationSource.values) {
        final original = item(source);
        final json = original.toJson();
        expect(json['receivedAt'], receivedAt.toUtc().millisecondsSinceEpoch);
        expect(json['source'], source.key);

        final restored = AppNotificationItem.tryFromJson(json)!;
        expect(restored.id, original.id);
        expect(restored.title, original.title);
        expect(restored.body, original.body);
        expect(restored.receivedAt.isAtSameMomentAs(receivedAt), isTrue);
        expect(restored.data, original.data);
        expect(restored.source, source);
      }
    });

    test('stored keys are fixed', () {
      expect(NotificationSource.values.map((s) => s.key), [
        'foreground',
        'background',
        'tap_background',
        'tap_terminated',
      ]);
    });

    test('unknown or missing source key → background', () {
      expect(NotificationSource.fromKey('push'), NotificationSource.background);
      expect(NotificationSource.fromKey(null), NotificationSource.background);
      expect(NotificationSource.fromKey(3), NotificationSource.background);

      final json = item(NotificationSource.tapTerminated).toJson()
        ..['source'] = 'push';
      expect(
        AppNotificationItem.tryFromJson(json)!.source,
        NotificationSource.background,
      );
    });

    test('missing id or bad receivedAt → null, never throws', () {
      Map<String, dynamic> base() =>
          item(NotificationSource.foreground).toJson();

      expect(AppNotificationItem.tryFromJson(base()..remove('id')), isNull);
      expect(AppNotificationItem.tryFromJson(base()..['id'] = ''), isNull);
      expect(AppNotificationItem.tryFromJson(base()..['id'] = 42), isNull);
      expect(
        AppNotificationItem.tryFromJson(base()..remove('receivedAt')),
        isNull,
      );
      expect(
        AppNotificationItem.tryFromJson(base()..['receivedAt'] = '2026-11-02'),
        isNull,
      );
      expect(
        AppNotificationItem.tryFromJson(base()..['receivedAt'] = 1.5),
        isNull,
      );
      // Outside DateTime's range
      expect(
        AppNotificationItem.tryFromJson(
          base()..['receivedAt'] = 9007199254740991,
        ),
        isNull,
      );
      expect(AppNotificationItem.tryFromJson(const {}), isNull);
    });

    test('other broken fields fall back instead of failing', () {
      final json = item(NotificationSource.foreground).toJson()
        ..['title'] = null
        ..['body'] = 7
        ..['data'] = 'not a map';
      final restored = AppNotificationItem.tryFromJson(json)!;
      expect(restored.title, '');
      expect(restored.body, '');
      expect(restored.data, isEmpty);

      final mixed = AppNotificationItem.tryFromJson(
        item(NotificationSource.foreground).toJson()
          ..['data'] = {'type': 'review', 'count': 2, 'empty': null},
      )!;
      expect(mixed.data, {'type': 'review', 'count': '2'});
    });
  });
}
