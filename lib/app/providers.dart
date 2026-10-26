import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/ai_insight_service.dart';
import '../services/ai_service.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/budget_service.dart';
import '../services/crashlytics_service.dart';
import '../services/demo_data_service.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';
import '../services/purchase_service.dart';
import '../services/reflection_service.dart';
import '../services/remote_config_service.dart';
import '../services/report_service.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';
import '../services/wishlist_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/budget_viewmodel.dart';
import '../viewmodels/insights_viewmodel.dart';
import '../viewmodels/purchase_viewmodel.dart';
import '../viewmodels/reflection_viewmodel.dart';
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
        Provider<UserService>(create: (_) => FirestoreUserService()),
        Provider<WishlistService>(create: (_) => FirestoreWishlistService()),
        Provider<PurchaseService>(create: (_) => FirestorePurchaseService()),
        Provider<BudgetService>(create: (_) => FirestoreBudgetService()),
        Provider<ReflectionService>(
          create: (_) => FirestoreReflectionService(),
        ),
        Provider<DemoDataService>(create: (_) => FirestoreDemoDataService()),
        Provider<AiService>(
          create: (_) => FirebaseAiService(
            modelName: () => remoteConfigService.aiInsightModel,
          ),
        ),
        Provider<StorageService>(create: (_) => StorageService()),
        Provider<AppAnalyticsService>(create: (_) => AppAnalyticsService()),
        Provider<CrashlyticsService>.value(value: crashlyticsService),
        Provider<RemoteConfigService>.value(value: remoteConfigService),
        Provider<NotificationService>.value(value: notificationService),
        Provider<ReportService>(create: (_) => ReportService()),

        // ViewModels. Every ViewModel holding user data gets the uid from AuthViewModel
        // through a ProxyProvider (updateUid); widgets never assign it.
        ChangeNotifierProvider(
          create: (context) => AuthViewModel(
            authService: context.read<AuthService>(),
            userService: context.read<UserService>(),
            budgetService: context.read<BudgetService>(),
            analyticsService: context.read<AppAnalyticsService>(),
            crashlyticsService: crashlyticsService,
          ),
        ),
        ChangeNotifierProxyProvider<AuthViewModel, SettingsViewModel>(
          create: (context) => SettingsViewModel(
            remoteConfigService: remoteConfigService,
            crashlyticsService: crashlyticsService,
            notificationService: notificationService,
            userService: context.read<UserService>(),
          ),
          update: (_, auth, vm) => vm!..updateUid(auth.userId),
        ),
        ChangeNotifierProxyProvider2<
          AuthViewModel,
          SettingsViewModel,
          WishlistViewModel
        >(
          create: (context) => WishlistViewModel(
            wishlistService: context.read<WishlistService>(),
            analyticsService: context.read<AppAnalyticsService>(),
          ),
          update: (_, auth, settings, vm) => vm!
            ..updateUid(auth.userId)
            ..updateCoolingOffDays(settings.coolingOffDays),
        ),
        ChangeNotifierProxyProvider<AuthViewModel, ReportViewModel>(
          create: (context) => ReportViewModel(
            reportService: context.read<ReportService>(),
            storageService: context.read<StorageService>(),
            analyticsService: context.read<AppAnalyticsService>(),
          ),
          update: (_, auth, vm) => vm!..updateUid(auth.userId),
        ),
        ChangeNotifierProxyProvider<AuthViewModel, PurchaseViewModel>(
          create: (context) => PurchaseViewModel(
            purchaseService: context.read<PurchaseService>(),
            analyticsService: context.read<AppAnalyticsService>(),
          ),
          update: (_, auth, vm) => vm!..updateUid(auth.userId),
        ),
        ChangeNotifierProxyProvider2<
          AuthViewModel,
          PurchaseViewModel,
          BudgetViewModel
        >(
          create: (context) => BudgetViewModel(
            budgetService: context.read<BudgetService>(),
            analyticsService: context.read<AppAnalyticsService>(),
          ),
          update: (_, auth, purchaseVm, vm) => vm!
            ..updateUid(auth.userId)
            ..updateSources(
              purchases: purchaseVm.allPurchases,
              month: purchaseVm.selectedMonth,
            ),
        ),
        ChangeNotifierProxyProvider2<
          AuthViewModel,
          PurchaseViewModel,
          ReflectionViewModel
        >(
          create: (context) => ReflectionViewModel(
            reflectionService: context.read<ReflectionService>(),
          ),
          update: (_, auth, purchaseVm, vm) => vm!
            ..updateUid(auth.userId)
            ..updateMonth(purchaseVm.selectedMonth),
        ),
        // Góc nhìn / Chiêm nghiệm: recomputes stats whenever purchases, wishlist or month change
        ChangeNotifierProxyProvider2<
          PurchaseViewModel,
          WishlistViewModel,
          InsightsViewModel
        >(
          create: (context) => InsightsViewModel(
            aiInsightService: AiInsightService(
              generator: context.read<AiService>(),
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
