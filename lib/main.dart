import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'firebase/firebase_setup.dart';
import 'services/crashlytics_service.dart';
import 'services/notification_service.dart';
import 'services/remote_config_service.dart';
import 'services/review_reminder_service.dart';
import 'services/share_intent_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN');

  // FirebaseSetup needs these three; all other services are created by AppProviders
  // after Firebase is initialized.
  final crashlyticsService = CrashlyticsService();
  final remoteConfigService = RemoteConfigService();
  final notificationService = NotificationService();

  await FirebaseSetup.initialize(
    crashlyticsService: crashlyticsService,
    remoteConfigService: remoteConfigService,
    notificationService: notificationService,
  );

  // Local "Đến hẹn xem lại" notifications (Android/iOS only; no-op elsewhere)
  final reviewReminderService = LocalReviewReminderService();
  await reviewReminderService.initialize(onOpen: openReviewDueList);

  // Android Native Share Sheet target (Android only; no-op elsewhere)
  final shareIntentService = ShareIntentService();
  await shareIntentService.initialize(onDataReceived: openAddItemWithSharedData);

  runApp(
    AppProviders(
      crashlyticsService: crashlyticsService,
      remoteConfigService: remoteConfigService,
      notificationService: notificationService,
      reviewReminderService: reviewReminderService,
      shareIntentService: shareIntentService,
      child: const WhyIBuyApp(),
    ),
  );
}
