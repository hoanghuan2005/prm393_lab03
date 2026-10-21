import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

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
  final FirebaseMessaging _fcm;
  final List<AppNotificationItem> _receivedNotifications = [];
  final _notificationsStreamController =
      StreamController<List<AppNotificationItem>>.broadcast();

  NotificationService({FirebaseMessaging? fcm})
      : _fcm = fcm ?? FirebaseMessaging.instance;

  List<AppNotificationItem> get receivedNotifications =>
      List.unmodifiable(_receivedNotifications);

  Stream<List<AppNotificationItem>> get notificationsStream =>
      _notificationsStreamController.stream;

  /// Initialize FCM, request permissions, and register listeners
  Future<void> initialize({
    Function(RemoteMessage message)? onNotificationOpened,
  }) async {
    try {
      // 1. Request notification permission (Crucial for Android 13+)
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('FCM Authorization status: ${settings.authorizationStatus}');

      // 2. Register background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground message received: ${message.notification?.title}');
        _recordNotification(message);
      });

      // 4. Background notification opened listener
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM Notification tapped to open app: ${message.data}');
        _recordNotification(message);
        onNotificationOpened?.call(message);
      });

      // 5. Terminated state notification tap
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('FCM App opened from terminated message: ${initialMessage.data}');
        _recordNotification(initialMessage);
        onNotificationOpened?.call(initialMessage);
      }

      // Log FCM Token
      // ignore: deprecated_member_use
      final token = await _fcm.getToken();
      debugPrint('FCM Device Token: $token');
    } catch (e) {
      debugPrint('NotificationService initialize error: $e');
    }
  }

  void _recordNotification(RemoteMessage message) {
    final item = AppNotificationItem(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'Thông báo Why I Buy',
      body: message.notification?.body ?? '',
      receivedAt: DateTime.now(),
      data: message.data,
    );
    _receivedNotifications.insert(0, item);
    _notificationsStreamController.add(List.unmodifiable(_receivedNotifications));
  }

  void dispose() {
    _notificationsStreamController.close();
  }
}
