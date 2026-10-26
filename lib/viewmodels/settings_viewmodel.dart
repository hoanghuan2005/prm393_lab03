import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/crashlytics_service.dart';
import '../services/notification_service.dart';
import '../services/remote_config_service.dart';

/// ViewModel managing Firebase Demo Area (Crashlytics, Remote Config, FCM notifications)
class SettingsViewModel extends ChangeNotifier {
  final RemoteConfigService remoteConfigService;
  final CrashlyticsService crashlyticsService;
  final NotificationService notificationService;

  StreamSubscription<List<AppNotificationItem>>? _notifSubscription;
  List<AppNotificationItem> _notifications = [];
  bool _isRefreshingConfig = false;

  SettingsViewModel({
    required this.remoteConfigService,
    required this.crashlyticsService,
    required this.notificationService,
  }) {
    _init();
  }

  // Remote Config Values
  int get coolingOffDays => remoteConfigService.coolingOffDays;
  bool get enableAiInsight => remoteConfigService.enableAiInsight;
  int get maxWishlistItems => remoteConfigService.maxWishlistItems;
  bool get saleReminderEnabled => remoteConfigService.saleReminderEnabled;
  bool get isRefreshingConfig => _isRefreshingConfig;

  // FCM Notifications
  List<AppNotificationItem> get notifications => _notifications;

  void _init() {
    _notifications = notificationService.receivedNotifications;
    _notifSubscription = notificationService.notificationsStream.listen((list) {
      _notifications = list;
      notifyListeners();
    });
  }

  /// Live refresh Remote Config without rebuild
  Future<void> refreshRemoteConfig() async {
    _isRefreshingConfig = true;
    notifyListeners();

    try {
      await remoteConfigService.fetchAndActivate();
    } catch (e) {
      debugPrint('Error refreshing remote config: $e');
    } finally {
      _isRefreshingConfig = false;
      notifyListeners();
    }
  }

  /// Trigger a test non-fatal error recorded in Crashlytics
  Future<void> testHandledNonFatalError(String userId) async {
    try {
      throw FormatException(
        'Simulated non-fatal exception for Lab 3 validation (UID: $userId)',
      );
    } catch (e, stack) {
      await crashlyticsService.recordHandledError(
        e,
        stack,
        reason: 'Firebase Demo Screen: Handled error test',
        customKeys: {
          'demo_action': 'non_fatal_test_trigger',
          'user_id': userId,
          'screen': 'ProfileScreen/FirebaseDemo',
        },
      );
    }
  }

  /// Trigger a forced test crash for Crashlytics dashboard evidence
  void testForcedCrash() {
    crashlyticsService.forceCrashForTesting();
  }

  @override
  void dispose() {
    _notifSubscription?.cancel();
    super.dispose();
  }
}
