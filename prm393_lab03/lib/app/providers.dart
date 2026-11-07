import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../firebase/platform_support.dart';
import '../services/ai_decision_service.dart';
import '../services/ai_insight_service.dart';
import '../services/ai_photo_search_service.dart';
import '../services/ai_pre_purchase_service.dart';
import '../services/ai_price_search_service.dart';
import '../services/ai_product_identity_service.dart';
import '../services/ai_service.dart';
import '../services/ai_suggestion_service.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/budget_service.dart';
import '../services/crashlytics_service.dart';
import '../services/data_export_service.dart';
import '../services/demo_data_service.dart';
import '../services/demo_price_history_service.dart';
import '../services/extension_session_service.dart';
import '../services/feedback_service.dart';
import '../services/hidden_match_service.dart';
import '../services/instrumented_ai_service.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';
import '../services/price_history_contribution_service.dart';
import '../services/price_history_service.dart';
import '../services/purchase_service.dart';
import '../services/reflection_service.dart';
import '../services/remote_config_service.dart';
import '../services/report_service.dart';
import '../services/report_share_service.dart';
import '../services/review_reminder_service.dart';
import '../services/share_intent_service.dart';
import '../services/shared_price_service.dart';
import '../services/shopping_profile_service.dart';
import '../services/user_service.dart';
import '../services/wishlist_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/budget_viewmodel.dart';
import '../viewmodels/decision_support_viewmodel.dart';
import '../viewmodels/extension_link_viewmodel.dart';
import '../viewmodels/insights_viewmodel.dart';
import '../viewmodels/item_suggestion_viewmodel.dart';
import '../viewmodels/linked_accounts_viewmodel.dart';
import '../viewmodels/photo_search_viewmodel.dart';
import '../viewmodels/pre_purchase_viewmodel.dart';
import '../viewmodels/price_history_demo_viewmodel.dart';
import '../viewmodels/purchase_viewmodel.dart';
import '../viewmodels/reflection_viewmodel.dart';
import '../viewmodels/report_viewmodel.dart';
import '../viewmodels/same_product_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../viewmodels/shared_price_viewmodel.dart';
import '../viewmodels/shopping_profile_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import '../viewmodels/wishlist_viewmodel.dart';

/// All services and ViewModels of the app.
///
/// The three services passed in are created before Firebase starts (FirebaseSetup needs them);
/// every other service touches Firebase*.instance, so it must only be created after
/// FirebaseSetup.initialize — Provider.create runs lazily, after runApp.
InstrumentedAiService _gemini(
  BuildContext context,
  RemoteConfigService remoteConfig,
) {
  final gemini = FirebaseAiService(
    modelName: () => remoteConfig.aiInsightModel,
  );
  return InstrumentedAiService(
    text: gemini,
    image: gemini,
    web: gemini,
    modelName: () => remoteConfig.aiInsightModel,
    promptFor: remoteConfig.aiPromptFor,
    analyticsService: context.read<AppAnalyticsService>(),
  );
}

class AppProviders extends StatelessWidget {
  final CrashlyticsService crashlyticsService;
  final RemoteConfigService remoteConfigService;
  final NotificationService notificationService;
  final ReviewReminderService reviewReminderService;
  final ShareIntentService? shareIntentService;
  final Widget child;

  const AppProviders({
    super.key,
    required this.crashlyticsService,
    required this.remoteConfigService,
    required this.notificationService,
    required this.reviewReminderService,
    this.shareIntentService,
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
        Provider<DemoPriceHistoryService>(
          create: (_) => FirestoreDemoPriceHistoryService(),
        ),
        // "Giá tham khảo": the service only; each screen creates its own ViewModel
        Provider<PriceHistoryService>(
          create: (_) => FirestorePriceHistoryService(),
        ),
        // "Không phải món này" of "Cùng món ở shop khác" (G8)
        Provider<HiddenMatchService>(
          create: (_) => FirestoreHiddenMatchService(),
        ),
        // The user's own prices sent anonymously to "Giá tham khảo" (G7)
        Provider<PriceHistoryContributionService>(
          create: (_) => FirestorePriceHistoryContributionService(),
        ),
        Provider<ExtensionSessionService>(
          create: (_) => FirestoreExtensionSessionService(),
        ),
        Provider<ShoppingProfileService>(
          create: (_) => FirestoreShoppingProfileService(),
        ),
        Provider<SharedPriceService>(
          create: (_) => FirestoreSharedPriceService(),
        ),
        Provider<AppAnalyticsService>(create: (_) => AppAnalyticsService()),
        // One Gemini client for every AI feature: prompt from Remote Config, ai_* events
        Provider<AiService>(
          create: (context) => _gemini(context, remoteConfigService),
        ),
        Provider<CrashlyticsService>.value(value: crashlyticsService),
        Provider<RemoteConfigService>.value(value: remoteConfigService),
        Provider<NotificationService>.value(value: notificationService),
        Provider<ReviewReminderService>.value(value: reviewReminderService),
        Provider<ShareIntentService>.value(
          value: shareIntentService ?? ShareIntentService(),
        ),
        Provider<ReportService>(create: (_) => ReportService()),
        Provider<ReportShareService>(
          create: (_) => PrintingReportShareService(),
        ),
        Provider<DataExportService>(
          create: (_) => FileSaverDataExportService(),
        ),
        Provider<FeedbackService>(create: (_) => FirestoreFeedbackService()),
        ChangeNotifierProvider(
          create: (context) => PrePurchaseViewModel(
            aiService: AiPrePurchaseService(
              generator: context.read<AiService>(),
            ),
            remoteConfigService: remoteConfigService,
            preferencesService: PreferencesService(),
          ),
        ),

        // "Chụp để tìm": photo + prompt to Gemini (FirebaseAiService is stateless).
        // AI shop prices only show when enable_ai_price_search is on (paid grounding).
        ChangeNotifierProvider(
          create: (context) {
            final gemini = _gemini(context, remoteConfigService);
            return PhotoSearchViewModel(
              aiService: AiPhotoSearchService(generator: gemini),
              analyticsService: context.read<AppAnalyticsService>(),
              priceSearchService: AiPriceSearchService(generator: gemini),
              remoteConfigService: remoteConfigService,
              preferencesService: PreferencesService(),
            );
          },
        ),

        // Theme management with persistence
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),

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
            demoDataService: context.read<DemoDataService>(),
            reminderService: reviewReminderService,
            preferencesService: PreferencesService(),
            exportService: context.read<DataExportService>(),
            feedbackService: context.read<FeedbackService>(),
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
            crashlyticsService: crashlyticsService,
            analyticsService: context.read<AppAnalyticsService>(),
            reminderService: reviewReminderService,
          ),
          update: (_, auth, settings, vm) => vm!
            ..updateUid(auth.userId)
            ..updateCoolingOffDays(settings.coolingOffDays)
            ..updateMaxShown(settings.maxWishlistItems),
        ),
        ChangeNotifierProxyProvider<AuthViewModel, PurchaseViewModel>(
          create: (context) => PurchaseViewModel(
            purchaseService: context.read<PurchaseService>(),
            crashlyticsService: crashlyticsService,
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
            crashlyticsService: crashlyticsService,
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
            crashlyticsService: crashlyticsService,
          ),
          update: (_, auth, purchaseVm, vm) => vm!
            ..updateUid(auth.userId)
            ..updateMonth(purchaseVm.selectedMonth),
        ),
        ChangeNotifierProxyProvider3<
          AuthViewModel,
          PurchaseViewModel,
          WishlistViewModel,
          ReportViewModel
        >(
          create: (context) => ReportViewModel(
            reportService: context.read<ReportService>(),
            crashlyticsService: crashlyticsService,
            shareService: context.read<ReportShareService>(),
            analyticsService: context.read<AppAnalyticsService>(),
          ),
          update: (_, auth, purchaseVm, wishlistVm, vm) => vm!
            ..updateUid(auth.userId)
            ..updateSources(
              userName: auth.displayName,
              purchases: purchaseVm.allPurchases,
              // G2c: sample items never enter the monthly report
              wishlistItems: wishlistVm.realItems,
            ),
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
                // G2c: sample items never enter the stats
                wishlistItems: wishlistVm.realItems,
                month: purchaseVm.selectedMonth,
              ),
        ),
        // Hồ sơ mua sắm: owned items, style, brands (spec 7.2)
        ChangeNotifierProxyProvider<AuthViewModel, ShoppingProfileViewModel>(
          create: (context) => ShoppingProfileViewModel(
            service: context.read<ShoppingProfileService>(),
            crashlyticsService: crashlyticsService,
          ),
          update: (_, auth, vm) => vm!..updateUid(auth.userId),
        ),
        // "Dữ liệu giá mẫu" (Firebase Demo Area): admins only, role read from users/{uid}
        ChangeNotifierProxyProvider<AuthViewModel, PriceHistoryDemoViewModel>(
          create: (context) => PriceHistoryDemoViewModel(
            demoService: context.read<DemoPriceHistoryService>(),
            userService: context.read<UserService>(),
            crashlyticsService: crashlyticsService,
          ),
          update: (_, auth, vm) => vm!..updateUid(auth.userId),
        ),
        // "Giá người khác ghi" (spec 8.3) and "Giá tham khảo" (G7): Google accounts
        // share, guests only read
        ChangeNotifierProxyProvider<AuthViewModel, SharedPriceViewModel>(
          create: (context) => SharedPriceViewModel(
            service: context.read<SharedPriceService>(),
            preferencesService: PreferencesService(),
            historyService: context.read<PriceHistoryContributionService>(),
            // "Mã món" (G8): same switches as the other AI features
            identityService: AiProductIdentityService(
              generator: context.read<AiService>(),
            ),
            aiAllowed: () async =>
                PlatformSupport.supportsFirebaseAi &&
                remoteConfigService.enableAiSuggestions &&
                await PreferencesService().getAiInsightEnabled(),
          ),
          update: (_, auth, vm) => vm!
            ..updateUser(
              auth.userId,
              canContribute: !(auth.user?.isAnonymous ?? true),
            ),
        ),
        // "Cùng món ở shop khác" on Chi tiết món (G8): hidden matches are per user
        ChangeNotifierProxyProvider<AuthViewModel, SameProductViewModel>(
          create: (context) => SameProductViewModel(
            service: context.read<PriceHistoryService>(),
            hiddenService: context.read<HiddenMatchService>(),
            analytics: context.read<AppAnalyticsService>(),
          ),
          update: (_, auth, vm) => vm!..updateUid(auth.userId),
        ),
        // Decision Card labels + AI reason, Lịch sale and sale plans (this month's budget)
        ChangeNotifierProxyProvider5<
          AuthViewModel,
          PurchaseViewModel,
          WishlistViewModel,
          BudgetViewModel,
          ShoppingProfileViewModel,
          DecisionSupportViewModel
        >(
          create: (context) => DecisionSupportViewModel(
            budgetService: context.read<BudgetService>(),
            wishlistService: context.read<WishlistService>(),
            aiDecisionService: AiDecisionService(
              generator: context.read<AiService>(),
            ),
            remoteConfigService: remoteConfigService,
            preferencesService: PreferencesService(),
            reminderService: reviewReminderService,
          ),
          update: (_, auth, purchaseVm, wishlistVm, budgetVm, profileVm, vm) =>
              vm!
                ..updateUid(auth.userId)
                ..updateSources(
                  purchases: purchaseVm.allPurchases,
                  wishlistItems: wishlistVm.allItems,
                  groups: budgetVm.groups,
                  ownedItems: profileVm.ownedItems,
                ),
        ),
        // Thêm món / Ghi khoản mua / Chi tiết món: budget group and possible duplicates
        ChangeNotifierProxyProvider3<
          PurchaseViewModel,
          WishlistViewModel,
          ShoppingProfileViewModel,
          ItemSuggestionViewModel
        >(
          create: (context) => ItemSuggestionViewModel(
            aiSuggestionService: AiSuggestionService(
              generator: context.read<AiService>(),
            ),
            remoteConfigService: remoteConfigService,
            preferencesService: PreferencesService(),
            analyticsService: context.read<AppAnalyticsService>(),
          ),
          update: (_, purchaseVm, wishlistVm, profileVm, vm) =>
              vm!..updateSources(
                purchases: purchaseVm.allPurchases,
                wishlistItems: wishlistVm.allItems,
                ownedItems: profileVm.ownedItems,
              ),
        ),
        // Chrome extension linking: approval dialog and "Thiết bị đã liên kết"
        ChangeNotifierProxyProvider<AuthViewModel, ExtensionLinkViewModel>(
          create: (context) => ExtensionLinkViewModel(
            service: context.read<ExtensionSessionService>(),
            crashlyticsService: crashlyticsService,
          ),
          update: (_, auth, vm) => vm!..updateUid(auth.userId),
        ),
        // Cá nhân → "Tài khoản liên kết": link / unlink Google and GitHub
        ChangeNotifierProxyProvider<AuthViewModel, LinkedAccountsViewModel>(
          create: (context) => LinkedAccountsViewModel(
            authService: context.read<AuthService>(),
            userService: context.read<UserService>(),
            crashlyticsService: crashlyticsService,
          ),
          update: (_, auth, vm) => vm!..updateUid(auth.userId),
        ),
      ],
      child: child,
    );
  }
}
