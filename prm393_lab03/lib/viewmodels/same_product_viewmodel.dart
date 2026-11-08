import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/errors/describe_error.dart';
import '../models/price_history.dart';
import '../models/price_history_contribution.dart';
import '../models/same_product.dart';
import '../models/shared_price.dart';
import '../models/wishlist_item.dart';
import '../services/analytics_service.dart';
import '../services/hidden_match_service.dart';
import '../services/price_history_service.dart';
import 'deferred_notify.dart';

enum SameProductStatus {
  loading,

  /// No productCode, no variant code for the item's variant, or no shop to show
  none,
  ready,

  /// Not loaded; the card simply stays hidden
  error,
}

class SameProductState {
  final SameProductStatus status;
  final List<SameProductOffer> offers;
  final String? variantCode;
  final bool isDemo;

  const SameProductState(
    this.status, {
    this.offers = const [],
    this.variantCode,
    this.isDemo = false,
  });

  const SameProductState.loading() : this(SameProductStatus.loading);

  const SameProductState.none() : this(SameProductStatus.none);

  /// The card is shown with at least one shop
  bool get visible => status == SameProductStatus.ready && offers.isNotEmpty;

  /// The shops shown, for the "Cả nhóm" chart
  SameProductLinks? get links => offers.isEmpty
      ? null
      : SameProductLinks(
          productKeys: [for (final o in offers) o.productKey],
          variantCode: variantCode,
        );
}

/// What was read for one item, kept to recompute after "Không phải món này"
class _Candidates {
  final Map<String, PriceHistoryProduct> products;
  final Map<String, List<PriceHistoryReport>> reports;
  final String? variantCode;
  final bool isDemo;

  const _Candidates(this.products, this.reports, this.variantCode, this.isDemo);
}

/// "Cùng món ở shop khác" on Chi tiết món (G8): the same productCode and variant code
/// in other shops, lowest latest list price first, up to 3. Matching is automatic
/// (AI codes), so each row can be hidden ("Không phải món này", per user).
class SameProductViewModel extends ChangeNotifier with DeferredNotify {
  final PriceHistoryService service;
  final HiddenMatchService hiddenService;
  final AppAnalyticsService? analytics;
  final DateTime Function() _now;

  SameProductViewModel({
    required this.service,
    required this.hiddenService,
    this.analytics,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  String? _uid;

  /// users/{uid}/hiddenMatches; null until read for this user
  Set<String>? _hidden;
  final Map<String, SameProductState> _states = {};
  final Map<String, _Candidates> _candidates = {};

  /// Loads started for an earlier user are dropped
  int _generation = 0;

  void updateUid(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _hidden = null;
    _states.clear();
    _candidates.clear();
    _generation++;
    notifyLater();
  }

  /// productKey|modelKey of [item]; null without a Shopee productKey
  static String? _keyOf(WishlistItem item) {
    final productKey = HistoryContribution.productKeyOf(item);
    if (productKey == null) return null;
    return '$productKey|${SharedPriceSummary.modelKeyOf(item.modelId)}';
  }

  /// Null until [load] has been called for [item]
  SameProductState? stateFor(WishlistItem item) => _states[_keyOf(item)];

  /// Reads the item's code, the other listings and their last 7 days. Called once per
  /// opening of Chi tiết món; the previous result stays on screen meanwhile.
  Future<void> load(WishlistItem item) async {
    final key = _keyOf(item);
    final productKey = HistoryContribution.productKeyOf(item);
    if (key == null || productKey == null) return;
    final generation = _generation;
    _states.putIfAbsent(key, () => const SameProductState.loading());
    notifyLater();
    try {
      final product = await service.watchProduct(productKey).first;
      final code = product?.productCode;
      final variantCode = product == null
          ? null
          : _variantCodeOf(product, item);
      if (product == null || code == null || variantCode == _unknown) {
        _set(generation, key, const SameProductState.none());
        return;
      }
      final ownShop = SameProduct.shopIdOf(productKey);
      final others = {
        for (final p in await service.findSameProduct(
          code,
          isDemo: product.isDemo,
        ))
          if (SameProduct.shopIdOf(p.productKey) != ownShop) p.productKey: p,
      };
      // A day more than the window: offers are cut at exactly 7 days
      final from = _now().subtract(
        const Duration(days: SameProduct.windowDays + 1),
      );
      final keys = others.keys.toList();
      final reports = await Future.wait([
        for (final k in keys) service.fetchReports(k, from),
      ]);
      await _loadHidden();
      if (generation != _generation || isDisposed) return;
      _candidates[key] = _Candidates(
        others,
        {for (var i = 0; i < keys.length; i++) keys[i]: reports[i]},
        variantCode,
        product.isDemo,
      );
      _publish(key, logView: true);
    } catch (e) {
      debugPrint('Same product not loaded: ${describeError(e)}');
      _set(generation, key, const SameProductState(SameProductStatus.error));
    }
  }

  /// Marker for "the item has a variant whose code is not known yet"
  static const String _unknown = '?';

  /// The item's variant code; null when neither it nor the product has variants
  static String? _variantCodeOf(
    PriceHistoryProduct product,
    WishlistItem item,
  ) {
    final modelKey = SharedPriceSummary.modelKeyOf(item.modelId);
    if (modelKey == 'none' && product.variantCodes.isEmpty) return null;
    return product.variantCodes[modelKey] ?? _unknown;
  }

  Future<void> _loadHidden() async {
    final uid = _uid;
    if (_hidden != null || uid == null) return;
    try {
      _hidden = await hiddenService.hiddenKeys(uid);
    } catch (e) {
      // Shown unfiltered this time; read again on the next load
      debugPrint('Hidden matches not loaded: ${describeError(e)}');
    }
  }

  void _set(int generation, String key, SameProductState state) {
    if (generation != _generation || isDisposed) return;
    _states[key] = state;
    notifyListeners();
  }

  void _publish(String key, {bool logView = false}) {
    final c = _candidates[key];
    if (c == null) return;
    final offers = pickLowestOffers(
      c.products,
      c.reports,
      c.variantCode,
      _now(),
      hidden: _hidden ?? const {},
    );
    _states[key] = SameProductState(
      SameProductStatus.ready,
      offers: offers,
      variantCode: c.variantCode,
      isDemo: c.isDemo,
    );
    if (logView && offers.isNotEmpty) {
      unawaited(
        analytics?.logViewSameProduct(
              resultCount: offers.length,
              isDemo: c.isDemo,
            ) ??
            Future<void>.value(),
      );
    }
    notifyListeners();
  }

  void _republishAll() {
    for (final key in _candidates.keys.toList()) {
      _publish(key);
    }
  }

  /// "Không phải món này": hidden at once (another shop may move up), then saved.
  /// False when it could not be saved; the row is back.
  Future<bool> hide(String productKey) async {
    final uid = _uid;
    if (uid == null) return false;
    (_hidden ??= {}).add(productKey);
    _republishAll();
    unawaited(analytics?.logHideSameProductMatch() ?? Future<void>.value());
    try {
      await hiddenService.hide(uid, productKey);
      return true;
    } catch (e) {
      debugPrint('Match not hidden: ${describeError(e)}');
      _hidden?.remove(productKey);
      _republishAll();
      return false;
    }
  }

  /// "Hoàn tác" after [hide]
  Future<void> undoHide(String productKey) async {
    final uid = _uid;
    if (uid == null) return;
    _hidden?.remove(productKey);
    _republishAll();
    try {
      await hiddenService.unhide(uid, productKey);
    } catch (e) {
      debugPrint('Match not shown again: ${describeError(e)}');
      (_hidden ??= {}).add(productKey);
      _republishAll();
    }
  }
}
