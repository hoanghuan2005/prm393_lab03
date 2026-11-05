import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import 'safe_notifier.dart';

enum SaleEventFilter {
  published('Đang hiển thị'),
  archived('Đã lưu trữ'),
  all('Tất cả');

  final String label;

  const SaleEventFilter(this.label);
}

/// Management screen of the sale calendar the app reads (`saleEvents`):
/// list, search, create, edit, archive / restore.
class SaleEventsViewModel extends ChangeNotifier with SafeNotifier {
  static const int maxName = 60;

  final SaleEventService _service;
  final String adminUid;
  StreamSubscription<List<SaleEvent>>? _subscription;

  List<SaleEvent>? _all;
  String? _error;
  String _query = '';
  SaleEventFilter _filter = SaleEventFilter.published;
  final Set<String> _busy = {};

  SaleEventsViewModel(this._service, {required this.adminUid}) {
    _subscribe();
  }

  void _subscribe() {
    _subscription?.cancel();
    _all = null;
    _error = null;
    _subscription = _service.watchAll().listen(
      (events) {
        _all = events;
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
  SaleEventFilter get filter => _filter;
  bool isBusy(String id) => _busy.contains(id);

  void setQuery(String value) {
    _query = value;
    notifySafely();
  }

  void setFilter(SaleEventFilter value) {
    _filter = value;
    notifySafely();
  }

  int countFor(SaleEventFilter filter) =>
      _all?.where((e) => _inFilter(e, filter)).length ?? 0;

  UiState<List<SaleEvent>> get state {
    final error = _error;
    if (error != null) return UiError(message: error, onRetry: retry);
    final all = _all;
    if (all == null) return const UiLoading();
    if (all.isEmpty) {
      return const UiEmpty(
        message: 'Chưa có sự kiện sale nào. Bấm "Thêm sự kiện" để tạo đợt sale đầu tiên.',
      );
    }
    final visible = [
      for (final e in all)
        if (_inFilter(e, _filter) && _matchesQuery(e)) e,
    ];
    if (visible.isEmpty) {
      final q = _query.trim();
      return UiEmpty(
        message: q.isEmpty
            ? 'Không có sự kiện nào ở mục "${_filter.label}".'
            : 'Không có sự kiện nào khớp "$q".',
      );
    }
    return UiSuccess(visible);
  }

  static bool _inFilter(SaleEvent e, SaleEventFilter filter) =>
      switch (filter) {
        SaleEventFilter.published => e.status == SaleEventStatus.published,
        SaleEventFilter.archived => e.status == SaleEventStatus.archived,
        SaleEventFilter.all => true,
      };

  /// Name, type or day (dd/MM/yyyy); accents optional ("tet" finds "Tết")
  bool _matchesQuery(SaleEvent e) {
    final q = foldVietnamese(_query.trim());
    if (q.isEmpty) return true;
    return foldVietnamese('${e.name} ${e.type.label} ${formatDay(e.date)}')
        .contains(q);
  }

  static String? validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Nhập tên đợt sale';
    if (name.length > maxName) return 'Tối đa $maxName ký tự';
    return null;
  }

  /// The app shows one sale per day, so two published events cannot share a day
  SaleEvent? duplicateOf(DateTime day, {String? exceptId}) {
    final id = SaleEvent.dayId(day);
    for (final e in _all ?? const <SaleEvent>[]) {
      if (e.id != exceptId &&
          e.status == SaleEventStatus.published &&
          SaleEvent.dayId(e.date) == id) {
        return e;
      }
    }
    return null;
  }

  static String _duplicateMessage(SaleEvent clash) =>
      'Ngày ${formatDay(clash.date)} đã có sự kiện "${clash.name}". '
      'Hãy sửa sự kiện đó thay vì tạo thêm.';

  /// Create when [id] is null, otherwise edit. Returns an error message, or null.
  Future<String?> save(SaleEventDraft draft, {String? id}) async {
    final nameError = validateName(draft.name);
    if (nameError != null) return nameError;
    final clash = duplicateOf(draft.day, exceptId: id);
    if (clash != null) return _duplicateMessage(clash);
    try {
      if (id == null) {
        await _service.create(adminUid: adminUid, draft: draft);
      } else {
        await _service.update(id, draft);
      }
      return null;
    } catch (e) {
      return describeFirestoreError(e);
    }
  }

  /// Archive (hide from the app) or restore. Returns an error message, or null.
  Future<String?> setStatus(SaleEvent event, SaleEventStatus status) async {
    if (status == SaleEventStatus.published) {
      final clash = duplicateOf(event.date, exceptId: event.id);
      if (clash != null) return _duplicateMessage(clash);
    }
    _busy.add(event.id);
    notifySafely();
    try {
      await _service.setStatus(event.id, status);
      return null;
    } catch (e) {
      return describeFirestoreError(e);
    } finally {
      _busy.remove(event.id);
      notifySafely();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

const Map<String, String> _accents = {
  'a': 'àáạảãâầấậẩẫăằắặẳẵ',
  'e': 'èéẹẻẽêềếệểễ',
  'i': 'ìíịỉĩ',
  'o': 'òóọỏõôồốộổỗơờớợởỡ',
  'u': 'ùúụủũưừứựửữ',
  'y': 'ỳýỵỷỹ',
  'd': 'đ',
};

final Map<String, String> _fold = {
  for (final MapEntry(:key, :value) in _accents.entries)
    for (final ch in value.split('')) ch: key,
};

/// Lower case without Vietnamese accents, for search
@visibleForTesting
String foldVietnamese(String text) =>
    text.toLowerCase().split('').map((ch) => _fold[ch] ?? ch).join();
