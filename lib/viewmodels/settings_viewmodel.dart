import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';
import '../services/crashlytics_service.dart';
import '../services/demo_data_service.dart';
import '../services/notification_service.dart';
import '../services/remote_config_service.dart';
import '../services/user_service.dart';
import 'deferred_notify.dart';

/// ViewModel managing Firebase Demo Area (Crashlytics, Remote Config, FCM notifications)
class SettingsViewModel extends ChangeNotifier with DeferredNotify {
  final RemoteConfigService remoteConfigService;
  final CrashlyticsService crashlyticsService;
  final NotificationService notificationService;
  final UserService userService;
  final DemoDataService demoDataService;

  StreamSubscription<List<AppNotificationItem>>? _notifSubscription;
  StreamSubscription<UserSettings>? _settingsSubscription;
  String? _uid;
  UserSettings _settings = const UserSettings();
  bool _isDemoBusy = false;
  List<AppNotificationItem> _notifications = [];
  bool _isRefreshingConfig = false;

  SettingsViewModel({
    required this.remoteConfigService,
    required this.crashlyticsService,
    required this.notificationService,
    required this.userService,
    required this.demoDataService,
  }) {
    _init();
  }

  /// users/{uid}.settings; defaults while signed out or not loaded
  UserSettings get settings => _settings;

  /// The user's own value when set, otherwise Remote Config `cooling_off_days`
  int get coolingOffDays =>
      _settings.coolingOffDays ?? remoteConfigService.coolingOffDays;
  bool get isCoolingOffFromUser => _settings.coolingOffDays != null;

  // Remote Config Values
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

  /// Called by the provider whenever the signed-in user changes
  void updateUid(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _settingsSubscription?.cancel();
    _settingsSubscription = null;
    _settings = const UserSettings();
    notifyLater();
    if (uid == null) return;
    _settingsSubscription = userService.watchSettings(uid).listen((settings) {
      _settings = settings;
      notifyListeners();
    }, onError: (Object e) => debugPrint('watchSettings error: $e'));
  }

  Future<bool> updateSettings(UserSettings settings) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      await userService.updateSettings(uid, settings);
      return true;
    } catch (e) {
      debugPrint('updateSettings error: $e');
      return false;
    }
  }

  /// Seeding or clearing is running
  bool get isDemoBusy => _isDemoBusy;

  /// Firebase Demo Area: writes demo purchases, wishlist, budget and reflection
  Future<bool> seedDemoData() =>
      _runDemo((uid) => demoDataService.seed(uid), 'seedDemoData');

  /// Firebase Demo Area: deletes all of the user's data (keeps profile + budget groups)
  Future<bool> clearAllData() =>
      _runDemo((uid) => demoDataService.clearAll(uid), 'clearAllData');

  Future<bool> _runDemo(
    Future<void> Function(String uid) action,
    String reason,
  ) async {
    final uid = _uid;
    if (uid == null || _isDemoBusy) return false;
    _isDemoBusy = true;
    notifyListeners();
    try {
      await action(uid);
      return true;
    } catch (e, stack) {
      await crashlyticsService.recordHandledError(e, stack, reason: reason);
      return false;
    } finally {
      _isDemoBusy = false;
      notifyListeners();
    }
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
    _settingsSubscription?.cancel();
    super.dispose();
  }
}
