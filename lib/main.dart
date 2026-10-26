import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase/firebase_setup.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/ai_insight_service.dart';
import 'services/analytics_service.dart';
import 'services/auth_service.dart';
import 'services/crashlytics_service.dart';
import 'services/notification_service.dart';
import 'services/preferences_service.dart';
import 'services/purchase_service.dart';
import 'services/remote_config_service.dart';
import 'services/report_service.dart';
import 'services/storage_service.dart';
import 'services/wishlist_service.dart';
import 'theme/app_theme.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/insights_viewmodel.dart';
import 'viewmodels/purchase_viewmodel.dart';
import 'viewmodels/report_viewmodel.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'viewmodels/wishlist_viewmodel.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'widgets/states/loading_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN', null);

  // ⚠️ FIX: Initialize Firebase FIRST, before creating any service
  // that depends on Firebase*.instance
  final crashlyticsService = CrashlyticsService();
  final remoteConfigService = RemoteConfigService();
  final notificationService = NotificationService();

  await FirebaseSetup.initialize(
    crashlyticsService: crashlyticsService,
    remoteConfigService: remoteConfigService,
    notificationService: notificationService,
  );

  // Now Firebase is initialized — safe to create services that access
  // FirebaseAuth.instance, FirebaseFirestore.instance, etc.
  final authService = AuthService();
  final wishlistService = WishlistService();
  final purchaseService = PurchaseService();
  final storageService = StorageService();
  final analyticsService = AppAnalyticsService();
  final reportService = ReportService();
  final preferencesService = PreferencesService();
  final aiInsightService = AiInsightService(
    generator: FirebaseAiInsightGenerator(
      modelName: () => remoteConfigService.aiInsightModel,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        // Services Injection
        Provider<AuthService>.value(value: authService),
        Provider<WishlistService>.value(value: wishlistService),
        Provider<PurchaseService>.value(value: purchaseService),
        Provider<StorageService>.value(value: storageService),
        Provider<AppAnalyticsService>.value(value: analyticsService),
        Provider<CrashlyticsService>.value(value: crashlyticsService),
        Provider<RemoteConfigService>.value(value: remoteConfigService),
        Provider<NotificationService>.value(value: notificationService),
        Provider<ReportService>.value(value: reportService),

        // ViewModels
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(
            authService: authService,
            analyticsService: analyticsService,
            crashlyticsService: crashlyticsService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => WishlistViewModel(
            wishlistService: wishlistService,
            analyticsService: analyticsService,
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
          create: (_) => ReportViewModel(
            reportService: reportService,
            storageService: storageService,
            analyticsService: analyticsService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => PurchaseViewModel(
            purchaseService: purchaseService,
            analyticsService: analyticsService,
          ),
        ),
        // Góc nhìn / Chiêm nghiệm: recomputes stats whenever purchases, wishlist or month change
        ChangeNotifierProxyProvider2<PurchaseViewModel, WishlistViewModel, InsightsViewModel>(
          create: (_) => InsightsViewModel(
            aiInsightService: aiInsightService,
            remoteConfigService: remoteConfigService,
            preferencesService: preferencesService,
            crashlyticsService: crashlyticsService,
          ),
          update: (_, purchaseVm, wishlistVm, insightsVm) => insightsVm!
            ..updateSources(
              purchases: purchaseVm.allPurchases,
              wishlistItems: wishlistVm.allItems,
              month: purchaseVm.selectedMonth,
            ),
        ),
      ],
      child: const WhyIBuyApp(),
    ),
  );
}

class WhyIBuyApp extends StatelessWidget {
  const WhyIBuyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final analyticsService = context.read<AppAnalyticsService>();

    return MaterialApp(
      title: 'Why I Buy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorObservers: analyticsService.navigatorObservers,
      home: const AuthGate(),
    );
  }
}

/// Authentication State Router Gate
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    switch (authVm.status) {
      case AuthStatus.initial:
      case AuthStatus.loading:
        return const Scaffold(
          body: LoadingView(message: 'Đang kiểm tra trạng thái phiên đăng nhập...'),
        );
      case AuthStatus.authenticated:
        return const MainNavigationScreen();
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
        return const LoginScreen();
    }
  }
}
