import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import 'safe_notifier.dart';
import 'sale_events_viewmodel.dart' show foldVietnamese;

enum VoucherFilter {
  active('Đang dùng'),
  expired('Hết hạn'),
  archived('Đã lưu trữ'),
  all('Tất cả');

  final String label;

  const VoucherFilter(this.label);
}

/// "Mã giảm giá": the real Shopee vouchers the app suggests (`vouchers`,
/// decision D-3). List, search, create, edit, archive, use again.
class VouchersAdminViewModel extends ChangeNotifier with SafeNotifier {
  final VoucherRecordService _service;
  final String byUid;
  final DateTime Function() _now;
  StreamSubscription<List<VoucherRecord>>? _subscription;

  List<VoucherRecord>? _all;
  String? _error;
  String _query = '';
  VoucherFilter _filter = VoucherFilter.active;
  final Set<String> _busy = {};

  VouchersAdminViewModel(
    this._service, {
    required this.byUid,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _subscribe();
  }

  void _subscribe() {
    _subscription?.cancel();
    _all = null;
    _error = null;
    _subscription = _service.watchAll().listen(
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

  DateTime get now => _now();
  String get query => _query;
  VoucherFilter get filter => _filter;
  bool isBusy(String id) => _busy.contains(id);

  void setQuery(String value) {
    _query = value;
    notifySafely();
  }

  void setFilter(VoucherFilter value) {
    _filter = value;
    notifySafely();
  }

  int countFor(VoucherFilter filter) =>
      _all?.where((v) => _inFilter(v, filter)).length ?? 0;

  UiState<List<VoucherRecord>> get state {
    final error = _error;
    if (error != null) return UiError(message: error, onRetry: retry);
    final all = _all;
    if (all == null) return const UiLoading();
    if (all.isEmpty) {
      return const UiEmpty(
        message:
            'Chưa có mã nào. Bấm "Thêm mã" để nhập một mã Shopee đang công bố; '
            'app chỉ gợi ý mã có ở đây.',
      );
    }
    final visible = [
      for (final v in all)
        if (_inFilter(v, _filter) && _matchesQuery(v)) v,
    ];
    if (visible.isEmpty) {
      final q = _query.trim();
      return UiEmpty(
        message: q.isEmpty
            ? 'Không có mã nào ở mục "${_filter.label}".'
            : 'Không có mã nào khớp "$q".',
      );
    }
    return UiSuccess(visible);
  }

  bool _inFilter(VoucherRecord v, VoucherFilter filter) => switch (filter) {
    VoucherFilter.active => v.isActive && !v.isExpired(now),
    VoucherFilter.expired => v.isActive && v.isExpired(now),
    VoucherFilter.archived => !v.isActive,
    VoucherFilter.all => true,
  };

  /// Code, title, shop or category; accents optional
  bool _matchesQuery(VoucherRecord v) {
    final q = foldVietnamese(_query.trim());
    if (q.isEmpty) return true;
    final d = v.draft;
    return foldVietnamese(
      '${d.code} ${d.title} ${d.shopName ?? ''} ${d.shopId ?? ''} '
      '${d.category.label}',
    ).contains(q);
  }

  // ---------- Validation (same limits as firestore.rules) ----------

  static final RegExp _code = RegExp(r'^[A-Z0-9]{3,30}$');

  static String? validateCode(String? value) {
    final code = value?.trim().toUpperCase() ?? '';
    if (code.isEmpty) return 'Nhập mã, ví dụ SHOPEE50K';
    if (!_code.hasMatch(code)) {
      return 'Chỉ chữ in hoa không dấu và số, 3–${VoucherDraft.maxCode} ký tự';
    }
    return null;
  }

  static String? validateTitle(String? value) {
    final title = value?.trim() ?? '';
    if (title.isEmpty) return 'Nhập mô tả ngắn, ví dụ "Giảm 50K đơn từ 250K"';
    if (title.length > VoucherDraft.maxTitle) {
      return 'Tối đa ${VoucherDraft.maxTitle} ký tự';
    }
    return null;
  }

  /// "50.000", "50000" or "50k" → 50000; null when it is not a whole amount
  static int? parseVnd(String? value) {
    var text = (value ?? '').trim().toLowerCase().replaceAll(
      RegExp(r'[.,\s₫đ]'),
      '',
    );
    var factor = 1;
    if (text.endsWith('k')) {
      factor = 1000;
      text = text.substring(0, text.length - 1);
    }
    final n = int.tryParse(text);
    return n == null ? null : n * factor;
  }

  static String? validateDiscount(String? value, VoucherKind kind) {
    final n = parseVnd(value);
    if (n == null) return 'Nhập số tiền, ví dụ 50000 hoặc 50k';
    if (n > VoucherDraft.maxVnd) return 'Số tiền quá lớn';
    if (kind == VoucherKind.discount && n <= 0) {
      return 'Mã giảm giá phải giảm hơn 0 ₫';
    }
    if (n < 0) return 'Không nhận số âm';
    return null;
  }

  static String? validateMinOrder(String? value) {
    if ((value ?? '').trim().isEmpty) return null;
    final n = parseVnd(value);
    if (n == null || n < 0) return 'Nhập số tiền, hoặc để trống nếu không có';
    if (n > VoucherDraft.maxVnd) return 'Số tiền quá lớn';
    return null;
  }

  /// Empty is fine (a voucher for every shop); otherwise a link or id that
  /// gives a Shopee shop id
  static String? validateShopLink(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (shopIdFromShopeeLink(text) == null) {
      return 'Dán link một sản phẩm của shop (có "-i.<số>.<số>") '
          'hoặc link shopee.vn/shop/<số>';
    }
    return null;
  }

  static final RegExp _shopeeUrl = RegExp(
    r'^https://([a-z0-9-]+[.])?shopee[.]vn(/.*)?$',
  );

  static String? validateSourceUrl(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (text.length > VoucherDraft.maxSourceUrl) {
      return 'Tối đa ${VoucherDraft.maxSourceUrl} ký tự';
    }
    if (!_shopeeUrl.hasMatch(text)) {
      return 'Chỉ nhận link https của shopee.vn';
    }
    return null;
  }

  /// The same code for the same shop (or for every shop) already in use
  VoucherRecord? duplicateOf(VoucherDraft draft, {String? exceptId}) {
    final code = draft.code.trim().toUpperCase();
    final shop = draft.shopId?.trim() ?? '';
    for (final v in _all ?? const <VoucherRecord>[]) {
      if (v.id == exceptId || !v.isActive) continue;
      if (v.draft.code.toUpperCase() == code &&
          (v.draft.shopId?.trim() ?? '') == shop) {
        return v;
      }
    }
    return null;
  }

  /// Create when [id] is null, otherwise edit (keeps the archived state).
  /// Returns an error message, or null.
  Future<String?> save(VoucherDraft draft, {String? id}) async {
    final error =
        validateCode(draft.code) ??
        validateTitle(draft.title) ??
        validateDiscount('${draft.discountVnd}', draft.kind) ??
        validateMinOrder('${draft.minOrderVnd}') ??
        validateSourceUrl(draft.sourceUrl);
    if (error != null) return error;
    if (draft.validUntil.isBefore(DateTime(now.year, now.month, now.day))) {
      return 'Hạn dùng đã qua. Chọn ngày từ hôm nay trở đi.';
    }
    final clash = duplicateOf(draft, exceptId: id);
    if (clash != null) {
      return 'Mã ${clash.draft.code} đã có cho '
          '${clash.draft.shopId == null ? 'mọi shop' : 'shop này'}. '
          'Hãy sửa mã đó thay vì thêm mới.';
    }
    try {
      if (id == null) {
        await _service.create(byUid: byUid, draft: draft);
      } else {
        await _service.update(
          id,
          draft,
          isActive: _byId(id)?.isActive ?? true,
          byUid: byUid,
        );
      }
      return null;
    } catch (e) {
      return describeFirestoreError(e);
    }
  }

  /// Archive ([active] false) or use again. Returns an error message, or null.
  Future<String?> setActive(VoucherRecord voucher, bool active) async {
    if (active && voucher.isLegacy) {
      return 'Mã này do màn quản trị cũ tạo, thiếu thông tin. '
          'Hãy bấm Sửa, kiểm tra lại rồi lưu.';
    }
    _busy.add(voucher.id);
    notifySafely();
    try {
      await _service.setActive(voucher.id, active, byUid: byUid);
      return null;
    } catch (e) {
      return describeFirestoreError(e);
    } finally {
      _busy.remove(voucher.id);
      notifySafely();
    }
  }

  VoucherRecord? _byId(String id) {
    for (final v in _all ?? const <VoucherRecord>[]) {
      if (v.id == id) return v;
    }
    return null;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
