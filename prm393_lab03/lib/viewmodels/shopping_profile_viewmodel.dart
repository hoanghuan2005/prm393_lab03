import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/owned_item.dart';
import '../models/ui_state.dart';
import '../services/crashlytics_service.dart';
import '../services/shopping_profile_service.dart';
import 'deferred_notify.dart';
import 'error_reporting.dart';

/// "Hồ sơ mua sắm" (screen 24, spec 7.2): things the user owns, style and brands.
/// Owned items feed the Decision Card (S5) and the duplicate hint.
class ShoppingProfileViewModel extends ChangeNotifier
    with DeferredNotify, ErrorReporting {
  final ShoppingProfileService service;
  @override
  final CrashlyticsService? crashlyticsService;

  String? _uid;
  StreamSubscription<List<OwnedItem>>? _itemsSubscription;
  StreamSubscription<ShoppingTags>? _tagsSubscription;
  UiState<List<OwnedItem>> _state = const UiInitial();
  List<OwnedItem> _ownedItems = const [];
  ShoppingTags _tags = const ShoppingTags();
  String? _actionError;

  ShoppingProfileViewModel({required this.service, this.crashlyticsService});

  UiState<List<OwnedItem>> get state => _state;
  List<OwnedItem> get ownedItems => _ownedItems;
  ShoppingTags get tags => _tags;
  String? get actionError => _actionError;

  void updateUid(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _itemsSubscription?.cancel();
    _tagsSubscription?.cancel();
    _ownedItems = const [];
    _tags = const ShoppingTags();
    if (uid == null) {
      _state = const UiInitial();
      notifyLater();
      return;
    }
    _state = const UiLoading();
    notifyLater();
    _itemsSubscription = service
        .watchOwnedItems(uid)
        .listen(
          (items) {
            _ownedItems = items;
            _state = UiSuccess(items);
            notifyListeners();
          },
          onError: (Object e, StackTrace stack) {
            _state = UiError(
              message: messageFor(e, stack, reason: 'watchOwnedItems'),
              onRetry: () => _retry(uid),
            );
            notifyListeners();
          },
        );
    _tagsSubscription = service.watchTags(uid).listen((tags) {
      _tags = tags;
      notifyListeners();
    }, onError: (Object e) => debugPrint('Shopping tags unavailable: $e'));
  }

  void _retry(String uid) {
    _uid = null;
    updateUid(uid);
  }

  /// Owned items in the same group as, or tagged like, an item being considered (S5)
  List<OwnedItem> matchesFor({required String title, String? budgetGroupId}) =>
      [
        for (final o in _ownedItems)
          if (o.matches(title: title, budgetGroupId: budgetGroupId)) o,
      ];

  Future<bool> _write(
    Future<void> Function(String uid) write,
    String reason,
  ) async {
    final uid = _uid;
    if (uid == null) {
      _actionError = 'Vui lòng đăng nhập để lưu hồ sơ.';
      return false;
    }
    try {
      await write(uid);
      _actionError = null;
      return true;
    } catch (e, stack) {
      _actionError = messageFor(e, stack, reason: reason);
      return false;
    }
  }

  Future<bool> saveOwnedItem({
    String id = '',
    required String name,
    String? budgetGroupId,
    required String tagsText,
    String? note,
    DateTime? createdAt,
  }) => _write(
    (uid) => service.saveOwnedItem(
      uid,
      OwnedItem(
        id: id,
        name: name,
        budgetGroupId: budgetGroupId,
        tags: OwnedItem.parseTags(tagsText),
        note: note,
        createdAt: createdAt ?? DateTime.now(),
      ),
    ),
    'saveOwnedItem',
  );

  Future<bool> deleteOwnedItem(OwnedItem item) =>
      _write((uid) => service.deleteOwnedItem(uid, item.id), 'deleteOwnedItem');

  Future<bool> saveTags({
    required String stylesText,
    required String brandsText,
  }) => _write(
    (uid) => service.saveTags(
      uid,
      ShoppingTags(
        styles: OwnedItem.parseTags(stylesText),
        brands: OwnedItem.parseTags(brandsText),
      ),
    ),
    'saveShoppingTags',
  );

  @override
  void dispose() {
    _itemsSubscription?.cancel();
    _tagsSubscription?.cancel();
    super.dispose();
  }
}
