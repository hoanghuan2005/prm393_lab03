import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';

import '../firebase/platform_support.dart';
import 'analytics_events.dart';

/// Service abstraction for Firebase Analytics
/// Strictly adheres to the Analytics Plan in docs/analytics-plan.md (No PII).
/// Every event name and parameter comes from analytics_events.dart.
/// On web/Windows analytics is disabled ([_analytics] is null) and events are no-ops.
class AppAnalyticsService {
  final FirebaseAnalytics? _analytics;

  AppAnalyticsService({FirebaseAnalytics? analytics})
    : _analytics =
          analytics ??
          (PlatformSupport.supportsAnalytics
              ? FirebaseAnalytics.instance
              : null);

  List<NavigatorObserver> get navigatorObservers => [
    if (_analytics != null) FirebaseAnalyticsObserver(analytics: _analytics),
  ];

  /// uid on sign-in, null on sign-out (never email)
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics?.setUserId(id: userId);
    } catch (e) {
      debugPrint('Analytics setUserId error: $e');
    }
  }

  Future<void> _log(String event, [Map<String, Object>? parameters]) async {
    try {
      await _analytics?.logEvent(
        name: event,
        parameters: parameters == null || parameters.isEmpty
            ? null
            : parameters,
      );
    } catch (e) {
      debugPrint('Analytics $event error: $e');
    }
  }

  Future<void> logLogin({required String method}) =>
      _log(AnalyticsEvents.login, {AnalyticsParams.method: method});

  Future<void> logLogout({int? sessionDurationSec}) => _log(
    AnalyticsEvents.logout,
    {AnalyticsParams.sessionDurationSec: ?sessionDurationSec},
  );

  /// Only the query length is sent; the text itself may contain item names
  Future<void> logSearch({
    required int queryLength,
    required int resultCount,
  }) => _log(AnalyticsEvents.search, {
    AnalyticsParams.queryLength: queryLength,
    AnalyticsParams.resultCount: resultCount,
  });

  Future<void> logAddToWishlist({
    required String motive,
    required int? priceVnd,
  }) => _log(AnalyticsEvents.addToWishlist, {
    AnalyticsParams.motive: motive,
    AnalyticsParams.hasPrice: priceVnd == null ? 0 : 1,
    if (priceVnd != null)
      AnalyticsParams.amountBucket: AmountBucket.of(priceVnd).value,
  });

  Future<void> logViewItemDetail({
    required String motive,
    required int daysInCooldown,
  }) => _log(AnalyticsEvents.viewItemDetail, {
    AnalyticsParams.motive: motive,
    AnalyticsParams.daysInCooldown: daysInCooldown,
  });

  /// [decision] is one of [AnalyticsDecisions]
  Future<void> logMakeDecision({
    required String decision,
    required String motive,
    required int? priceVnd,
  }) => _log(AnalyticsEvents.makeDecision, {
    AnalyticsParams.decision: decision,
    AnalyticsParams.motive: motive,
    AnalyticsParams.hasPrice: priceVnd == null ? 0 : 1,
    if (priceVnd != null)
      AnalyticsParams.amountBucket: AmountBucket.of(priceVnd).value,
  });

  Future<void> logPurchaseRecorded({
    required String motive,
    required int amountVnd,
    required String budgetGroupId,
  }) => _log(AnalyticsEvents.purchaseRecorded, {
    AnalyticsParams.motive: motive,
    AnalyticsParams.amountBucket: AmountBucket.of(amountVnd).value,
    AnalyticsParams.budgetGroup: budgetGroupId,
  });

  Future<void> logBudgetSet({
    required String budgetGroupId,
    required int amountVnd,
    required String month,
  }) => _log(AnalyticsEvents.budgetSet, {
    AnalyticsParams.budgetGroup: budgetGroupId,
    AnalyticsParams.amountBucket: AmountBucket.of(amountVnd).value,
    AnalyticsParams.month: month,
  });

  Future<void> logExportReport({
    required String fileFormat,
    required int itemCount,
  }) => _log(AnalyticsEvents.exportReport, {
    AnalyticsParams.fileFormat: fileFormat,
    AnalyticsParams.itemCount: itemCount,
  });

  Future<void> logClickSaleReminder(String saleType) => _log(
    AnalyticsEvents.clickSaleReminder,
    {AnalyticsParams.saleType: saleType},
  );
}
