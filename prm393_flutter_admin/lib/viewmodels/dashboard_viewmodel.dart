import 'package:flutter/foundation.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import '../models/dashboard_stats.dart';
import '../services/admin_ai_service.dart';
import '../services/dashboard_service.dart';
import 'safe_notifier.dart';

class DashboardViewModel extends ChangeNotifier with SafeNotifier {
  final DashboardService _service;

  /// Admins also see the figures over every user's purchases and wishlist
  final bool isAdmin;

  UiState<DashboardStats> _state = const UiLoading();
  DashboardStats? _latest;
  bool _loading = false;

  DashboardViewModel(this._service, {required this.isAdmin}) {
    load();
  }

  UiState<DashboardStats> get state => _state;
  bool get isLoading => _loading;
  DashboardStats? get latest => _latest;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _state = const UiLoading();
    notifySafely();
    try {
      final stats = await _service.load(includeActivity: isAdmin);
      _latest = stats;
      _state = stats.isEmpty
          ? UiEmpty(
              message: 'Chưa có người dùng nào. Số liệu sẽ có khi người dùng đăng nhập vào app.',
              actionTitle: 'Làm mới',
              onAction: load,
            )
          : UiSuccess(stats);
    } catch (e) {
      _state = UiError(message: describeFirestoreError(e), onRetry: load);
    } finally {
      _loading = false;
      notifySafely();
    }
  }

  /// The aggregate numbers the AI assistant may send (loads them if needed)
  Future<AdminAiMetrics> aiMetrics() async {
    if (_latest == null) await load();
    final s = _latest;
    final a = s?.activity;
    return AdminAiMetrics(
      totalUsers: s?.totalUsers ?? 0,
      newUsersToday: s?.newUsersToday ?? 0,
      activeUsersToday: a?.activeUsersToday ?? 0,
      dormantUsers: a?.dormantUsers ?? 0,
      totalWishlistItems: a?.wishlistItems ?? 0,
    );
  }
}
