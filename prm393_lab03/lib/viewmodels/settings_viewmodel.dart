import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/errors/describe_error.dart';
import '../core/utils/purchase_csv.dart';
import '../firebase/platform_support.dart';
import '../models/app_notification_item.dart';
import '../models/budget_group.dart';
import '../models/purchase_item.dart';
import '../models/reflection.dart';
import '../models/user_profile.dart';
import '../services/crashlytics_service.dart';
import '../services/data_export_service.dart';
import '../services/demo_data_service.dart';
import '../services/feedback_service.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';
import '../services/remote_config_service.dart';
import '../services/review_reminder_service.dart';
import '../services/user_service.dart';
import 'deferred_notify.dart';
import 'error_reporting.dart';

/// Result of "Xuất dữ liệu"
sealed class ExportResult {
  const ExportResult();
}

/// [fileName] includes the extension, e.g. `whyibuy-10-2026.csv`
class ExportSaved extends ExportResult {
  final String fileName;
  const ExportSaved(this.fileName);
}

class ExportNothing extends ExportResult {
  const ExportNothing();
}

class ExportFailed extends ExportResult {
  const ExportFailed();
}

/// Cá nhân: reminders (05a), data export, feedback, and the Firebase Demo Area
/// (Crashlytics, Remote Config, FCM notifications)
class SettingsViewModel extends ChangeNotifier
    with DeferredNotify, ErrorReporting {
  final RemoteConfigService remoteConfigService;
  @override
  final CrashlyticsService crashlyticsService;
  final NotificationService notificationService;
  final UserService userService;
  final DemoDataService demoDataService;
  final ReviewReminderService? reminderService;
  final PreferencesService? preferencesService;
  final DataExportService? exportService;
  final FeedbackService? feedbackService;

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
    this.reminderService,
    this.preferencesService,
    this.exportService,
    this.feedbackService,
  }) {
    _init();
  }

  // ---------- Daily "Nhắc ghi khoản mua" (screen 05a, Cá nhân) ----------

  bool _dailyReminderEnabled = false;
  int _dailyReminderMinutes = PreferencesService.defaultDailyReminderMinutes;

  /// Local notifications exist on Android/iOS only
  bool get supportsDailyReminder =>
      (reminderService?.isSupported ?? false) && preferencesService != null;
  bool get dailyReminderEnabled => _dailyReminderEnabled;
  int get dailyReminderHour => _dailyReminderMinutes ~/ 60;
  int get dailyReminderMinute => _dailyReminderMinutes % 60;

  /// "21:00"
  String get dailyReminderTimeText =>
      '${dailyReminderHour.toString().padLeft(2, '0')}:'
      '${dailyReminderMinute.toString().padLeft(2, '0')}';

  Future<void> _loadDailyReminder() async {
    final prefs = preferencesService;
    if (prefs == null) return;
    _dailyReminderEnabled = await prefs.getDailyReminderEnabled();
    _dailyReminderMinutes = await prefs.getDailyReminderMinutes();
    notifyListeners();
    // Re-arm after an app update or a time zone change; replacing is harmless
    if (_dailyReminderEnabled && supportsDailyReminder) {
      await reminderService!.scheduleDaily(
        hour: dailyReminderHour,
        minute: dailyReminderMinute,
      );
    }
  }

  // ---------- "Nhắc chiêm nghiệm" at the end of each month ----------

  bool _reflectionReminderEnabled = false;

  bool get reflectionReminderEnabled => _reflectionReminderEnabled;

  Future<void> _armReflectionReminders() async => reminderService
      ?.scheduleReflectionReminders(reflectionReminderTimes(DateTime.now()));

  Future<void> _loadReflectionReminder() async {
    final prefs = preferencesService;
    if (prefs == null) return;
    _reflectionReminderEnabled = await prefs.getReflectionReminderEnabled();
    notifyListeners();
    // Only a few months are scheduled ahead: top them up on every start
    if (_reflectionReminderEnabled && supportsDailyReminder) {
      await _armReflectionReminders();
    }
  }

  /// From the user's tap on the switch. false = permission denied.
  Future<bool> enableReflectionReminder() async {
    final reminders = reminderService;
    final prefs = preferencesService;
    if (!supportsDailyReminder || reminders == null || prefs == null) {
      return false;
    }
    if (!await reminders.requestPermission()) return false;
    await _armReflectionReminders();
    await prefs.setReflectionReminderEnabled(true);
    _reflectionReminderEnabled = true;
    notifyListeners();
    return true;
  }

  Future<void> disableReflectionReminder() async {
    await reminderService?.scheduleReflectionReminders(const []);
    await preferencesService?.setReflectionReminderEnabled(false);
    _reflectionReminderEnabled = false;
    notifyListeners();
  }

  /// Screen 05a after the first saved purchase: only once per device, only where
  /// reminders work, and not when the reminder is already on
  Future<bool> shouldOfferDailyReminder() async {
    final prefs = preferencesService;
    if (!supportsDailyReminder || prefs == null || _dailyReminderEnabled) {
      return false;
    }
    return !await prefs.getDailyReminderOffered();
  }

  Future<void> markDailyReminderOffered() async =>
      preferencesService?.setDailyReminderOffered();

  /// From the user's tap ("Bật nhắc nhở" or the switch). false = permission denied.
  Future<bool> enableDailyReminder() async {
    final reminders = reminderService;
    final prefs = preferencesService;
    if (!supportsDailyReminder || reminders == null || prefs == null) {
      return false;
    }
    final granted = await reminders.requestPermission();
    if (!granted) return false;
    await reminders.scheduleDaily(
      hour: dailyReminderHour,
      minute: dailyReminderMinute,
    );
    await prefs.setDailyReminderEnabled(true);
    _dailyReminderEnabled = true;
    notifyListeners();
    return true;
  }

  Future<void> disableDailyReminder() async {
    await reminderService?.cancelDaily();
    await preferencesService?.setDailyReminderEnabled(false);
    _dailyReminderEnabled = false;
    notifyListeners();
  }

  Future<void> setDailyReminderTime(int hour, int minute) async {
    final prefs = preferencesService;
    if (prefs == null) return;
    _dailyReminderMinutes = (hour * 60 + minute).clamp(0, 24 * 60 - 1);
    await prefs.setDailyReminderMinutes(_dailyReminderMinutes);
    notifyListeners();
    if (_dailyReminderEnabled) {
      await reminderService?.scheduleDaily(
        hour: dailyReminderHour,
        minute: dailyReminderMinute,
      );
    }
  }

  // ---------- "Xuất dữ liệu" (CSV) ----------

  bool _isExporting = false;
  bool get isExporting => _isExporting;

  Future<ExportResult> exportPurchasesCsv(
    List<PurchaseItem> purchases,
    List<BudgetGroup> groups, {
    DateTime? now,
  }) async {
    final exporter = exportService;
    if (exporter == null || _isExporting) return const ExportFailed();
    if (purchases.isEmpty) return const ExportNothing();
    _isExporting = true;
    notifyListeners();
    try {
      final name = PurchaseCsv.fileName(now ?? DateTime.now());
      await exporter.saveCsv(name, PurchaseCsv.build(purchases, groups));
      return ExportSaved('$name.csv');
    } catch (e, stack) {
      await crashlyticsService.recordHandledError(
        e,
        stack,
        reason: 'exportPurchasesCsv',
      );
      return const ExportFailed();
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  // ---------- "Gửi góp ý" ----------

  bool _isSendingFeedback = false;
  bool get isSendingFeedback => _isSendingFeedback;

  /// null on success, otherwise a Vietnamese message to show
  Future<String?> sendFeedback(String message) async {
    final uid = _uid;
    final service = feedbackService;
    if (uid == null || service == null) {
      return 'Bạn cần đăng nhập để gửi góp ý.';
    }
    if (message.trim().isEmpty) return 'Bạn chưa viết góp ý.';
    if (_isSendingFeedback) return null;
    _isSendingFeedback = true;
    notifyListeners();
    try {
      await service.send(uid, message);
      return null;
    } catch (e, stack) {
      return messageFor(e, stack, reason: 'sendFeedback');
    } finally {
      _isSendingFeedback = false;
      notifyListeners();
    }
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

  /// Notification permission is asked from a tap (here or right after "Chờ"), never on
  /// launch, on every platform that has Cloud Messaging
  bool get asksNotificationPermissionInApp => PlatformSupport.supportsMessaging;
  bool _notificationsEnabled = false;
  bool get notificationsEnabled => _notificationsEnabled;

  /// Must be called from a user's tap
  /// After a refused request: the system settings are the only way to allow them
  Future<bool> openNotificationSettings() =>
      notificationService.openSystemSettings();

  Future<bool> enableNotifications() async {
    _notificationsEnabled = await notificationService
        .requestPermissionFromUser();
    notifyListeners();
    return _notificationsEnabled;
  }

  void _init() {
    unawaited(_loadDailyReminder());
    unawaited(_loadReflectionReminder());
    if (PlatformSupport.supportsMessaging) {
      unawaited(
        notificationService.isPermissionGranted().then((granted) {
          _notificationsEnabled = granted;
          notifyListeners();
        }),
      );
    }
    _notifications = notificationService.receivedNotifications;
    _notifSubscription = notificationService.notificationsStream.listen((list) {
      _notifications = list;
      notifyListeners();
    });
  }

  /// Called by the provider whenever the signed-in user changes
  void updateUid(String? uid) {
    if (uid == _uid) return;
    // Leaving an account (not the first sign-in, whose launch message must survive)
    if (_uid != null) unawaited(notificationService.clearReceived());
    _uid = uid;
    _settingsSubscription?.cancel();
    _settingsSubscription = null;
    _settings = const UserSettings();
    notifyLater();
    if (uid == null) return;
    _settingsSubscription = userService.watchSettings(uid).listen(
      (settings) {
        _settings = settings;
        notifyListeners();
      },
      onError: (Object e, StackTrace s) =>
          messageFor(e, s, reason: 'watchSettings'),
    );
  }

  Future<bool> updateSettings(UserSettings settings) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      await userService.updateSettings(uid, settings);
      return true;
    } catch (e, stack) {
      messageFor(e, stack, reason: 'updateSettings');
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
      // Re-filter the list for sale_reminder_enabled now, not on the next message
      unawaited(notificationService.reload());
    } catch (e) {
      debugPrint('Error refreshing remote config: ${describeError(e)}');
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
      await crashlyticsService.logCrashToFirestore(
        feature: 'ProfileDemo (Non-Fatal)',
        errorCode: 'ERR_NON_FATAL_TEST',
        errorMessage: 'Simulated non-fatal exception for Lab 3 validation (UID: $userId)',
        stackTrace: stack.toString(),
        severity: 'warning',
      );

      await reminderService?.showImmediateNotification(
        id: 998,
        title: 'Đã ghi lỗi có xử lý (Crashlytics)',
        body: 'Lỗi thử đã được gửi lên Firebase Crashlytics & Admin Web.',
      );
    }
  }

  /// Trigger a forced test crash for Crashlytics dashboard evidence
  Future<void> testForcedCrash({String? userId}) async {
    await reminderService?.showImmediateNotification(
      id: 999,
      title: 'Sắp crash thử (Crashlytics & Admin Web)',
      body: 'App sẽ đóng để gửi báo cáo crash lên Firebase Crashlytics.',
    );
    final effectiveUid = userId ?? _uid ?? 'anonymous';
    await crashlyticsService.logCrashToFirestore(
      feature: 'ProfileDemo (Forced Crash)',
      errorCode: 'FATAL_TEST_CRASH',
      errorMessage: 'Kích hoạt thử nghiệm Crash thật từ Profile Demo (UID: $effectiveUid)',
      stackTrace: StackTrace.current.toString(),
      severity: 'fatal',
    );
    await Future.delayed(const Duration(milliseconds: 600));
    crashlyticsService.forceCrashForTesting();
  }

  /// Shows a local notification; it does not go through FCM
  Future<void> sendTestNotification() async {
    await reminderService?.showImmediateNotification(
      id: 1001,
      title: 'Thử thông báo trên máy',
      body: 'Đây là thông báo cục bộ do app tạo, không đi qua Firebase Cloud Messaging.',
    );
  }

  @override
  void dispose() {
    _notifSubscription?.cancel();
    _settingsSubscription?.cancel();
    super.dispose();
  }
}
