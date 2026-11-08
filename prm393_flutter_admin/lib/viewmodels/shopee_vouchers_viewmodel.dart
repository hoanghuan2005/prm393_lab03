import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import '../models/shopee_voucher.dart';
import '../services/shopee_voucher_service.dart';
import 'safe_notifier.dart';
import 'sale_events_viewmodel.dart' show foldVietnamese;

/// Vouchers an admin / staff scraped from Shopee with the Chrome extension
/// (Hướng 2). Updates in real time: a new scrape shows up right away.
class ShopeeVouchersViewModel extends ChangeNotifier with SafeNotifier {
  final ShopeeVoucherService _service;

  StreamSubscription<List<ShopeeVoucher>>? _subscription;
  List<ShopeeVoucher>? _vouchers;
  String? _error;

  /// null = every scope
  VoucherScope? _scope;
  String _query = '';
  bool _hideUnavailable = false;
  final Set<String> _busy = {};
  bool _deletingAll = false;

  ShopeeVouchersViewModel(this._service) {
    _watch();
  }

  void _watch() {
    _subscription?.cancel();
    _vouchers = null;
    _error = null;
    _subscription = _service.watchVouchers().listen(
      (items) {
        _vouchers = items;
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
    _watch();
    notifySafely();
  }

  VoucherScope? get scope => _scope;
  String get query => _query;
  bool get hideUnavailable => _hideUnavailable;
  bool isBusy(String id) => _deletingAll || _busy.contains(id);
  bool get deletingAll => _deletingAll;

  int get totalCount => _vouchers?.length ?? 0;

  /// Distinct shops among the scraped vouchers
  int get shopCount => {
    for (final v in _vouchers ?? const <ShopeeVoucher>[])
      if (v.shopId != null || v.shopName != null) v.shopId ?? v.shopName,
  }.length;

  /// Other shops where the same voucher (same text) was scraped, e.g. a
  /// Shopee voucher offered on products of several shops
  List<String> otherShopsFor(ShopeeVoucher voucher) {
    final key = voucher.sameVoucherKey;
    return {
      for (final v in _vouchers ?? const <ShopeeVoucher>[])
        if (v.id != voucher.id &&
            v.shopName != null &&
            v.shopName != voucher.shopName &&
            v.sameVoucherKey == key)
          v.shopName!,
    }.toList()..sort();
  }

  int countFor(VoucherScope? scope) => scope == null
      ? totalCount
      : (_vouchers ?? const []).where((v) => v.scope == scope).length;

  void setScope(VoucherScope? scope) {
    if (scope == _scope) return;
    _scope = scope;
    notifySafely();
  }

  void setQuery(String value) {
    _query = value;
    notifySafely();
  }

  void setHideUnavailable(bool value) {
    _hideUnavailable = value;
    notifySafely();
  }

  /// Vouchers matching the current scope, search and "hide used up" filter
  List<ShopeeVoucher> get visible {
    final q = foldVietnamese(_query.trim());
    return (_vouchers ?? const <ShopeeVoucher>[]).where((v) {
      if (_scope != null && v.scope != _scope) return false;
      if (_hideUnavailable && v.unavailable) return false;
      if (q.isEmpty) return true;
      return foldVietnamese(
        '${v.raw} ${v.shopName ?? ''} ${v.productTitle ?? ''}',
      ).contains(q);
    }).toList();
  }

  /// Deletes every voucher currently shown (respects the filters).
  /// Returns an error message, or null when done.
  Future<String?> deleteVisible() async {
    final ids = visible.map((v) => v.id).toList();
    if (ids.isEmpty || _deletingAll) return null;
    _deletingAll = true;
    notifySafely();
    try {
      await _service.deleteMany(ids);
      return null;
    } catch (e) {
      return isPermissionDenied(e)
          ? 'Không xoá được: tài khoản không còn quyền nhân viên / admin.'
          : describeFirestoreError(e);
    } finally {
      _deletingAll = false;
      notifySafely();
    }
  }

  UiState<List<ShopeeVoucher>> get state {
    if (_error != null) return UiError(message: _error!, onRetry: retry);
    final all = _vouchers;
    if (all == null) return const UiLoading();
    if (all.isEmpty) {
      return const UiEmpty(
        message:
            'Chưa có voucher nào. Mở một trang Shopee, bấm "Cào voucher" '
            'trong extension (bản Lab) và voucher sẽ hiện ở đây ngay.',
      );
    }
    final items = visible;
    if (items.isEmpty) {
      return const UiEmpty(message: 'Không có voucher nào khớp bộ lọc.');
    }
    return UiSuccess(items);
  }

  /// Returns an error message, or null when the voucher is deleted
  Future<String?> delete(ShopeeVoucher voucher) async {
    _busy.add(voucher.id);
    notifySafely();
    try {
      await _service.delete(voucher.id);
      return null;
    } catch (e) {
      return isPermissionDenied(e)
          ? 'Không xoá được: tài khoản không còn quyền nhân viên / admin.'
          : describeFirestoreError(e);
    } finally {
      _busy.remove(voucher.id);
      notifySafely();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
