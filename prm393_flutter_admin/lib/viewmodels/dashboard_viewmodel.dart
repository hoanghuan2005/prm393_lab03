import 'package:flutter/foundation.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import '../models/dashboard_stats.dart';
import '../services/dashboard_service.dart';
import 'safe_notifier.dart';

class DashboardViewModel extends ChangeNotifier with SafeNotifier {
  final DashboardService _service;

  UiState<DashboardStats> _state = const UiLoading();
  bool _loading = false;

  DashboardViewModel(this._service) {
    load();
  }

  UiState<DashboardStats> get state => _state;
  bool get isLoading => _loading;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _state = const UiLoading();
    notifySafely();
    try {
      final stats = await _service.load();
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
}
