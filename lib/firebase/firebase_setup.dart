import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart';
import 'app_check_setup.dart';
import '../services/crashlytics_service.dart';
import '../services/notification_service.dart';
import '../services/remote_config_service.dart';

/// Centralized Firebase Initialization and Service Orchestrator
class FirebaseSetup {
  FirebaseSetup._();

  static Future<void> initialize({
    required CrashlyticsService crashlyticsService,
    required RemoteConfigService remoteConfigService,
    required NotificationService notificationService,
    Function(dynamic message)? onNotificationOpened,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. Initialize Firebase Core
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 1b. App Check (required by Firebase AI Logic). Failure only disables AI wording.
    try {
      await AppCheckSetup.activate();
    } catch (e) {
      debugPrint('AppCheck activate error: $e');
    }

    // 2. Setup Crashlytics error handlers
    crashlyticsService.initCrashlyticsHandlers();

    // 3. Initialize Remote Config
    await remoteConfigService.initialize();

    // 4. Initialize FCM
    await notificationService.initialize(
      onNotificationOpened: onNotificationOpened,
    );
  }
}
