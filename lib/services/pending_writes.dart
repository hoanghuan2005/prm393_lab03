import 'package:flutter/foundation.dart';

/// Writes already applied to the local Firestore cache that the server has not confirmed
/// yet (offline). The app shows "đang chờ mạng" while [count] > 0; Firestore syncs them
/// by itself when the connection returns.
class PendingWrites extends ChangeNotifier {
  PendingWrites._();

  static final PendingWrites instance = PendingWrites._();

  int _count = 0;

  /// Writes tracked before the last [reset] no longer change [count]
  int _generation = 0;

  int get count => _count;
  bool get hasPending => _count > 0;

  void track(Future<void> write) {
    final generation = _generation;
    _count++;
    notifyListeners();
    write
        .catchError((Object e) {
          // Rejected after reconnecting (e.g. rules); the screen already moved on
          debugPrint('Pending write failed after sync: $e');
        })
        .whenComplete(() {
          if (generation != _generation) return;
          _count--;
          notifyListeners();
        });
  }

  /// Account changed: the old account's queue is not this user's to show
  void reset() {
    _generation++;
    if (_count == 0) return;
    _count = 0;
    notifyListeners();
  }
}
