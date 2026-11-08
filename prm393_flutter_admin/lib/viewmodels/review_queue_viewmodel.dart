import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import 'safe_notifier.dart';
import 'sale_events_viewmodel.dart';

/// Review queue of sale suggestions sent from the app. Approving publishes the
/// sale event and messages the user's inbox in one batch; rejecting needs a reason.
class ReviewQueueViewModel extends ChangeNotifier with SafeNotifier {
  static const int maxReason = FirestoreSaleSuggestionService.maxReason;

  /// One tap fills the reason; the admin can still edit it
  static const List<String> quickReasons = [
    'Trùng với sự kiện đã có trong lịch',
    'Chưa có thông báo chính thức từ shop',
    'Ngày sale đã qua',
    'Thông tin chưa đủ rõ',
  ];

  final SaleSuggestionService _service;
  final String byUid;

  SuggestionStatus _tab = SuggestionStatus.pending;

  // The pending list is always watched: it also feeds the navigation badge
  StreamSubscription<List<SaleSuggestion>>? _pendingSubscription;
  List<SaleSuggestion>? _pending;
  String? _pendingError;

  StreamSubscription<List<SaleSuggestion>>? _reviewedSubscription;
  List<SaleSuggestion>? _reviewed;
  String? _reviewedError;

  final Set<String> _busy = {};

  ReviewQueueViewModel(this._service, {required this.byUid}) {
    _watchPending();
  }

  void _watchPending() {
    _pendingSubscription?.cancel();
    _pending = null;
    _pendingError = null;
    _pendingSubscription = _service
        .watchByStatus(SuggestionStatus.pending)
        .listen(
          (items) {
            _pending = items;
            _pendingError = null;
            notifySafely();
          },
          onError: (Object e) {
            _pendingError = describeFirestoreError(e);
            notifySafely();
          },
        );
  }

  void _watchReviewed(SuggestionStatus status) {
    _reviewedSubscription?.cancel();
    _reviewed = null;
    _reviewedError = null;
    _reviewedSubscription = _service
        .watchByStatus(status)
        .listen(
          (items) {
            _reviewed = items;
            _reviewedError = null;
            notifySafely();
          },
          onError: (Object e) {
            _reviewedError = describeFirestoreError(e);
            notifySafely();
          },
        );
  }

  SuggestionStatus get tab => _tab;
  int get pendingCount => _pending?.length ?? 0;
  bool isBusy(String id) => _busy.contains(id);

  void setTab(SuggestionStatus status) {
    if (status == _tab) return;
    _tab = status;
    if (status == SuggestionStatus.pending) {
      _reviewedSubscription?.cancel();
      _reviewedSubscription = null;
    } else {
      _watchReviewed(status);
    }
    notifySafely();
  }

  void retry() {
    if (_tab == SuggestionStatus.pending) {
      _watchPending();
    } else {
      _watchReviewed(_tab);
    }
    notifySafely();
  }

  UiState<List<SaleSuggestion>> get state {
    final isPending = _tab == SuggestionStatus.pending;
    final error = isPending ? _pendingError : _reviewedError;
    if (error != null) return UiError(message: error, onRetry: retry);
    final items = isPending ? _pending : _reviewed;
    if (items == null) return const UiLoading();
    if (items.isEmpty) {
      return UiEmpty(
        message: isPending
            ? 'Không có đề xuất nào chờ duyệt. Đề xuất mới từ app sẽ hiện ở đây ngay.'
            : 'Chưa có đề xuất nào ở mục "${_tab.label}".',
      );
    }
    return UiSuccess(items);
  }

  /// Pre-filled event for the approve dialog. The type follows the public
  /// pattern of the day; "confirmed" stays off until the admin checks the shop.
  static SaleEventDraft draftFor(SaleSuggestion s) => SaleEventDraft(
    name: s.name,
    date: s.date,
    type: typeForDay(s.date),
    confirmed: false,
  );

  static SaleType typeForDay(DateTime d) {
    if (d.day == d.month) return SaleType.doubleDay;
    if (d.day == 15) return SaleType.midMonth;
    if (d.day == 25) return SaleType.payday;
    return SaleType.other;
  }

  static String? validateReason(String? value) {
    final reason = value?.trim() ?? '';
    if (reason.isEmpty) return 'Nhập lý do để người gửi biết vì sao';
    if (reason.length > maxReason) return 'Tối đa $maxReason ký tự';
    return null;
  }

  /// Returns an error message, or null when the suggestion is approved
  Future<String?> approve(SaleSuggestion suggestion, SaleEventDraft event) {
    final nameError = SaleEventsViewModel.validateName(event.name);
    if (nameError != null) return Future.value(nameError);
    return _review(
      suggestion,
      () =>
          _service.approve(suggestion: suggestion, byUid: byUid, event: event),
    );
  }

  /// Returns an error message, or null when the suggestion is rejected
  Future<String?> reject(SaleSuggestion suggestion, String reason) {
    final reasonError = validateReason(reason);
    if (reasonError != null) return Future.value(reasonError);
    return _review(
      suggestion,
      () =>
          _service.reject(suggestion: suggestion, byUid: byUid, reason: reason),
    );
  }

  Future<String?> _review(
    SaleSuggestion suggestion,
    Future<Object?> Function() write,
  ) async {
    _busy.add(suggestion.id);
    notifySafely();
    try {
      await write();
      return null;
    } catch (e) {
      return isPermissionDenied(e)
          ? 'Không lưu được: đề xuất có thể đã được admin khác xử lý, '
                'hoặc tài khoản không còn quyền admin.'
          : describeFirestoreError(e);
    } finally {
      _busy.remove(suggestion.id);
      notifySafely();
    }
  }

  @override
  void dispose() {
    _pendingSubscription?.cancel();
    _reviewedSubscription?.cancel();
    super.dispose();
  }
}
