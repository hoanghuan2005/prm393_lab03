import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/models/app_notification_item.dart';
import 'package:prm393_lab03/services/notification_history_store.dart';

import 'support/in_memory_notification_history_store.dart';

AppNotificationItem _item(String id, DateTime receivedAt, {String? title}) =>
    AppNotificationItem(
      id: id,
      title: title ?? 'Tin $id',
      body: '',
      receivedAt: receivedAt,
      data: const {'type': 'review'},
      source: NotificationSource.foreground,
    );

void main() {
  final base = DateTime(2026, 11, 2, 9);

  group('parseHistory', () {
    test('null, empty or broken JSON → empty list', () {
      expect(parseHistory(null), isEmpty);
      expect(parseHistory(''), isEmpty);
      expect(parseHistory('{not json'), isEmpty);
      expect(parseHistory('{"id": "a"}'), isEmpty);
    });

    test('skips broken items, keeps the rest', () {
      final good = _item('a', base);
      final raw = jsonEncode([
        good.toJson(),
        {'title': 'thiếu id', 'receivedAt': 1},
        'not a map',
        {'id': 'b', 'receivedAt': 'hôm qua'},
      ]);
      final items = parseHistory(raw);
      expect(items, hasLength(1));
      expect(items.single.id, 'a');
      expect(items.single.receivedAt.isAtSameMomentAs(base), isTrue);
    });

    test('duplicate ids in stored data → only the first one kept', () {
      final raw = jsonEncode([
        _item('a', base, title: 'Bản đầu').toJson(),
        _item('b', base.add(const Duration(hours: 1))).toJson(),
        _item(
          'a',
          base.add(const Duration(hours: 2)),
          title: 'Bản sau',
        ).toJson(),
      ]);
      final items = parseHistory(raw);
      expect(items.map((e) => e.id), ['b', 'a']);
      expect(items.last.title, 'Bản đầu');
    });

    test('stored data out of order → sorted newest first', () {
      final raw = jsonEncode([
        _item('a', base).toJson(),
        _item('c', base.add(const Duration(hours: 2))).toJson(),
        _item('b', base.add(const Duration(hours: 1))).toJson(),
      ]);
      expect(parseHistory(raw).map((e) => e.id), ['c', 'b', 'a']);
    });

    test('60 stored items → the 50 newest', () {
      final raw = jsonEncode([
        for (var i = 0; i < 60; i++)
          _item('n$i', base.add(Duration(minutes: i))).toJson(),
      ]);
      final items = parseHistory(raw);
      expect(items, hasLength(maxNotificationHistory));
      expect(items.first.id, 'n59');
      expect(items.last.id, 'n10');
    });
  });

  group('mergeHistory', () {
    test('adds a new item, newest first', () {
      final older = _item('a', base);
      final newer = _item('b', base.add(const Duration(hours: 1)));
      final (list, added) = mergeHistory([newer], older);
      expect(added, isTrue);
      expect(list.map((e) => e.id), ['b', 'a']);

      final newest = _item('c', base.add(const Duration(hours: 2)));
      final (list2, _) = mergeHistory(list, newest);
      expect(list2.map((e) => e.id), ['c', 'b', 'a']);
    });

    test('same id → not added, list unchanged, stored one kept', () {
      final existing = [_item('a', base, title: 'Bản cũ')];
      final (list, added) = mergeHistory(
        existing,
        _item('a', base.add(const Duration(minutes: 5)), title: 'Bản mới'),
      );
      expect(added, isFalse);
      expect(list, same(existing));
      expect(list.single.title, 'Bản cũ');
    });

    test('keeps the 50 newest when the 51st arrives', () {
      var list = <AppNotificationItem>[];
      for (var i = 0; i < maxNotificationHistory; i++) {
        (list, _) = mergeHistory(
          list,
          _item('n$i', base.add(Duration(minutes: i))),
        );
      }
      expect(list, hasLength(50));

      final (full, added) = mergeHistory(
        list,
        _item('n50', base.add(const Duration(minutes: 50))),
      );
      expect(added, isTrue);
      expect(full, hasLength(50));
      expect(full.first.id, 'n50');
      expect(full.last.id, 'n1');
      expect(full.any((e) => e.id == 'n0'), isFalse);
      for (var i = 1; i < full.length; i++) {
        expect(full[i - 1].receivedAt.isAfter(full[i].receivedAt), isTrue);
      }
    });
  });

  group('InMemoryNotificationHistoryStore', () {
    test('add then load, duplicate ignored, clear', () async {
      final store = InMemoryNotificationHistoryStore();
      expect(await store.load(), isEmpty);

      expect(await store.add(_item('a', base)), isTrue);
      expect(
        await store.add(_item('b', base.add(const Duration(hours: 1)))),
        isTrue,
      );
      expect(await store.add(_item('a', base)), isFalse);
      expect((await store.load()).map((e) => e.id), ['b', 'a']);

      await store.clear();
      expect(await store.load(), isEmpty);
    });
  });
}
