import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/models/app_notification_item.dart';
import 'package:prm393_lab03/services/notification_history_store.dart';

import 'support/in_memory_notification_history_store.dart';

AppNotificationItem _item(
  String id,
  DateTime receivedAt, {
  String? title,
  NotificationSource source = NotificationSource.foreground,
}) => AppNotificationItem(
  id: id,
  title: title ?? 'Tin $id',
  body: '',
  receivedAt: receivedAt,
  data: const {'type': 'review'},
  source: source,
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
      final (list, change) = mergeHistory([newer], older);
      expect(change, HistoryChange.added);
      expect(list.map((e) => e.id), ['b', 'a']);

      final newest = _item('c', base.add(const Duration(hours: 2)));
      final (list2, _) = mergeHistory(list, newest);
      expect(list2.map((e) => e.id), ['c', 'b', 'a']);
    });

    test('same id → not added, list unchanged, stored one kept', () {
      final existing = [_item('a', base, title: 'Bản cũ')];
      final (list, change) = mergeHistory(
        existing,
        _item('a', base.add(const Duration(minutes: 5)), title: 'Bản mới'),
      );
      expect(change, HistoryChange.unchanged);
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

      final (full, change) = mergeHistory(
        list,
        _item('n50', base.add(const Duration(minutes: 50))),
      );
      expect(change, HistoryChange.added);
      expect(full, hasLength(50));
      expect(full.first.id, 'n50');
      expect(full.last.id, 'n1');
      expect(full.any((e) => e.id == 'n0'), isFalse);
      for (var i = 1; i < full.length; i++) {
        expect(full[i - 1].receivedAt.isAfter(full[i].receivedAt), isTrue);
      }
    });
  });

  group('Tapped notifications (openedVia)', () {
    final background = _item('x', base, source: NotificationSource.background);
    final other = _item(
      'y',
      base.add(const Duration(hours: 1)),
      source: NotificationSource.foreground,
    );
    final tappedAt = DateTime(2026, 11, 2, 21);

    test('tap on a stored background message marks it, in place', () {
      final (list, change) = mergeHistory(
        [other, background],
        _item(
          'x',
          base.add(const Duration(minutes: 1)),
          source: NotificationSource.tapBackground,
        ),
        now: tappedAt,
      );
      expect(change, HistoryChange.updated);
      expect(list.map((e) => e.id), ['y', 'x']);
      final marked = list.last;
      expect(marked.source, NotificationSource.background);
      expect(marked.openedVia, NotificationSource.tapBackground);
      expect(marked.openedAt, tappedAt);
      expect(marked.receivedAt, base);
      expect(marked.title, background.title);
    });

    test('second tap keeps the first openedAt', () {
      final (once, _) = mergeHistory(
        [background],
        _item('x', base, source: NotificationSource.tapBackground),
        now: tappedAt,
      );
      final (twice, change) = mergeHistory(
        once,
        _item('x', base, source: NotificationSource.tapTerminated),
        now: tappedAt.add(const Duration(hours: 1)),
      );
      expect(change, HistoryChange.unchanged);
      expect(twice, same(once));
      expect(twice.single.openedAt, tappedAt);
      expect(twice.single.openedVia, NotificationSource.tapBackground);
    });

    test('tap on a message never stored → added with that source', () {
      final (list, change) = mergeHistory([
        other,
      ], _item('z', base, source: NotificationSource.tapTerminated));
      expect(change, HistoryChange.added);
      final added = list.singleWhere((e) => e.id == 'z');
      expect(added.source, NotificationSource.tapTerminated);
      expect(added.openedVia, isNull);
      expect(added.openedAt, isNull);
    });

    test('openedVia / openedAt survive JSON; old JSON without them reads', () {
      final marked = background.markOpened(
        NotificationSource.tapTerminated,
        tappedAt,
      );
      final restored = parseHistory(jsonEncode([marked.toJson()])).single;
      expect(restored.openedVia, NotificationSource.tapTerminated);
      expect(restored.openedAt!.isAtSameMomentAs(tappedAt), isTrue);

      final oldJson = {
        'id': 'old',
        'title': 'Tin cũ',
        'body': '',
        'receivedAt': base.toUtc().millisecondsSinceEpoch,
        'data': {'type': 'review'},
        'source': 'background',
      };
      final old = AppNotificationItem.tryFromJson(oldJson)!;
      expect(old.id, 'old');
      expect(old.openedVia, isNull);
      expect(old.openedAt, isNull);
      expect(background.toJson().containsKey('openedVia'), isFalse);

      // Not a tap source → treated as not opened
      final bad = AppNotificationItem.tryFromJson({
        ...oldJson,
        'openedVia': 'foreground',
        'openedAt': 1,
      })!;
      expect(bad.openedVia, isNull);
      expect(bad.openedAt, isNull);
    });
  });

  group('InMemoryNotificationHistoryStore', () {
    test('add then load, duplicate ignored, clear', () async {
      final store = InMemoryNotificationHistoryStore();
      expect(await store.load(), isEmpty);

      expect(await store.add(_item('a', base)), HistoryChange.added);
      expect(
        await store.add(_item('b', base.add(const Duration(hours: 1)))),
        HistoryChange.added,
      );
      expect(await store.add(_item('a', base)), HistoryChange.unchanged);
      expect((await store.load()).map((e) => e.id), ['b', 'a']);

      await store.clear();
      expect(await store.load(), isEmpty);
    });
  });
}
