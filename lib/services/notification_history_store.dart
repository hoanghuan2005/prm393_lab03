import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification_item.dart';

/// Most notifications kept on the device
const int maxNotificationHistory = 50;

/// What [mergeHistory] / [NotificationHistoryStore.add] did with an item
enum HistoryChange {
  /// New id, inserted
  added,

  /// Id already stored; the stored item was marked as opened
  updated,

  /// Id already stored and nothing changed (or the write failed)
  unchanged,
}

/// On-device history of received push notifications ("Thông báo đã nhận").
/// Implementations never throw: they may run in the background isolate,
/// where Crashlytics is not available.
abstract interface class NotificationHistoryStore {
  /// Newest first
  Future<List<AppNotificationItem>> load();

  /// See [mergeHistory]. [HistoryChange.unchanged] also when the write failed.
  Future<HistoryChange> add(AppNotificationItem item);

  Future<void> clear();
}

/// Reads a stored JSON list and normalizes it, since stored data may be old or edited:
/// broken items skipped, duplicate ids dropped (first one kept), newest first, at most
/// [maxNotificationHistory]. Broken JSON gives an empty list.
List<AppNotificationItem> parseHistory(String? raw) {
  if (raw == null || raw.isEmpty) return [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    final seenIds = <String>{};
    final items = [
      for (final entry in decoded)
        if (entry is Map<String, dynamic>)
          ?AppNotificationItem.tryFromJson(entry),
    ].where((item) => seenIds.add(item.id)).toList();
    items.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return items.take(maxNotificationHistory).toList();
  } catch (e) {
    debugPrint('NotificationHistory: unreadable history: $e');
    return [];
  }
}

/// Adds [item] unless its id is already in [existing] (the stored one wins).
/// Result is newest first and at most [max] long.
/// Same id: when [item] is a tap and the stored one was never opened, the stored one
/// is replaced in place by a copy marked opened ([now], default the current time);
/// otherwise nothing changes.
/// Assumes [existing] is already normalized (it comes from [parseHistory]): on a
/// duplicate id it is not re-sorted, and when unchanged it is returned as is.
(List<AppNotificationItem>, HistoryChange) mergeHistory(
  List<AppNotificationItem> existing,
  AppNotificationItem item, {
  int max = maxNotificationHistory,
  DateTime? now,
}) {
  final index = existing.indexWhere((e) => e.id == item.id);
  if (index >= 0) {
    final stored = existing[index];
    if (!item.source.isTap || stored.openedVia != null) {
      return (existing, HistoryChange.unchanged);
    }
    final updated = List.of(existing)
      ..[index] = stored.markOpened(item.source, now ?? DateTime.now());
    return (updated, HistoryChange.updated);
  }
  final merged = [item, ...existing]
    ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
  return (merged.take(max).toList(), HistoryChange.added);
}

/// Stored as one JSON string under [storageKey]. Uses [SharedPreferencesAsync]
/// (no per-isolate cache), so items written by the background handler show up
/// in the main app.
class SharedPrefsNotificationHistoryStore implements NotificationHistoryStore {
  static const String storageKey = 'fcm_history_v1';

  /// Injected for testing; otherwise created on first use
  final SharedPreferencesAsync? _injectedPrefs;
  late final SharedPreferencesAsync _store =
      _injectedPrefs ?? SharedPreferencesAsync();

  SharedPrefsNotificationHistoryStore({SharedPreferencesAsync? prefs})
    : _injectedPrefs = prefs;

  @override
  Future<List<AppNotificationItem>> load() async {
    try {
      return parseHistory(await _store.getString(storageKey));
    } catch (e) {
      debugPrint('NotificationHistory: load failed: $e');
      return [];
    }
  }

  @override
  Future<HistoryChange> add(AppNotificationItem item) async {
    try {
      final existing = parseHistory(await _store.getString(storageKey));
      final (merged, change) = mergeHistory(existing, item);
      if (change == HistoryChange.unchanged) return change;
      await _store.setString(
        storageKey,
        jsonEncode([for (final e in merged) e.toJson()]),
      );
      return change;
    } catch (e) {
      debugPrint('NotificationHistory: add failed: $e');
      return HistoryChange.unchanged;
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _store.remove(storageKey);
    } catch (e) {
      debugPrint('NotificationHistory: clear failed: $e');
    }
  }
}
