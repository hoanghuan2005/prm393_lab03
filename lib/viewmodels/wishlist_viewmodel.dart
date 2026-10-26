import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/buying_motive.dart';
import '../models/ui_state.dart';
import '../models/wishlist_item.dart';
import '../models/wishlist_status.dart';
import '../services/analytics_events.dart';
import '../services/analytics_service.dart';
import '../services/crashlytics_service.dart';
import '../services/wishlist_service.dart';
import 'deferred_notify.dart';
import 'error_reporting.dart';

/// ViewModel managing Wishlist items, motive filtering, search, and decisions
class WishlistViewModel extends ChangeNotifier
    with DeferredNotify, ErrorReporting {
  final WishlistService wishlistService;
  final AppAnalyticsService analyticsService;
  @override
  final CrashlyticsService? crashlyticsService;

  StreamSubscription<List<WishlistItem>>? _itemsSubscription;
  List<WishlistItem> _allItems = [];
  UiState<List<WishlistItem>> _state = const UiInitial();

  BuyingMotive? _selectedMotiveFilter;
  WishlistStatus? _selectedStatusFilter;
  String _searchQuery = '';
  String? _uid;

  /// From SettingsViewModel: user setting, else Remote Config
  int _coolingOffDays = 3;

  /// Message of the last failed add / decision, for a SnackBar
  String? _actionError;

  WishlistViewModel({
    required this.wishlistService,
    required this.analyticsService,
    this.crashlyticsService,
  });

  String? get actionError => _actionError;

  int get coolingOffDays => _coolingOffDays;

  void updateCoolingOffDays(int days) => _coolingOffDays = days;

  UiState<List<WishlistItem>> get state => _state;
  BuyingMotive? get selectedMotiveFilter => _selectedMotiveFilter;
  WishlistStatus? get selectedStatusFilter => _selectedStatusFilter;
  String get searchQuery => _searchQuery;
  List<WishlistItem> get allItems => List.unmodifiable(_allItems);

  /// Filtered items based on active motive, status, and search query
  List<WishlistItem> get filteredItems {
    return _allItems.where((item) {
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
    _searchQuery = '';

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
    _updateFilteredState();
  }

  /// Toggle status filter
  void setStatusFilter(WishlistStatus? status) {
    _selectedStatusFilter = (_selectedStatusFilter == status) ? null : status;
    _updateFilteredState();
  }

  /// Add new item
  Future<bool> addItem({
    required String title,
    required int? price,
    required BuyingMotive motive,
    String? productUrl,
  }) async {
    try {
      final uid = _uid;
      if (uid == null) return false;
      await wishlistService.add(
        uid,
        title: title,
        priceVnd: price,
        motive: motive,
        url: productUrl,
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
  Future<bool> wait(WishlistItem item, DateTime reviewAt) => _decide(
    item,
    (uid) => wishlistService.setReview(uid, item.id, reviewAt),
    analyticsDecision: AnalyticsDecisions.wait,
    reason: 'wait',
  );

  /// "Bỏ qua"; the screen offers [reconsider] as a 5-second undo
  Future<bool> skip(WishlistItem item) => _decide(
    item,
    (uid) => wishlistService.skip(uid, item.id),
    analyticsDecision: AnalyticsDecisions.skip,
    reason: 'skip',
  );

  /// Undo of "Bỏ qua" and "Cân nhắc lại" later on: back to "Đang cân nhắc"
  Future<bool> reconsider(WishlistItem item) => _decide(
    item,
    (uid) => wishlistService.undoSkip(uid, item.id),
    reason: 'reconsider',
  );

  Future<bool> _decide(
    WishlistItem item,
    Future<void> Function(String uid) write, {
    String? analyticsDecision,
    required String reason,
  }) async {
    final uid = _uid;
    if (uid == null) {
      _actionError = 'Vui lòng đăng nhập để lưu quyết định.';
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
        _state = const UiEmpty(
          message: 'Không tìm thấy món nào phù hợp với bộ lọc hiện tại',
        );
      }
    } else {
      _state = UiSuccess(list);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _itemsSubscription?.cancel();
    super.dispose();
  }
}
