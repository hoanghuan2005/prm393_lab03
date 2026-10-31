import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase/platform_support.dart';
import '../models/notification_target.dart';

/// App notification model to keep an in-app list of received messages
class AppNotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
  final Map<String, dynamic> data;

  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    required this.data,
  });
}

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');
}

/// Service abstraction for Firebase Cloud Messaging (FCM)
class NotificationService {
  /// Injected for testing; otherwise resolved lazily via getter.
  final FirebaseMessaging? _injectedFcm;
  FirebaseMessaging get _fcm => _injectedFcm ?? FirebaseMessaging.instance;

  final List<AppNotificationItem> _receivedNotifications = [];
  final _notificationsStreamController =
      StreamController<List<AppNotificationItem>>.broadcast();

  /// Remote Config `sale_reminder_enabled`; while off, sale messages are not kept in the
  /// in-app list and a tap on one only opens the app
  final bool Function() _saleRemindersEnabled;

  NotificationService({
    FirebaseMessaging? fcm,
    bool Function()? saleRemindersEnabled,
  }) : _injectedFcm = fcm,
       _saleRemindersEnabled = saleRemindersEnabled ?? (() => true);

  List<AppNotificationItem> get receivedNotifications =>
      List.unmodifiable(_receivedNotifications);

  Stream<List<AppNotificationItem>> get notificationsStream =>
      _notificationsStreamController.stream;

  /// Initialize FCM and register listeners. Permission is never asked here: it is asked
  /// right after the user chooses "Chờ" or taps "Bật thông báo" in Cá nhân (spec A-09).
  /// Asking on launch would spend Android's limited prompts and may get a web site blocked.
  Future<void> initialize({
    void Function(Map<String, dynamic> data)? onNotificationOpened,
  }) async {
    if (!PlatformSupport.supportsMessaging) {
      debugPrint(
        'NotificationService: FCM skipped (no plugin on this platform)',
      );
      return;
    }
    try {
      final current = await _fcm.getNotificationSettings();
      debugPrint('FCM permission: ${current.authorizationStatus}');

      // Background messages: native handler on mobile, web/firebase-messaging-sw.js on web
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );
      }

      // 3. Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
          'FCM Foreground message received: ${message.notification?.title}',
        );
        recordNotification(message);
      });

      // 4. Background notification opened listener
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM Notification tapped to open app: ${message.data}');
        recordNotification(message);
        onNotificationOpened?.call(message.data);
      });

      // 5. Terminated state notification tap
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
          'FCM App opened from terminated message: ${initialMessage.data}',
        );
        recordNotification(initialMessage);
        onNotificationOpened?.call(initialMessage.data);
      }

      // On web getToken itself would open the browser prompt; wait for the user's click
      if (!kIsWeb || await isPermissionGranted()) await _logToken();
    } catch (e) {
      debugPrint('NotificationService initialize error: $e');
    }
  }

  Future<void> _logToken() async {
    // ignore: deprecated_member_use
    final token = await _fcm.getToken();
    debugPrint('FCM Device Token: $token');
  }

  /// Notifications are allowed for this app (web: for this site)
  Future<bool> isPermissionGranted() async {
    if (!PlatformSupport.supportsMessaging) return false;
    try {
      final settings = await _fcm.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      debugPrint('NotificationService permission check error: $e');
      return false;
    }
  }

  /// Asks for permission (Android 13+ / browser). Must run from a user's tap.
  Future<bool> requestPermissionFromUser() async {
    if (!PlatformSupport.supportsMessaging) return false;
    try {
      final settings = await _fcm.requestPermission();
      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized;
      if (granted) await _logToken();
      return granted;
    } catch (e) {
      debugPrint('NotificationService requestPermission error: $e');
      return false;
    }
  }

  /// Adds a message to the in-app list ("Thông báo đã nhận" in Cá nhân)
  @visibleForTesting
  void recordNotification(RemoteMessage message) {
    if (NotificationRoute.isSale(message.data) && !_saleRemindersEnabled()) {
      debugPrint('FCM sale reminder ignored: sale_reminder_enabled is off');
      return;
    }
    final item = AppNotificationItem(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'Thông báo Why I Buy',
      body: message.notification?.body ?? '',
      receivedAt: DateTime.now(),
      data: message.data,
    );
    _receivedNotifications.insert(0, item);
    _notificationsStreamController.add(
      List.unmodifiable(_receivedNotifications),
    );
  }

  /// Forgets messages received in the previous session (sign-out / account switch)
  void clearReceived() {
    if (_receivedNotifications.isEmpty) return;
    _receivedNotifications.clear();
    _notificationsStreamController.add(const []);
  }

  void dispose() {
    _notificationsStreamController.close();
  }
}
