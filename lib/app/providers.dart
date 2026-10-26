import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/ai_insight_service.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/crashlytics_service.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';
import '../services/purchase_service.dart';
import '../services/remote_config_service.dart';
import '../services/report_service.dart';
import '../services/storage_service.dart';
import '../services/wishlist_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/insights_viewmodel.dart';
import '../viewmodels/purchase_viewmodel.dart';
import '../viewmodels/report_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../viewmodels/wishlist_viewmodel.dart';

/// All services and ViewModels of the app.
///
/// The three services passed in are created before Firebase starts (FirebaseSetup needs them);
/// every other service touches Firebase*.instance, so it must only be created after
/// FirebaseSetup.initialize — Provider.create runs lazily, after runApp.
class AppProviders extends StatelessWidget {
  final CrashlyticsService crashlyticsService;
  final RemoteConfigService remoteConfigService;
  final NotificationService notificationService;
  final Widget child;

  const AppProviders({
    super.key,
    required this.crashlyticsService,
    required this.remoteConfigService,
    required this.notificationService,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services Injection
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<WishlistService>(create: (_) => WishlistService()),
        Provider<PurchaseService>(create: (_) => PurchaseService()),
        Provider<StorageService>(create: (_) => StorageService()),
        Provider<AppAnalyticsService>(create: (_) => AppAnalyticsService()),
        Provider<CrashlyticsService>.value(value: crashlyticsService),
        Provider<RemoteConfigService>.value(value: remoteConfigService),
        Provider<NotificationService>.value(value: notificationService),
        Provider<ReportService>(create: (_) => ReportService()),

        // ViewModels
        ChangeNotifierProvider(
          create: (context) => AuthViewModel(
            authService: context.read<AuthService>(),
            analyticsService: context.read<AppAnalyticsService>(),
            crashlyticsService: crashlyticsService,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => WishlistViewModel(
            wishlistService: context.read<WishlistService>(),
            analyticsService: context.read<AppAnalyticsService>(),
            remoteConfigService: remoteConfigService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsViewModel(
            remoteConfigService: remoteConfigService,
            crashlyticsService: crashlyticsService,
            notificationService: notificationService,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ReportViewModel(
            reportService: context.read<ReportService>(),
            storageService: context.read<StorageService>(),
            analyticsService: context.read<AppAnalyticsService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => PurchaseViewModel(
            purchaseService: context.read<PurchaseService>(),
            analyticsService: context.read<AppAnalyticsService>(),
          ),
        ),
        // Góc nhìn / Chiêm nghiệm: recomputes stats whenever purchases, wishlist or month change
        ChangeNotifierProxyProvider2<
          PurchaseViewModel,
          WishlistViewModel,
          InsightsViewModel
        >(
          create: (_) => InsightsViewModel(
            aiInsightService: AiInsightService(
              generator: FirebaseAiInsightGenerator(
                modelName: () => remoteConfigService.aiInsightModel,
              ),
            ),
            remoteConfigService: remoteConfigService,
            preferencesService: PreferencesService(),
            crashlyticsService: crashlyticsService,
          ),
          update: (_, purchaseVm, wishlistVm, insightsVm) =>
              insightsVm!..updateSources(
                purchases: purchaseVm.allPurchases,
                wishlistItems: wishlistVm.allItems,
                month: purchaseVm.selectedMonth,
              ),
        ),
      ],
      child: child,
    );
  }
}
