import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/buying_motive.dart';
import '../models/ui_state.dart';
import '../models/wishlist_item.dart';
import '../models/wishlist_status.dart';
import '../services/analytics_service.dart';
import '../services/remote_config_service.dart';
import '../services/wishlist_service.dart';

/// ViewModel managing Wishlist items, motive filtering, search, and decisions
class WishlistViewModel extends ChangeNotifier {
  final WishlistService wishlistService;
  final AppAnalyticsService analyticsService;
  final RemoteConfigService remoteConfigService;

  StreamSubscription<List<WishlistItem>>? _itemsSubscription;
  List<WishlistItem> _allItems = [];
  UiState<List<WishlistItem>> _state = const UiInitial();

  BuyingMotive? _selectedMotiveFilter;
  WishlistStatus? _selectedStatusFilter;
  String _searchQuery = '';
  String _currentUserId = '';

  WishlistViewModel({
    required this.wishlistService,
    required this.analyticsService,
    required this.remoteConfigService,
  });

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

  /// Total items currently in psychological cooldown
  int get cooldownCount {
    return _allItems.where((item) => item.isInCooldown).length;
  }

  /// Bind to user's Firestore stream
  void setUserId(String userId) {
    if (_currentUserId == userId && _itemsSubscription != null) return;
    _currentUserId = userId;
    _itemsSubscription?.cancel();

    if (userId.isEmpty) {
      _allItems = [];
      _state = const UiEmpty(
        message: 'Vui lòng đăng nhập để xem danh sách cân nhắc.',
      );
      notifyListeners();
      return;
    }

    _state = const UiLoading();
    notifyListeners();

    _itemsSubscription = wishlistService
        .streamUserItems(userId)
        .listen(
          (items) {
            _allItems = items;
            _updateFilteredState();
          },
          onError: (error) {
            _state = UiError(
              message: 'Không thể tải dữ liệu: $error',
              onRetry: () => setUserId(userId),
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
      analyticsService.logSearch(
        searchTerm: query,
        resultCount: filteredItems.length,
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
      final coolingDays = remoteConfigService.coolingOffDays;
      await wishlistService.addItem(
        userId: _currentUserId,
        title: title,
        priceVnd: price,
        motive: motive,
        url: productUrl,
        coolingOffDays: coolingDays,
      );

      await analyticsService.logAddToWishlist(
        motive: motive.key,
        price: price,
        hasSaleDate: motive.relatesToSales,
      );
      return true;
    } catch (e) {
      debugPrint('WishlistViewModel addItem error: $e');
      return false;
    }
  }

  /// Update decision (Buy / Wait / Drop)
  Future<bool> updateDecision({
    required String itemId,
    required WishlistStatus status,
    required BuyingMotive motive,
    required int? price,
    String? note,
  }) async {
    try {
      await wishlistService.updateItemStatus(
        itemId: itemId,
        newStatus: status,
        note: note,
      );

      final savedAmount = status == WishlistStatus.skipped ? (price ?? 0) : 0;
      await analyticsService.logMakeDecision(
        action: status.key,
        motive: motive.key,
        savedAmount: savedAmount,
      );
      return true;
    } catch (e) {
      debugPrint('WishlistViewModel updateDecision error: $e');
      return false;
    }
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
