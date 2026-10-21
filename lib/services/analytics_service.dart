import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Service abstraction for Firebase Analytics
/// Strictly adheres to the Analytics Plan in docs/analytics-plan.md (No PII)
class AppAnalyticsService {
  final FirebaseAnalytics _analytics;

  AppAnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get analyticsObserver =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// Set user ID upon sign-in
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      debugPrint('Analytics setUserId error: $e');
    }
  }

  /// Event 1: login
  Future<void> logLogin({String method = 'google'}) async {
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (e) {
      debugPrint('Analytics logLogin error: $e');
    }
  }

  /// Event 2: search
  Future<void> logSearch({
    required String searchTerm,
    required int resultCount,
  }) async {
    try {
      await _analytics.logSearch(
        searchTerm: searchTerm,
        parameters: {'result_count': resultCount},
      );
    } catch (e) {
      debugPrint('Analytics logSearch error: $e');
    }
  }

  /// Event 3: add_to_wishlist
  Future<void> logAddToWishlist({
    required String motive,
    required double price,
    required bool hasSaleDate,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'add_to_wishlist',
        parameters: {
          'motive': motive,
          'item_price': price,
          'has_sale_date': hasSaleDate ? 1 : 0,
        },
      );
    } catch (e) {
      debugPrint('Analytics logAddToWishlist error: $e');
    }
  }

  /// Event 4: view_item_detail
  Future<void> logViewItemDetail({
    required String itemId,
    required String motive,
    required int daysInCooldown,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'view_item_detail',
        parameters: {
          'item_id': itemId,
          'motive': motive,
          'days_in_cooldown': daysInCooldown,
        },
      );
    } catch (e) {
      debugPrint('Analytics logViewItemDetail error: $e');
    }
  }

  /// Event 5: make_decision
  Future<void> logMakeDecision({
    required String action,
    required String motive,
    required double savedAmount,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'make_decision',
        parameters: {
          'action': action,
          'motive': motive,
          'saved_amount': savedAmount,
        },
      );
    } catch (e) {
      debugPrint('Analytics logMakeDecision error: $e');
    }
  }

  /// Event 6: export_report
  Future<void> logExportReport({
    required String fileFormat,
    required int fileSizeKb,
    required int itemCount,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'export_report',
        parameters: {
          'file_format': fileFormat,
          'file_size_kb': fileSizeKb,
          'item_count': itemCount,
        },
      );
    } catch (e) {
      debugPrint('Analytics logExportReport error: $e');
    }
  }

  /// Event 7: logout
  Future<void> logLogout({int? sessionDurationSec}) async {
    try {
      final params = <String, Object>{};
      if (sessionDurationSec != null) {
        params['session_duration_sec'] = sessionDurationSec;
      }
      await _analytics.logEvent(
        name: 'logout',
        parameters: params.isNotEmpty ? params : null,
      );
    } catch (e) {
      debugPrint('Analytics logLogout error: $e');
    }
  }

  /// Event 8: click_sale_reminder
  Future<void> logClickSaleReminder(String saleType) async {
    try {
      await _analytics.logEvent(
        name: 'click_sale_reminder',
        parameters: {'sale_type': saleType},
      );
    } catch (e) {
      debugPrint('Analytics logClickSaleReminder error: $e');
    }
  }
}
