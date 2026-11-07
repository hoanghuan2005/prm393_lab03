import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/errors/describe_error.dart';
import '../models/price_history_contribution.dart';
import '../models/price_snapshot.dart';
import '../models/shared_price.dart';
import '../models/shopee_link.dart';
import '../models/wishlist_item.dart';
import '../services/ai_product_identity_service.dart';
import '../services/preferences_service.dart';
import '../services/price_history_contribution_service.dart';
import '../services/shared_price_service.dart';
import 'deferred_notify.dart';

enum SharedPriceStatus {
  /// The item has no Shopee product link, so there is nothing to compare with
  unsupported,
  loading,

  /// Fewer than 2 comparable prices from other people (after the outlier filter)
  notEnough,
  ready,
  error,
}

class SharedPriceState {
  final SharedPriceStatus status;
  final SharedPriceSummary? summary;

  /// The variant is unknown: only prices whose variant is also unknown are compared
  final bool variantUnknown;
  final PriceType priceType;

  const SharedPriceState(
    this.status, {
    this.summary,
    this.variantUnknown = false,
    this.priceType = PriceType.single,
  });
}

/// "Giá người khác ghi" on Chi tiết món (spec 8.3). Shares the user's own fresh price
/// anonymously (Google accounts only, can be turned off) and compares it with what
/// other people recorded for the same product and variant. The same switch also sends
/// the user's fresh prices to "Giá tham khảo" (priceHistory, G7) and lets AI name the
/// product there (productCode, G8).
class SharedPriceViewModel extends ChangeNotifier with DeferredNotify {
  final SharedPriceService service;
  final PreferencesService preferencesService;

  /// "Giá tham khảo" (G7); nothing is sent without it
  final PriceHistoryContributionService? historyService;

  /// "Mã món" (G8); no AI call without it, nor while [_aiAllowed] says no
  final AiProductIdentityService? identityService;
  final Future<bool> Function() _aiAllowed;
  final DateTime Function() _now;

  String? _uid;

  /// Guest (anonymous) accounts and linked extensions may read but not contribute:
  /// one person could otherwise appear as several (rules enforce the same)
  bool _canContribute = false;
  bool _sharingEnabled = true;
  final Map<String, SharedPriceState> _states = {};

  /// priceHistory reports already sent (or on their way) for the current user
  final Set<String> _historySent = {};

  /// productKey|modelKey being identified right now
  final Set<String> _identifying = {};
  late final Future<void> _preferenceLoaded;

  SharedPriceViewModel({
    required this.service,
    required this.preferencesService,
    this.historyService,
    this.identityService,
    Future<bool> Function()? aiAllowed,
    DateTime Function()? now,
  }) : _aiAllowed = aiAllowed ?? (() async => false),
       _now = now ?? DateTime.now {
    _preferenceLoaded = _loadPreference();
  }

  bool get sharingEnabled => _sharingEnabled;
  bool get canContribute => _canContribute;

  Future<void> _loadPreference() async {
    _sharingEnabled = await preferencesService.getSharePricesEnabled();
    if (!isDisposed) notifyListeners();
  }

  void updateUser(String? uid, {required bool canContribute}) {
    if (uid == _uid && canContribute == _canContribute) return;
    _uid = uid;
    _canContribute = canContribute;
    _states.clear();
    _historySent.clear();
    notifyLater();
  }

  /// Product and variant of [item]: written by the extension, or read from its link
  static ShopeeLink? linkOf(WishlistItem item) =>
      ShopeeLink.fromProductKey(item.productKey, modelId: item.modelId) ??
      ShopeeLink.tryParse(item.url);

  static String _key(WishlistItem item, PriceSnapshot? mine) =>
      '${item.id}|${linkOf(item)?.productKey}|${linkOf(item)?.modelId}|'
      '${mine?.observedAt.millisecondsSinceEpoch}';

  SharedPriceState stateFor(WishlistItem item, {PriceSnapshot? mine}) {
    if (linkOf(item) == null) {
      return const SharedPriceState(SharedPriceStatus.unsupported);
    }
    return _states[_key(item, mine)] ??
        const SharedPriceState(SharedPriceStatus.loading);
  }

  /// [mine]: the user's latest comparable price, if any. Loads once per price.
  Future<void> load(
    WishlistItem item, {
    PriceSnapshot? mine,
    bool force = false,
  }) async {
    final link = linkOf(item);
    if (link == null) return;
    final key = _key(item, mine);
    if (!force && _states.containsKey(key)) return;
    final priceType = mine?.priceType ?? PriceType.single;
    final modelKey = SharedPriceSummary.modelKeyOf(link.modelId);
    final variantUnknown = modelKey == 'none';
    _states[key] = SharedPriceState(
      SharedPriceStatus.loading,
      variantUnknown: variantUnknown,
      priceType: priceType,
    );
    notifyLater();

    final uid = _uid;
    final now = _now();
    if (uid != null &&
        _canContribute &&
        _sharingEnabled &&
        mine != null &&
        SharedPriceSummary.isShareable(mine, now)) {
      // Not awaited: offline it waits in Firestore's queue and must not block reading
      unawaited(
        service
            .contribute(
              uid: uid,
              productKey: link.productKey,
              modelKey: modelKey,
              snapshot: mine,
            )
            .catchError(
              (Object e) =>
                  debugPrint('Shared price not sent: ${describeError(e)}'),
            ),
      );
    }

    try {
      final reports = await service.reportsFor(link.productKey, modelKey);
      // The user's own report is never compared with itself
      if (uid != null) {
        reports.remove(
          SharedPriceSummary.reportId(uid, link.productKey, modelKey),
        );
      }
      final summary = SharedPriceSummary.summarize(
        reports.values.toList(),
        priceType: priceType,
        now: now,
        myAmountVnd: mine?.amountVnd,
      );
      _states[key] = SharedPriceState(
        summary == null ? SharedPriceStatus.notEnough : SharedPriceStatus.ready,
        summary: summary,
        variantUnknown: variantUnknown,
        priceType: priceType,
      );
    } catch (e) {
      debugPrint('Shared prices unavailable: ${describeError(e)}');
      _states[key] = SharedPriceState(
        SharedPriceStatus.error,
        variantUnknown: variantUnknown,
        priceType: priceType,
      );
    }
    if (!isDisposed) notifyListeners();
  }

  /// G7: sends the user's own fresh prices of [item] ([snapshots] = its Lịch sử giá)
  /// anonymously to "Giá tham khảo": not for guests, only with a productKey and with
  /// sharing on (see [HistoryContribution.reportsFor]). Each report is sent once.
  Future<void> reportHistory(
    WishlistItem item,
    List<PriceSnapshot> snapshots,
  ) async {
    await _preferenceLoaded;
    final history = historyService, uid = _uid;
    final productKey = HistoryContribution.productKeyOf(item);
    final title = HistoryContribution.titleOf(item);
    if (isDisposed || history == null || uid == null) return;
    if (!_canContribute || !_sharingEnabled) return;
    if (productKey == null || title == null) return;
    for (final report in HistoryContribution.reportsFor(
      item,
      snapshots,
      _now(),
    )) {
      final sentKey =
          '$productKey|${report.modelKey}|${report.observedAt.toIso8601String()}|'
          '${report.amountVnd}|${report.priceType.key}';
      if (!_historySent.add(sentKey)) continue;
      // Not awaited by the screen: offline it waits in Firestore's queue
      try {
        await history.contribute(
          uid: uid,
          productKey: productKey,
          title: title,
          shopName: report.shopName,
          report: report,
        );
      } catch (e) {
        _historySent.remove(sentKey);
        debugPrint('Price history report not sent: ${describeError(e)}');
      }
    }
  }

  /// G8: asks AI once per link what the product is, and writes its productCode (source
  /// 'ai') when priceHistory has none; asks again only for a variant whose modelKey is
  /// not in variantCodes yet. Same conditions as [reportHistory], plus the AI switches.
  /// Runs after [reportHistory], which may have created the product. A not-sure answer
  /// is remembered on this device (the link is not asked again); an AI or write error
  /// is not, so the next opening of Chi tiết món tries again. Never throws.
  Future<void> identifyProduct(WishlistItem item) async {
    await _preferenceLoaded;
    final ai = identityService, history = historyService, uid = _uid;
    final productKey = HistoryContribution.productKeyOf(item);
    if (isDisposed || ai == null || history == null || uid == null) return;
    if (!_canContribute || !_sharingEnabled || productKey == null) return;
    final modelKey = SharedPriceSummary.modelKeyOf(item.modelId);
    final label = item.variantLabel?.trim() ?? '';
    final variantKey = '$productKey|$modelKey';
    if (!_identifying.add(variantKey)) return;
    try {
      if (!await _aiAllowed()) return;
      final product = await history.fetchProduct(productKey);
      if (product == null || product.isDemo) return;
      final tried = await preferencesService.getProductIdentityTried();
      final needCode =
          product.productCode == null && !tried.contains(productKey);
      // A variant code only means something next to a product code
      final needVariant =
          label.isNotEmpty &&
          !product.variantCodes.containsKey(modelKey) &&
          !tried.contains(variantKey) &&
          (product.productCode != null || needCode);
      if (!needCode && !needVariant) return;

      // The title already in priceHistory: nothing more of the user's goes to AI
      final identity = await ai.extractProductIdentity(product.title, [
        if (needVariant) label,
      ]);
      final code = needCode ? identity?.productCode : null;
      final variantCode =
          needVariant && (code != null || product.productCode != null)
          ? identity?.variantCodeOf(label)
          : null;
      if (code != null || variantCode != null) {
        await history.addCodes(
          productKey: productKey,
          productCode: code,
          modelKey: variantCode == null ? null : modelKey,
          variantCode: variantCode,
        );
      }
      if (needCode) {
        await preferencesService.addProductIdentityTried(productKey);
      }
      if (needVariant) {
        await preferencesService.addProductIdentityTried(variantKey);
      }
    } catch (e) {
      debugPrint('Product identity not saved: ${describeError(e)}');
    } finally {
      _identifying.remove(variantKey);
    }
  }

  /// Off: stops sharing and removes this person's report for [item] right away; reports
  /// for other items stop counting after 3 days. On: the next price is shared again.
  Future<void> setSharingEnabled(bool enabled, {WishlistItem? item}) async {
    _sharingEnabled = enabled;
    notifyListeners();
    await preferencesService.setSharePricesEnabled(enabled);
    final uid = _uid;
    final link = item == null ? null : linkOf(item);
    if (!enabled && uid != null && _canContribute && link != null) {
      try {
        await service.withdraw(
          uid: uid,
          productKey: link.productKey,
          modelKey: SharedPriceSummary.modelKeyOf(link.modelId),
        );
      } catch (e) {
        debugPrint('Shared price not withdrawn: ${describeError(e)}');
      }
    }
  }
}
