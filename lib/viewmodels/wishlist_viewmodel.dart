import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/buying_motive.dart';
import '../models/ui_state.dart';
import '../models/wishlist_item.dart';
import '../models/wishlist_status.dart';
import '../services/analytics_events.dart';
import '../services/analytics_service.dart';
import '../services/crashlytics_service.dart';
import '../services/review_reminder_service.dart';
import '../services/wishlist_service.dart';
import 'deferred_notify.dart';
import 'error_reporting.dart';

/// Result of asking for notification permission after "Chờ"
enum ReminderPermission { granted, denied, unsupported }

/// ViewModel managing Wishlist items, motive filtering, search, and decisions
class WishlistViewModel extends ChangeNotifier
    with DeferredNotify, ErrorReporting {
  final WishlistService wishlistService;
  final AppAnalyticsService analyticsService;
  @override
  final CrashlyticsService? crashlyticsService;

  /// Local "Đến hẹn xem lại" notifications; null in tests that do not need them
  final ReviewReminderService? reminderService;

  StreamSubscription<List<WishlistItem>>? _itemsSubscription;
  List<WishlistItem> _allItems = [];
  UiState<List<WishlistItem>> _state = const UiInitial();

  BuyingMotive? _selectedMotiveFilter;
  WishlistStatus? _selectedStatusFilter;
  bool _reviewDueOnly = false;
  String _searchQuery = '';
  String? _uid;

  /// itemId → review date currently scheduled as a notification
  final Map<String, DateTime> _scheduledReminders = {};
  bool _remindersSynced = false;

  /// From SettingsViewModel: user setting, else Remote Config
  int _coolingOffDays = 3;

  /// Message of the last failed add / decision, for a SnackBar
  String? _actionError;

  WishlistViewModel({
    required this.wishlistService,
    required this.analyticsService,
    this.crashlyticsService,
    this.reminderService,
  });

  String? get actionError => _actionError;

  int get coolingOffDays => _coolingOffDays;

  void updateCoolingOffDays(int days) => _coolingOffDays = days;

  /// Remote Config `max_wishlist_items_shown`: items listed before "Xem thêm"
  int _maxShown = 20;
  bool _showAll = false;
  bool _disposed = false;

  int get maxShown => _maxShown;

  /// Fed by the ProxyProvider during build, so the redraw is deferred
  void updateMaxShown(int value) {
    final next = value < 1 ? 1 : value;
    if (next == _maxShown) return;
    _maxShown = next;
    Future.microtask(() {
      if (!_disposed) notifyListeners();
    });
  }

  /// The part of [items] the list shows; all of it after "Xem thêm"
  List<WishlistItem> visibleOf(List<WishlistItem> items) =>
      _showAll || items.length <= _maxShown
      ? items
      : items.sublist(0, _maxShown);

  void showAllItems() {
    _showAll = true;
    notifyListeners();
  }

  /// Sale reminder tapped: the items still being considered, nothing else filtered
  void showConsidering() {
    _searchQuery = '';
    _selectedMotiveFilter = null;
    _reviewDueOnly = false;
    _selectedStatusFilter = WishlistStatus.considering;
    _showAll = false;
    _updateFilteredState();
  }

  UiState<List<WishlistItem>> get state => _state;
  BuyingMotive? get selectedMotiveFilter => _selectedMotiveFilter;
  WishlistStatus? get selectedStatusFilter => _selectedStatusFilter;
  String get searchQuery => _searchQuery;
  List<WishlistItem> get allItems => List.unmodifiable(_allItems);

  /// "Cần xem lại": the review date chosen with "Chờ" has arrived (also the fallback
  /// when notifications are off or unsupported)
  List<WishlistItem> get reviewDueItems =>
      _allItems.where((i) => i.isReviewDue).toList();
  int get reviewDueCount => reviewDueItems.length;
  bool get reviewDueOnly => _reviewDueOnly;

  /// Filtered items based on active motive, status, and search query
  List<WishlistItem> get filteredItems {
    return _allItems.where((item) {
      if (_reviewDueOnly && !item.isReviewDue) return false;
      if (_selectedMotiveFilter != null &&
          item.motive != _selectedMotiveFilter) {
        return false;
      }
      if (_selectedStatusFilter != null &&
          item.status != _selectedStatusFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = item.title.toLowerCase().contains(query);
        final matchesMotive = item.displayMotive.label.toLowerCase().contains(
          query,
        );
        return matchesTitle || matchesMotive;
      }
      return true;
    }).toList();
  }

  /// Total money saved by dropping impulse purchases
  int get totalSavedAmount {
    return _allItems
        .where((item) => item.status == WishlistStatus.skipped)
        .fold(0, (sum, item) => sum + (item.latestPriceVnd ?? 0));
  }

  /// Items still being considered (shown on Trang chủ)
  int get consideringCount =>
      _allItems.where((i) => i.status == WishlistStatus.considering).length;

  /// Total items currently in psychological cooldown
  int get cooldownCount {
    return _allItems.where((item) => item.isInCooldown).length;
  }

  /// Called by the provider whenever the signed-in user changes
  void updateUid(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _itemsSubscription?.cancel();
    _itemsSubscription = null;
    _allItems = [];
    _selectedMotiveFilter = null;
    _selectedStatusFilter = null;
    _reviewDueOnly = false;
    _searchQuery = '';
    // Reminders belong to the previous account
    _scheduledReminders.clear();
    _remindersSynced = false;
    unawaited(reminderService?.cancelAll() ?? Future<void>.value());

    if (uid == null) {
      _state = const UiInitial();
      notifyLater();
      return;
    }

    _state = const UiLoading();
    notifyLater();

    _itemsSubscription = wishlistService
        .watchItems(uid)
        .listen(
          (items) {
            _allItems = items;
            unawaited(_syncReminders(items));
            _updateFilteredState();
          },
          onError: (Object error, StackTrace stack) {
            _state = UiError(
              message: messageFor(error, stack, reason: 'watchItems'),
              onRetry: () {
                _uid = null;
                updateUid(uid);
              },
            );
            notifyListeners();
          },
        );
  }

  /// Set search query and log analytics event
  void setSearchQuery(String query) {
    _searchQuery = query;
    _showAll = false;
    _updateFilteredState();

    if (query.trim().isNotEmpty) {
      unawaited(
        analyticsService.logSearch(
          queryLength: query.trim().length,
          resultCount: filteredItems.length,
        ),
      );
    }
  }

  /// Toggle motive filter
  void setMotiveFilter(BuyingMotive? motive) {
    _selectedMotiveFilter = (_selectedMotiveFilter == motive) ? null : motive;
    _showAll = false;
    _updateFilteredState();
  }

  /// Show only items whose review date has arrived
  void setReviewDueFilter(bool enabled) {
    _reviewDueOnly = enabled;
    _showAll = false;
    _updateFilteredState();
  }

  /// Keeps one notification per waiting item, whatever changed the item (this screen,
  /// a purchase, a delete, another device): schedule new dates, cancel the rest.
  Future<void> _syncReminders(List<WishlistItem> items) async {
    final reminders = reminderService;
    if (reminders == null || !reminders.isSupported) return;
    if (!_remindersSynced) {
      // Drop notifications left over from items deleted while the app was closed
      _remindersSynced = true;
      await reminders.cancelAll();
    }
    final waiting = {
      for (final item in items)
        if (item.isWaiting) item.id: item,
    };
    for (final id in _scheduledReminders.keys.toList()) {
      if (!waiting.containsKey(id)) {
        _scheduledReminders.remove(id);
        await reminders.cancel(id);
      }
    }
    for (final item in waiting.values) {
      if (_scheduledReminders[item.id] == item.reviewAt) continue;
      _scheduledReminders[item.id] = item.reviewAt!;
      await reminders.schedule(
        itemId: item.id,
        title: item.title,
        at: item.reviewAt!,
      );
    }
  }

  /// Asked right after the user chose "Chờ", never on app start
  Future<ReminderPermission> requestReminderPermission() async {
    final reminders = reminderService;
    if (reminders == null || !reminders.isSupported) {
      return ReminderPermission.unsupported;
    }
    return await reminders.requestPermission()
        ? ReminderPermission.granted
        : ReminderPermission.denied;
  }

  /// Toggle status filter
  void setStatusFilter(WishlistStatus? status) {
    _selectedStatusFilter = (_selectedStatusFilter == status) ? null : status;
    _showAll = false;
    _updateFilteredState();
  }

  /// Add new item
  Future<bool> addItem({
    required String title,
    required int? price,
    required BuyingMotive motive,
    String? productUrl,
    String? budgetGroupId,
    int priority = WishlistItem.defaultPriority,
  }) async {
    try {
      final uid = _uid;
      if (uid == null) {
        _actionError = 'Vui lòng đăng nhập để lưu món.';
        return false;
      }
      await wishlistService.add(
        uid,
        title: title,
        priceVnd: price,
        motive: motive,
        url: productUrl,
        budgetGroupId: budgetGroupId,
        priority: priority,
        coolingOffDays: _coolingOffDays,
      );

      unawaited(
        analyticsService.logAddToWishlist(motive: motive.key, priceVnd: price),
      );
      _actionError = null;
      return true;
    } catch (e, stack) {
      _actionError = messageFor(e, stack, reason: 'addItem');
      return false;
    }
  }

  // "Mua" is not here on purpose: an item only becomes purchased through
  // PurchaseViewModel.addPurchase(fromWishlist:), which also records the expense.

  /// "Chờ": keeps the item in "Đang cân nhắc" and schedules a review on [reviewAt]
  Future<bool> wait(WishlistItem item, DateTime reviewAt) => _writeItem(
    item,
    (uid) => wishlistService.setReview(uid, item.id, reviewAt),
    analyticsDecision: AnalyticsDecisions.wait,
    reason: 'wait',
  );

  /// "Bỏ qua"; the screen offers [reconsider] as a 5-second undo
  Future<bool> skip(WishlistItem item) => _writeItem(
    item,
    (uid) => wishlistService.skip(uid, item.id),
    analyticsDecision: AnalyticsDecisions.skip,
    reason: 'skip',
  );

  /// Undo of "Bỏ qua" and "Cân nhắc lại" later on: back to "Đang cân nhắc"
  Future<bool> reconsider(WishlistItem item) => _writeItem(
    item,
    (uid) => wishlistService.undoSkip(uid, item.id),
    reason: 'reconsider',
  );

  /// Title, link, motive, budget group and priority. The price is changed with [updatePrice]
  /// so every price keeps its own snapshot and date.
  Future<bool> updateDetails(
    WishlistItem item, {
    required String title,
    String? url,
    BuyingMotive? motive,
    String? budgetGroupId,
    int? priority,
  }) {
    // Built field by field: copyWith cannot clear an optional value such as the link
    final updated = WishlistItem(
      id: item.id,
      title: title.trim(),
      url: url == null || url.trim().isEmpty ? null : url.trim(),
      motive: motive,
      priority: priority ?? item.priority,
      status: item.status,
      cooldownUntil: item.cooldownUntil,
      reviewAt: item.reviewAt,
      budgetGroupId: budgetGroupId,
      latestPriceVnd: item.latestPriceVnd,
      latestPriceAt: item.latestPriceAt,
      saveChannel: item.saveChannel,
      purchaseId: item.purchaseId,
      note: item.note,
      createdAt: item.createdAt,
      decidedAt: item.decidedAt,
      confirmedDuplicate: item.confirmedDuplicate,
    );
    return _writeItem(
      item,
      (uid) => wishlistService.update(uid, updated),
      reason: 'updateDetails',
    );
  }

  /// Decision Card: the user says this item is (not) the same as something they have
  Future<bool> setConfirmedDuplicate(WishlistItem item, bool value) =>
      _writeItem(
        item,
        (uid) => wishlistService.update(
          uid,
          item.copyWith(confirmedDuplicate: value),
        ),
        reason: 'setConfirmedDuplicate',
      );

  /// New price snapshot dated now (also fills in a price that was unknown)
  Future<bool> updatePrice(WishlistItem item, int amountVnd) => _writeItem(
    item,
    (uid) => wishlistService.addPrice(uid, item.id, amountVnd),
    reason: 'updatePrice',
  );

  /// Removes the item and its price history; a purchase made from it stays in Lịch sử
  Future<bool> deleteItem(WishlistItem item) => _writeItem(
    item,
    (uid) => wishlistService.delete(uid, item.id),
    reason: 'deleteItem',
  );

  /// One write on [item]; [actionError] explains a failure
  Future<bool> _writeItem(
    WishlistItem item,
    Future<void> Function(String uid) write, {
    String? analyticsDecision,
    required String reason,
  }) async {
    final uid = _uid;
    if (uid == null) {
      _actionError = 'Vui lòng đăng nhập để lưu thay đổi.';
      return false;
    }
    try {
      await write(uid);
      if (analyticsDecision != null) {
        unawaited(
          analyticsService.logMakeDecision(
            decision: analyticsDecision,
            motive: item.displayMotive.key,
            priceVnd: item.latestPriceVnd,
          ),
        );
      }
      _actionError = null;
      return true;
    } catch (e, stack) {
      _actionError = messageFor(e, stack, reason: reason);
      return false;
    }
  }

  /// Called once when an item's detail screen opens (view_item_detail)
  void onItemViewed(WishlistItem item) {
    unawaited(
      analyticsService.logViewItemDetail(
        motive: item.displayMotive.key,
        daysInCooldown: item.daysSinceCreated,
      ),
    );
  }

  void _updateFilteredState() {
    final list = filteredItems;
    if (list.isEmpty) {
      if (_allItems.isEmpty) {
        _state = const UiEmpty(
          message: 'Chưa có món nào được lưu',
          actionTitle: 'Thêm món đầu tiên',
        );
      } else {
        _state = UiEmpty(
          message: _reviewDueOnly
              ? 'Chưa có món nào đến ngày xem lại'
              : 'Không tìm thấy món nào phù hợp với bộ lọc hiện tại',
        );
      }
    } else {
      _state = UiSuccess(list);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _itemsSubscription?.cancel();
    super.dispose();
  }
}
