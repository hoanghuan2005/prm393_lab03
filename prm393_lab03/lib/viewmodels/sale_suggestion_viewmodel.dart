import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart'
    show
        SaleSuggestion,
        SaleSuggestionService,
        SuggestionStatus,
        describeFirestoreError;

import '../models/ui_state.dart';
import 'deferred_notify.dart';

/// "Báo đợt sale" (cross-role flow, decision D-1 (a)): a signed-in user reports a
/// sale a marketplace has already announced. Staff check the source on the web
/// admin; an approved one is published to every user's Lịch sale and the user
/// gets the answer in their inbox. Models and the service come from
/// `packages/core`, shared with the web admin.
class SaleSuggestionViewModel extends ChangeNotifier with DeferredNotify {
  static const int maxName = 40;
  static const int maxSource = 200;

  /// How far ahead a sale can be reported
  static const int maxDaysAhead = 365;

  final SaleSuggestionService service;
  final DateTime Function() _now;

  StreamSubscription<List<SaleSuggestion>>? _subscription;
  String? _uid;
  bool _isAnonymous = false;
  UiState<List<SaleSuggestion>> _mine = const UiInitial();
  bool _isSubmitting = false;
  String? _actionError;

  SaleSuggestionViewModel({required this.service, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  /// The user's own reports, latest first, live
  UiState<List<SaleSuggestion>> get mine => _mine;
  bool get isSubmitting => _isSubmitting;
  String? get actionError => _actionError;

  /// firestore.rules refuse guests (anonymous sign-in): one person must not
  /// count as several
  bool get canSuggest => _uid != null && !_isAnonymous;
  bool get isGuest => _uid != null && _isAnonymous;

  DateTime get today {
    final n = _now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime get lastDay => today.add(const Duration(days: maxDaysAhead));

  void updateUser(String? uid, {required bool isAnonymous}) {
    if (uid == _uid && isAnonymous == _isAnonymous) return;
    _uid = uid;
    _isAnonymous = isAnonymous;
    _subscribe();
  }

  void _subscribe() {
    _subscription?.cancel();
    _subscription = null;
    final uid = _uid;
    if (uid == null || _isAnonymous) {
      _mine = const UiInitial();
      notifyLater();
      return;
    }
    _mine = const UiLoading();
    notifyLater();
    _subscription = service
        .watchMine(uid)
        .listen(
          (list) {
            _mine = list.isEmpty
                ? const UiEmpty(message: 'Bạn chưa báo đợt sale nào.')
                : UiSuccess(list);
            notifyListeners();
          },
          onError: (Object e) {
            _mine = UiError(
              message: describeFirestoreError(e),
              onRetry: _subscribe,
            );
            notifyListeners();
          },
        );
  }

  static String? validateName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Nhập tên đợt sale, ví dụ "12.12 Siêu sale".';
    if (v.length > maxName) return 'Tối đa $maxName ký tự.';
    return null;
  }

  /// The source is what staff check: a link or where the user saw it
  static String? validateSource(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return 'Ghi nơi sàn công bố (link hoặc mô tả ngắn) để nhóm kiểm tra.';
    }
    if (v.length > maxSource) return 'Tối đa $maxSource ký tự.';
    return null;
  }

  String? validateDate(DateTime? date) {
    if (date == null) return 'Chọn ngày diễn ra đợt sale.';
    final day = DateTime(date.year, date.month, date.day);
    if (day.isBefore(today)) return 'Đợt sale này đã qua.';
    if (day.isAfter(lastDay)) return 'Chỉ báo đợt sale trong 12 tháng tới.';
    return null;
  }

  /// Same day and name already reported and still waiting: avoid a duplicate
  bool isDuplicate(String name, DateTime date) {
    final list = switch (_mine) {
      UiSuccess(:final data) => data,
      _ => const <SaleSuggestion>[],
    };
    final n = name.trim().toLowerCase();
    return list.any(
      (s) =>
          s.status == SuggestionStatus.pending &&
          s.name.trim().toLowerCase() == n &&
          s.date.year == date.year &&
          s.date.month == date.month &&
          s.date.day == date.day,
    );
  }

  /// Sends a pending report; false with [actionError] when refused or failed
  Future<bool> submit({
    required String name,
    required DateTime? date,
    required String source,
  }) async {
    final uid = _uid;
    _actionError = null;
    if (uid == null || !canSuggest) {
      _actionError = 'Cần đăng nhập bằng tài khoản Google để báo đợt sale.';
      notifyListeners();
      return false;
    }
    final invalid =
        validateName(name) ?? validateDate(date) ?? validateSource(source);
    if (invalid != null) {
      _actionError = invalid;
      notifyListeners();
      return false;
    }
    if (isDuplicate(name, date!)) {
      _actionError = 'Bạn đã báo đợt sale này, đang chờ nhóm kiểm tra.';
      notifyListeners();
      return false;
    }
    _isSubmitting = true;
    notifyListeners();
    try {
      await service.submit(uid: uid, name: name, date: date, note: source);
      return true;
    } catch (e) {
      _actionError = describeFirestoreError(e);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
