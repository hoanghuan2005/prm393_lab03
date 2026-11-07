import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/price_history.dart';

import '../services/crashlytics_service.dart';
import '../services/demo_price_history_service.dart';
import '../services/user_service.dart';
import 'error_reporting.dart';

/// "Dữ liệu giá mẫu" buttons of the Firebase Demo Area; only admins see them.
/// The uid comes from AuthViewModel through a ProxyProvider (updateUid).
class PriceHistoryDemoViewModel extends ChangeNotifier with ErrorReporting {
  final DemoPriceHistoryService demoService;
  final UserService userService;
  @override
  final CrashlyticsService? crashlyticsService;

  PriceHistoryDemoViewModel({
    required this.demoService,
    required this.userService,
    this.crashlyticsService,
  });

  String? _uid;
  StreamSubscription<String>? _roleSubscription;
  bool _isAdmin = false;
  bool _isBusy = false;
  int _done = 0;
  int _total = 0;
  String? _errorMessage;
  List<ProductGroup> _groups = const [];
  bool _disposed = false;

  bool get isAdmin => _isAdmin;
  bool get isBusy => _isBusy;

  /// Documents of the current step (clearing, then writing)
  int get done => _done;
  int get total => _total;
  String? get errorMessage => _errorMessage;

  /// Sample groups to open as a chart (loaded for admins, refreshed after seed / clear)
  List<ProductGroup> get groups => _groups;

  void updateUid(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _roleSubscription?.cancel();
    _roleSubscription = null;
    _setAdmin(false);
    if (uid == null) return;
    _roleSubscription = userService
        .watchRole(uid)
        .listen(
          (role) => _setAdmin(role == 'admin'),
          onError: (_) {
            _setAdmin(false);
          },
        );
  }

  void _setAdmin(bool value) {
    if (value == _isAdmin) return;
    _isAdmin = value;
    if (!value) _groups = const [];
    _notify();
    if (value) loadGroups();
  }

  Future<void> loadGroups() async {
    try {
      final groups = await demoService.demoGroups();
      if (_disposed || !_isAdmin) return;
      _groups = groups;
      _notify();
    } catch (_) {
      // The list is a shortcut only; the buttons still work without it
    }
  }

  /// Number of documents written; null on error ([errorMessage])
  Future<int?> seed() =>
      _run((onProgress) => demoService.seed(onProgress: onProgress), 'seed');

  /// Number of documents deleted; null on error ([errorMessage]). The sample items
  /// of the signed-in admin's own wishlist go first (G2c).
  Future<int?> clear() => _run((onProgress) async {
    if (_uid case final uid?) {
      await demoService.removeDemoItemsFromMyWishlist(uid);
    }
    return demoService.clearDemo(onProgress: onProgress);
  }, 'clear');

  /// G2c: sample items added to the admin's own wishlist; null on error
  Future<int?> addDemoItems() => _run((_) async {
    final uid = _uid;
    if (uid == null) return 0;
    return demoService.addDemoItemsToMyWishlist(uid);
  }, 'add items');

  /// G2c: sample items removed from the admin's own wishlist; null on error
  Future<int?> removeDemoItems() => _run((_) async {
    final uid = _uid;
    if (uid == null) return 0;
    return demoService.removeDemoItemsFromMyWishlist(uid);
  }, 'remove items');

  Future<int?> _run(
    Future<int> Function(DemoProgress onProgress) action,
    String name,
  ) async {
    if (!_isAdmin || _isBusy) return null;
    _isBusy = true;
    _done = 0;
    _total = 0;
    _errorMessage = null;
    _notify();
    try {
      return await action((done, total) {
        _done = done;
        _total = total;
        _notify();
      });
    } catch (e, stack) {
      _errorMessage = messageFor(e, stack, reason: 'demo price history $name');
      return null;
    } finally {
      _isBusy = false;
      _notify();
      if (!_disposed && _isAdmin) await loadGroups();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _roleSubscription?.cancel();
    super.dispose();
  }
}
