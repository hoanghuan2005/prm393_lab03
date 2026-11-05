import 'dart:async';
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/errors/describe_error.dart';
import '../firebase/platform_support.dart';
import '../models/app_notification_item.dart';
import '../models/notification_target.dart';
import 'notification_history_store.dart';

/// Converts an FCM message for the notification history. [receivedAt] is the send
/// time when known, not the time it was recorded.
AppNotificationItem notificationItemFromMessage(
  RemoteMessage message,
  NotificationSource source,
) {
  final sentTime = message.sentTime;
  return AppNotificationItem(
    id:
        message.messageId ??
        (sentTime ?? DateTime.now()).millisecondsSinceEpoch.toString(),
    title: message.notification?.title ?? 'Thông báo Why I Buy',
    body: message.notification?.body ?? '',
    receivedAt: sentTime ?? DateTime.now(),
    data: {
      for (final entry in message.data.entries)
        if (entry.value != null) entry.key: '${entry.value}',
    },
    source: source,
  );
}

/// Top-level background message handler for FCM. Runs in its own isolate: only
/// saves the message on the device (no Remote Config, Analytics, Crashlytics or
/// Firestore here). Sale messages are filtered when shown, not here.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // This isolate has no plugins registered yet; shared_preferences needs them
  DartPluginRegistrant.ensureInitialized();
  try {
    final item = notificationItemFromMessage(
      message,
      NotificationSource.background,
    );
    final change = await SharedPrefsNotificationHistoryStore().add(item);
    if (change == HistoryChange.added) {
      debugPrint('FCM background message saved: ${item.id}');
    }
  } catch (e) {
    debugPrint('FCM background message not saved: $e');
  }
}

/// Service abstraction for Firebase Cloud Messaging (FCM)
class NotificationService {
  /// Injected for testing; otherwise resolved lazily via getter.
  final FirebaseMessaging? _injectedFcm;
  FirebaseMessaging get _fcm => _injectedFcm ?? FirebaseMessaging.instance;

  /// On-device history, shared with the background handler's isolate
  final NotificationHistoryStore _historyStore;

  /// Everything in the store, newest first (sale messages included)
  List<AppNotificationItem> _receivedNotifications = [];
  final _notificationsStreamController =
      StreamController<List<AppNotificationItem>>.broadcast();
  final _foregroundController =
      StreamController<AppNotificationItem>.broadcast();

  /// Serializes store writes from this isolate (each add is read–merge–write).
  /// Never completes with an error, so one failed step does not block the next.
  Future<void> _storeQueue = Future.value();

  Future<void> _enqueue(Future<void> Function() step) {
    return _storeQueue = _storeQueue.then((_) => step()).catchError((Object e) {
      debugPrint('NotificationService history error: $e');
    });
  }

  /// Remote Config `sale_reminder_enabled`; while off, sale messages are hidden from the
  /// in-app list (still stored) and a tap on one only opens the app
  final bool Function() _saleRemindersEnabled;

  NotificationService({
    FirebaseMessaging? fcm,
    bool Function()? saleRemindersEnabled,
    NotificationHistoryStore? historyStore,
  }) : _injectedFcm = fcm,
       _saleRemindersEnabled = saleRemindersEnabled ?? (() => true),
       _historyStore = historyStore ?? SharedPrefsNotificationHistoryStore();

  /// Filtered here rather than when saving: the background isolate stores every
  /// message without reading Remote Config
  List<AppNotificationItem> get receivedNotifications {
    final showSales = _saleRemindersEnabled();
    return List.unmodifiable(
      _receivedNotifications.where(
        (item) => showSales || !NotificationRoute.isSale(item.data),
      ),
    );
  }

  Stream<List<AppNotificationItem>> get notificationsStream =>
      _notificationsStreamController.stream;

  /// Messages received while the app is open (Android shows nothing by itself then),
  /// after they are saved. Sale messages hidden by `sale_reminder_enabled` are skipped.
  Stream<AppNotificationItem> get foregroundMessages =>
      _foregroundController.stream;

  /// Current Remote Config `sale_reminder_enabled`
  bool get saleRemindersEnabled => _saleRemindersEnabled();

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
    // Show what was saved earlier (background handler, previous launches), even
    // without notification permission
    await reload();
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
        unawaited(handleForegroundMessage(message));
      });

      // 4. Background notification opened listener
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM Notification tapped to open app: ${message.data}');
        unawaited(
          recordNotification(message, NotificationSource.tapBackground),
        );
        onNotificationOpened?.call(message.data);
      });

      // 5. Terminated state notification tap
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
          'FCM App opened from terminated message: ${initialMessage.data}',
        );
        unawaited(
          recordNotification(initialMessage, NotificationSource.tapTerminated),
        );
        onNotificationOpened?.call(initialMessage.data);
      }

      // On web getToken itself would open the browser prompt; wait for the user's click
      if (!kIsWeb || await isPermissionGranted()) await _logToken();
      FirebaseAuth.instance.authStateChanges().listen((_) {
        unawaited(_logToken());
      });
    } catch (e) {
      debugPrint('NotificationService initialize error: ${describeError(e)}');
    }
  }

  Future<void> _logToken() async {
    // ignore: deprecated_member_use
    final token = await _fcm.getToken();
    debugPrint('FCM Device Token: $token');
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (token == null || uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  /// Notifications are allowed for this app (web: for this site)
  Future<bool> isPermissionGranted() async {
    if (!PlatformSupport.supportsMessaging) return false;
    try {
      final settings = await _fcm.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      debugPrint(
        'NotificationService permission check error: ${describeError(e)}',
      );
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
      debugPrint(
        'NotificationService requestPermission error: ${describeError(e)}',
      );
      return false;
    }
  }

  /// Reads the stored history into memory and publishes it
  Future<void> reload() async {
    _receivedNotifications = await _historyStore.load();
    _publish();
  }

  /// Saves a message to the history ("Thông báo đã nhận" in Cá nhân), then reloads.
  /// A message already stored (same id, e.g. saved by the background handler and
  /// then tapped) is not added again; a tap only marks it as opened.
  @visibleForTesting
  Future<void> recordNotification(
    RemoteMessage message,
    NotificationSource source,
  ) {
    final item = notificationItemFromMessage(message, source);
    return _enqueue(() async {
      await _historyStore.add(item);
      await reload();
    });
  }

  /// `onMessage`: saves the message, then announces it on [foregroundMessages]
  @visibleForTesting
  Future<void> handleForegroundMessage(RemoteMessage message) async {
    await recordNotification(message, NotificationSource.foreground);
    final item = notificationItemFromMessage(
      message,
      NotificationSource.foreground,
    );
    if (NotificationRoute.isSale(item.data) && !_saleRemindersEnabled()) return;
    if (!_foregroundController.isClosed) _foregroundController.add(item);
  }

  /// Forgets the stored history (sign-out / account switch)
  Future<void> clearReceived() {
    return _enqueue(() async {
      await _historyStore.clear();
      _receivedNotifications = [];
      _publish();
    });
  }

  void _publish() {
    if (_notificationsStreamController.isClosed) return;
    _notificationsStreamController.add(receivedNotifications);
  }

  void dispose() {
    _notificationsStreamController.close();
    _foregroundController.close();
  }
}
