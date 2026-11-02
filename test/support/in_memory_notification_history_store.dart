import 'package:prm393_lab03/models/app_notification_item.dart';
import 'package:prm393_lab03/services/notification_history_store.dart';

/// Test double with the same merge rules as the SharedPreferences store
class InMemoryNotificationHistoryStore implements NotificationHistoryStore {
  List<AppNotificationItem> _items = [];

  @override
  Future<List<AppNotificationItem>> load() async => List.of(_items);

  @override
  Future<bool> add(AppNotificationItem item) async {
    final (merged, added) = mergeHistory(_items, item);
    _items = merged;
    return added;
  }

  @override
  Future<void> clear() async => _items = [];
}
