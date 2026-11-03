import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../firebase/platform_support.dart';

/// Local notifications of the app:
/// * on the review date chosen with "Chờ" (spec A-09, E12). When notifications are
///   unavailable or denied, the "Cần xem lại" list in the app is the fallback;
/// * the daily "Nhắc ghi khoản mua" (screen 05a, Cá nhân), off until the user turns it on;
/// * "Nhắc đợt sale" at 20:00 the evening before a confirmed sale (spec 8.2, A-13).
/// Every method here may silently do nothing.
abstract interface class ReviewReminderService {
  /// Android/iOS only. flutter_local_notifications is pinned to 18.0.1, the last version
  /// without a Windows implementation (its Windows plugin needs Visual Studio ATL).
  bool get isSupported;

  /// [onOpen] runs when the user taps a review reminder while the app is running,
  /// [onOpenDaily] when they tap the daily reminder. [onOpenSale] gets the same data
  /// as a sale push (`type`, `sale_type`, `sale_id`), also when the tap started the app.
  Future<void> initialize({
    VoidCallback? onOpen,
    VoidCallback? onOpenDaily,
    void Function(Map<String, dynamic> data)? onOpenSale,
  });

  /// The app was started by tapping a review reminder; true only once
  bool consumeLaunchedFromReminder();

  /// The app was started by tapping the daily reminder; true only once
  bool consumeLaunchedFromDailyReminder();

  /// Asks for permission. Call only from the user's tap ("Chờ", "Bật nhắc nhở").
  /// true = may notify.
  Future<bool> requestPermission();

  Future<void> schedule({
    required String itemId,
    required String title,
    required DateTime at,
  });

  Future<void> cancel(String itemId);

  /// Cancels every review reminder; the daily reminder belongs to the device and stays
  Future<void> cancelAll();

  /// Repeats every day at [hour]:[minute] local time; replaces the previous time
  Future<void> scheduleDaily({required int hour, required int minute});

  Future<void> cancelDaily();

  /// Replaces every scheduled sale reminder with [reminders]; empty cancels them all
  Future<void> scheduleSaleReminders(
    List<({String saleId, String saleType, String body, DateTime at})>
    reminders,
  );

  /// Displays an immediate system notification on the status bar (for FCM alerts & Crashlytics test events)
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  });
}

class LocalReviewReminderService implements ReviewReminderService {
  static const String _channelId = 'review_reminders';
  static const String _channelName = 'Nhắc xem lại';
  static const String _dailyChannelId = 'daily_record_reminder';
  static const String _dailyChannelName = 'Nhắc ghi khoản mua';
  static const String _alertChannelId = 'app_immediate_alerts';
  static const String _alertChannelName = 'Thông báo trực tiếp';

  /// Review ids come from [idFor] (31-bit hashes of item ids); a fixed small id for
  /// the single daily reminder
  static const int dailyId = 1;
  static const String dailyPayload = 'daily_record_reminder';
  static const String _saleChannelId = 'sale_reminders';
  static const String _saleChannelName = 'Nhắc đợt sale';

  /// Payload of a sale reminder: `sale:<saleId>|<saleType>`
  static const String salePayloadPrefix = 'sale:';

  static String salePayload(String saleId, String saleType) =>
      '$salePayloadPrefix$saleId|$saleType';

  /// The data a sale push carries, so both open the same screen
  static Map<String, dynamic>? saleDataFrom(String? payload) {
    if (payload == null || !payload.startsWith(salePayloadPrefix)) return null;
    final parts = payload.substring(salePayloadPrefix.length).split('|');
    return {
      'type': 'sale',
      'sale_id': parts.first,
      if (parts.length > 1) 'sale_type': parts[1],
    };
  }

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  bool _launchedFromReminder = false;
  bool _launchedFromDaily = false;

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
  Future<void> initialize({
    VoidCallback? onOpen,
    VoidCallback? onOpenDaily,
    void Function(Map<String, dynamic> data)? onOpenSale,
  }) async {
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
        onDidReceiveNotificationResponse: (response) {
          final sale = saleDataFrom(response.payload);
          if (sale != null) {
            onOpenSale?.call(sale);
          } else if (response.payload == dailyPayload) {
            onOpenDaily?.call();
          } else {
            onOpen?.call();
          }
        },
      );
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        final payload = launch?.notificationResponse?.payload;
        final sale = saleDataFrom(payload);
        if (sale != null) {
          // Kept until the signed-in shell is shown (openFromNotification)
          onOpenSale?.call(sale);
        } else {
          final isDaily = payload == dailyPayload;
          _launchedFromDaily = isDaily;
          _launchedFromReminder = !isDaily;
        }
      }
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
  bool consumeLaunchedFromDailyReminder() {
    final launched = _launchedFromDaily;
    _launchedFromDaily = false;
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
      final pending = await _plugin.pendingNotificationRequests();
      for (final request in pending) {
        // Daily and sale reminders are not review reminders
        if (request.id == dailyId ||
            (request.payload?.startsWith(salePayloadPrefix) ?? false)) {
          continue;
        }
        await _plugin.cancel(request.id);
      }
    } catch (e) {
      debugPrint('ReviewReminder cancelAll error: $e');
    }
  }

  @override
  Future<void> scheduleDaily({required int hour, required int minute}) async {
    if (!_initialized) return;
    try {
      final now = tz.TZDateTime.now(tz.local);
      var first = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      if (!first.isAfter(now)) first = first.add(const Duration(days: 1));
      await _plugin.zonedSchedule(
        dailyId,
        'Why I Buy?',
        'Hôm nay bạn có mua gì không? Ghi lại trong 10 giây.',
        first,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _dailyChannelId,
            _dailyChannelName,
            channelDescription: 'Nhắc mỗi ngày ghi lại khoản mua trong ngày',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: dailyPayload,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        // Same time every day
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('ReviewReminder scheduleDaily error: $e');
    }
  }

  @override
  Future<void> cancelDaily() async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(dailyId);
    } catch (e) {
      debugPrint('ReviewReminder cancelDaily error: $e');
    }
  }

  @override
  Future<void> scheduleSaleReminders(
    List<({String saleId, String saleType, String body, DateTime at})>
    reminders,
  ) async {
    if (!_initialized) return;
    try {
      final pending = await _plugin.pendingNotificationRequests();
      for (final request in pending) {
        if (request.payload?.startsWith(salePayloadPrefix) ?? false) {
          await _plugin.cancel(request.id);
        }
      }
      for (final r in reminders) {
        if (!r.at.isAfter(DateTime.now())) continue;
        await _plugin.zonedSchedule(
          idFor('$salePayloadPrefix${r.saleId}'),
          'Nhắc đợt sale',
          r.body,
          tz.TZDateTime.from(r.at, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _saleChannelId,
              _saleChannelName,
              channelDescription: '20:00 tối trước đợt sale đã xác nhận',
            ),
            iOS: DarwinNotificationDetails(),
          ),
          payload: salePayload(r.saleId, r.saleType),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (e) {
      debugPrint('ReviewReminder scheduleSaleReminders error: $e');
    }
  }

  @override
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!isSupported || !_initialized) return;
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _alertChannelId,
          _alertChannelName,
          channelDescription: 'Thông báo sự kiện và thử nghiệm Lab 3',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      );
      await _plugin.show(id, title, body, details, payload: payload);
    } catch (e) {
      debugPrint('ReviewReminder showImmediateNotification error: $e');
    }
  }
}
