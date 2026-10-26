import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../firebase/platform_support.dart';

/// Local notification on the review date chosen with "Chờ" (spec A-09, E12).
/// When notifications are unavailable or denied, the "Cần xem lại" list in the app
/// is the fallback, so every method here may silently do nothing.
abstract interface class ReviewReminderService {
  /// Android/iOS only. flutter_local_notifications is pinned to 18.0.1, the last version
  /// without a Windows implementation (its Windows plugin needs Visual Studio ATL).
  bool get isSupported;

  /// [onOpen] runs when the user taps a reminder while the app is running
  Future<void> initialize({VoidCallback? onOpen});

  /// The app was started by tapping a reminder; true only once
  bool consumeLaunchedFromReminder();

  /// Asks for permission. Call only right after the user chose "Chờ". true = may notify.
  Future<bool> requestPermission();

  Future<void> schedule({
    required String itemId,
    required String title,
    required DateTime at,
  });

  Future<void> cancel(String itemId);

  Future<void> cancelAll();
}

class LocalReviewReminderService implements ReviewReminderService {
  static const String _channelId = 'review_reminders';
  static const String _channelName = 'Nhắc xem lại';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  bool _launchedFromReminder = false;

  LocalReviewReminderService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  @override
  bool get isSupported => PlatformSupport.isMobile;

  /// Notification ids must be stable across app runs; String.hashCode is not
  static int idFor(String itemId) {
    var hash = 0x811c9dc5;
    for (final unit in itemId.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  @override
  Future<void> initialize({VoidCallback? onOpen}) async {
    if (!isSupported || _initialized) return;
    try {
      tz_data.initializeTimeZones();
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (e) {
      // Unknown zone name: keep the package default; reviews are at 09:00 local anyway
      debugPrint('ReviewReminder timezone error: $e');
    }
    try {
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (_) => onOpen?.call(),
      );
      final launch = await _plugin.getNotificationAppLaunchDetails();
      _launchedFromReminder = launch?.didNotificationLaunchApp ?? false;
      _initialized = true;
    } catch (e) {
      debugPrint('ReviewReminder initialize error: $e');
    }
  }

  @override
  bool consumeLaunchedFromReminder() {
    final launched = _launchedFromReminder;
    _launchedFromReminder = false;
    return launched;
  }

  @override
  Future<bool> requestPermission() async {
    if (!_initialized) return false;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await ios?.requestPermissions(alert: true, sound: true) ?? false;
    } catch (e) {
      debugPrint('ReviewReminder permission error: $e');
      return false;
    }
  }

  @override
  Future<void> schedule({
    required String itemId,
    required String title,
    required DateTime at,
  }) async {
    if (!_initialized || !at.isAfter(DateTime.now())) return;
    try {
      await _plugin.zonedSchedule(
        idFor(itemId),
        'Đến hẹn xem lại',
        // Neutral wording (spec 4.3): no "nên mua", no price pressure
        '"$title": bạn hẹn xem lại món này hôm nay. Mua, Chờ hay Bỏ qua đều được.',
        tz.TZDateTime.from(at, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Nhắc vào ngày bạn chọn khi bấm Chờ',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: itemId,
        // A few minutes late is fine for a review; avoids the exact-alarm permission
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('ReviewReminder schedule error: $e');
    }
  }

  @override
  Future<void> cancel(String itemId) async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(idFor(itemId));
    } catch (e) {
      debugPrint('ReviewReminder cancel error: $e');
    }
  }

  @override
  Future<void> cancelAll() async {
    if (!_initialized) return;
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('ReviewReminder cancelAll error: $e');
    }
  }
}
