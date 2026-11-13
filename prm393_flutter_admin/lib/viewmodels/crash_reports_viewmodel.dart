import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import 'safe_notifier.dart';
import 'sale_events_viewmodel.dart' show foldVietnamese;

enum CrashFilter {
  open('Chưa xử lý'),
  resolved('Đã xử lý'),
  all('Tất cả');

  final String label;

  const CrashFilter(this.label);
}

/// "Sự cố": crash and error reports the app writes to `crashes`, live, so the
/// team sees them here instead of opening the Firebase Console. Staff can mark a
/// report resolved (or open it again); reports are never deleted.
class CrashReportsViewModel extends ChangeNotifier with SafeNotifier {
  final CrashReportService _service;
  final String byUid;
  StreamSubscription<List<CrashReport>>? _subscription;

  List<CrashReport>? _all;
  String? _error;
  String _query = '';
  CrashFilter _filter = CrashFilter.open;
  final Set<String> _busy = {};

  CrashReportsViewModel(this._service, {required this.byUid}) {
    _subscribe();
  }

  void _subscribe() {
    _subscription?.cancel();
    _all = null;
    _error = null;
    _subscription = _service.watchRecent().listen(
      (list) {
        _all = list;
        _error = null;
        notifySafely();
      },
      onError: (Object e) {
        _error = describeFirestoreError(e);
        notifySafely();
      },
    );
  }

  void retry() {
    _subscribe();
    notifySafely();
  }

  String get query => _query;
  CrashFilter get filter => _filter;
  bool isBusy(String id) => _busy.contains(id);

  void setQuery(String value) {
    _query = value;
    notifySafely();
  }

  void setFilter(CrashFilter value) {
    _filter = value;
    notifySafely();
  }

  int countFor(CrashFilter filter) =>
      _all?.where((c) => _inFilter(c, filter)).length ?? 0;

  /// Open reports that crashed or threw an uncaught error: what needs a look first
  int get openFatalCount =>
      _all
          ?.where((c) => !c.isResolved && c.severity == CrashSeverity.fatal)
          .length ??
      0;

  UiState<List<CrashReport>> get state {
    final error = _error;
    if (error != null) return UiError(message: error, onRetry: retry);
    final all = _all;
    if (all == null) return const UiLoading();
    if (all.isEmpty) {
      return const UiEmpty(
        message:
            'Chưa có báo cáo sự cố nào. Khi app gặp lỗi chưa được bắt, báo cáo '
            'hiện ở đây ngay.',
      );
    }
    final visible = [
      for (final c in all)
        if (_inFilter(c, _filter) && _matchesQuery(c)) c,
    ];
    if (visible.isEmpty) {
      final q = _query.trim();
      return UiEmpty(
        message: q.isEmpty
            ? 'Không có báo cáo nào ở mục "${_filter.label}".'
            : 'Không có báo cáo nào khớp "$q".',
      );
    }
    return UiSuccess(visible);
  }

  bool _inFilter(CrashReport c, CrashFilter filter) => switch (filter) {
    CrashFilter.open => !c.isResolved,
    CrashFilter.resolved => c.isResolved,
    CrashFilter.all => true,
  };

  /// Screen or feature, error code, message or user id; accents optional
  bool _matchesQuery(CrashReport c) {
    final q = foldVietnamese(_query.trim());
    if (q.isEmpty) return true;
    return foldVietnamese(
      '${c.feature} ${c.errorCode} ${c.errorMessage} ${c.userId} '
      '${c.severity.label} ${c.platform}',
    ).contains(q);
  }

  /// Mark resolved ([resolved] true) or open again. Returns an error message, or null.
  Future<String?> setResolved(CrashReport report, bool resolved) async {
    _busy.add(report.id);
    notifySafely();
    try {
      await _service.setResolved(report.id, resolved, byUid: byUid);
      return null;
    } catch (e) {
      return describeFirestoreError(e);
    } finally {
      _busy.remove(report.id);
      notifySafely();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
