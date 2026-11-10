import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/constants/legal_texts.dart';
import 'package:prm393_lab03/models/app_notification_item.dart';
import 'package:prm393_lab03/models/buying_motive.dart';
import 'package:prm393_lab03/models/pre_purchase_check.dart';
import 'package:prm393_lab03/models/purchase_item.dart';
import 'package:prm393_lab03/models/sale_event.dart';
import 'package:prm393_lab03/screens/add_item_screen.dart';
import 'package:prm393_lab03/screens/budget_screen.dart';
import 'package:prm393_lab03/screens/compare_items_screen.dart';
import 'package:prm393_lab03/screens/email_verification_screen.dart';
import 'package:prm393_lab03/screens/feedback_screen.dart';
import 'package:prm393_lab03/screens/history_screen.dart';
import 'package:prm393_lab03/screens/home_screen.dart';
import 'package:prm393_lab03/screens/info_text_screen.dart';
import 'package:prm393_lab03/screens/insights_screen.dart';
import 'package:prm393_lab03/screens/item_detail_screen.dart';
import 'package:prm393_lab03/screens/login_screen.dart';
import 'package:prm393_lab03/screens/main_navigation_screen.dart';
import 'package:prm393_lab03/screens/monthly_reflection_screen.dart';
import 'package:prm393_lab03/screens/onboarding_screen.dart';
import 'package:prm393_lab03/screens/patterns_screen.dart';
import 'package:prm393_lab03/screens/photo_search_screen.dart';
import 'package:prm393_lab03/screens/pre_purchase_result_screen.dart';
import 'package:prm393_lab03/screens/pre_purchase_screen.dart';
import 'package:prm393_lab03/screens/profile_screen.dart';
import 'package:prm393_lab03/screens/purchase_detail_screen.dart';
import 'package:prm393_lab03/screens/record_purchase_screen.dart';
import 'package:prm393_lab03/screens/reminder_permission_screen.dart';
import 'package:prm393_lab03/screens/sale_screens.dart';
import 'package:prm393_lab03/screens/shopping_profile_screen.dart';
import 'package:prm393_lab03/screens/wishlist_screen.dart';
import 'package:prm393_lab03/services/ai_decision_service.dart';
import 'package:prm393_lab03/services/ai_insight_service.dart';
import 'package:prm393_lab03/services/ai_photo_search_service.dart';
import 'package:prm393_lab03/services/ai_pre_purchase_service.dart';
import 'package:prm393_lab03/services/ai_service.dart';
import 'package:prm393_lab03/services/crashlytics_service.dart';
import 'package:prm393_lab03/services/extension_session_service.dart';
import 'package:prm393_lab03/services/preferences_service.dart';
import 'package:prm393_lab03/services/reflection_service.dart';
import 'package:prm393_lab03/services/remote_config_service.dart';
import 'package:prm393_lab03/services/report_service.dart';
import 'package:prm393_lab03/services/report_share_service.dart';
import 'package:prm393_lab03/services/review_reminder_service.dart';
import 'package:prm393_lab03/services/share_intent_service.dart';
import 'package:prm393_lab03/services/shopping_profile_service.dart';
import 'package:prm393_lab03/services/user_service.dart';
import 'package:prm393_lab03/services/wishlist_service.dart';
import 'package:prm393_lab03/theme/app_colors.dart';
import 'package:prm393_lab03/theme/app_theme.dart';
import 'package:prm393_lab03/viewmodels/auth_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/decision_support_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/extension_link_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/insights_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/linked_accounts_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/photo_search_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/pre_purchase_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/reflection_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/report_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/settings_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/shopping_profile_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/theme_viewmodel.dart';
import 'package:prm393_lab03/widgets/app_bottom_sheet.dart';
import 'package:prm393_lab03/widgets/motive_chip.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/linked_auth_fakes.dart';
import '../support/purchase_harness.dart';

class _Generator extends Fake implements AiService {}

class _ImageGenerator extends Fake implements AiImageService {}

class _Share extends Fake implements ReportShareService {}

class _Reminders extends Fake implements ReviewReminderService {
  @override
  bool consumeLaunchedFromReminder() => false;
  @override
  bool consumeLaunchedFromDailyReminder() => false;
}

class _Remote extends Fake implements FirebaseRemoteConfig {
  @override
  bool getBool(String key) => false;
  @override
  int getInt(String key) => 3;
  @override
  String getString(String key) => '';
}

class _Auth extends SignedInAuthViewModel {
  @override
  bool get isAnonymous => true;
  @override
  bool get isAuthenticated => false;
  @override
  String get displayName => 'Bạn';
  @override
  Null get user => null;
  @override
  String? get errorMessage => null;
}

/// No network/native calls: this suite exercises rendering, not settings actions.
class _Settings extends ChangeNotifier implements SettingsViewModel {
  @override
  Future<void> markDailyReminderOffered() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      switch (invocation.memberName) {
        #notifications => <AppNotificationItem>[],
        #coolingOffDays => 3,
        #maxWishlistItems => 50,
        #dailyReminderHour => 20,
        #dailyReminderMinute => 0,
        #dailyReminderTimeText => '20:00',
        _ => false,
      };
}

void main() {
  final item = sampleWishlist();
  final purchase = PurchaseItem(
    id: 'test-purchase',
    title: 'Tai nghe',
    amountVnd: 420000,
    motive: BuyingMotive.sale,
    occurredAt: DateTime.now(),
  );
  final sale = SaleEvent(
    id: 'sale',
    name: '11.11',
    date: DateTime(2026, 11, 11),
    type: SaleType.doubleDay,
    confirmed: true,
  );
  final screens = <String, Widget>{
    'onboarding': const OnboardingScreen(),
    'login': const LoginScreen(),
    'home': const HomeScreen(),
    'history': const HistoryScreen(),
    'patterns': const PatternsScreen(),
    'profile': const ProfileScreen(),
    'budget': const BudgetScreen(),
    'wishlist': const WishlistScreen(),
    'add item': const AddItemScreen(),
    'item detail': ItemDetailScreen(item: item),
    'record purchase': const RecordPurchaseScreen(),
    'purchase detail': PurchaseDetailScreen(purchase: purchase),
    'pre purchase': const PrePurchaseScreen(),
    'shopping profile': const ShoppingProfileScreen(),
    'feedback': const FeedbackScreen(),
    'legal text': const InfoTextScreen(document: LegalTexts.terms),
    'insights': const InsightsScreen(),
    'monthly reflection': const MonthlyReflectionScreen(),
    'navigation': const MainNavigationScreen(),
    'compare items': CompareItemsScreen(item: item),
    'sale calendar': const SaleCalendarScreen(),
    'sale list': SaleListScreen(sale: sale),
    'sale plan': SalePlanScreen(sale: sale),
    'email verification': const EmailVerificationScreen(),
    'reminder permission': const ReminderPermissionScreen(),
    'photo search': const PhotoSearchScreen(),
    'pre purchase result': PrePurchaseResultScreen(
      answers: PrePurchaseAnswers(
        title: 'Tai nghe',
        why: WhyAnswer.need,
        influence: InfluenceAnswer.none,
        usage: UsageAnswer.daily,
        similar: SimilarOwnedAnswer.none,
      ),
    ),
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key} renders with the dark palette', (tester) async {
      SharedPreferences.setMockInitialValues({});
      // Wider viewport avoids pre-existing Ahem-font overflow in colour-only tests.
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final h = PurchaseHarness();
      final auth = _Auth();
      final settings = _Settings();
      final themeVm = ThemeViewModel();
      final shopping = ShoppingProfileViewModel(
        service: FirestoreShoppingProfileService(h.db),
      );
      shopping.updateUid(PurchaseHarness.uid);
      final linked = LinkedAccountsViewModel(
        authService: FakeLinkAuthService(null),
        userService: FirestoreUserService(h.db),
        isAvailable: false,
      );
      final devices = ExtensionLinkViewModel(
        service: FirestoreExtensionSessionService(h.db),
      );
      final remote = RemoteConfigService(remoteConfig: _Remote());
      final insights = InsightsViewModel(
        aiInsightService: AiInsightService(generator: _Generator()),
        remoteConfigService: remote,
        preferencesService: PreferencesService(),
        crashlyticsService: CrashlyticsService(),
      );
      insights.updateSources(
        purchases: [purchase],
        wishlistItems: [item],
        month: DateTime.now(),
      );
      final report = ReportViewModel(
        reportService: ReportService(),
        shareService: _Share(),
        analyticsService: h.analytics,
      );
      final reflection = ReflectionViewModel(
        reflectionService: FirestoreReflectionService(h.db),
      );
      final prePurchase = PrePurchaseViewModel(
        aiService: AiPrePurchaseService(generator: _Generator()),
        remoteConfigService: remote,
        preferencesService: PreferencesService(),
        platformSupportsAi: () => false,
      );
      final photo = PhotoSearchViewModel(
        aiService: AiPhotoSearchService(generator: _ImageGenerator()),
        remoteConfigService: remote,
        preferencesService: PreferencesService(),
        platformSupportsAi: () => false,
      );
      final decisions = DecisionSupportViewModel(
        budgetService: h.budgetService,
        wishlistService: FirestoreWishlistService(h.db),
        aiDecisionService: AiDecisionService(generator: _Generator()),
        remoteConfigService: remote,
        preferencesService: PreferencesService(),
        platformSupportsAi: () => false,
      );
      await h.initialize(item: item, purchase: purchase);
      await tester.pumpWidget(
        h.app(
          MultiProvider(
            providers: [
              Provider<ReviewReminderService>.value(value: _Reminders()),
              Provider<ShareIntentService>(create: (_) => ShareIntentService()),
              ChangeNotifierProvider<AuthViewModel>.value(value: auth),
              ChangeNotifierProvider<SettingsViewModel>.value(value: settings),
              ChangeNotifierProvider.value(value: themeVm),
              ChangeNotifierProvider.value(value: shopping),
              ChangeNotifierProvider.value(value: linked),
              ChangeNotifierProvider.value(value: devices),
              ChangeNotifierProvider.value(value: decisions),
              ChangeNotifierProvider.value(value: insights),
              ChangeNotifierProvider.value(value: report),
              ChangeNotifierProvider.value(value: reflection),
              ChangeNotifierProvider.value(value: prePurchase),
              ChangeNotifierProvider.value(value: photo),
            ],
            child: Theme(data: AppTheme.darkTheme, child: entry.value),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final context = tester.element(find.byWidget(entry.value));
      expect(Theme.of(context).brightness, Brightness.dark);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      h.dispose();
      auth.dispose();
      settings.dispose();
      themeVm.dispose();
      shopping.dispose();
      linked.dispose();
      devices.dispose();
      decisions.dispose();
      insights.dispose();
      report.dispose();
      reflection.dispose();
      prePurchase.dispose();
      photo.dispose();
    });
  }

  testWidgets(
    'onboarding keeps the original light gradient, card and text colours',
    (tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const OnboardingScreen()),
      );
      await tester.pumpAndSettle();
      final boxes = tester
          .widgetList<Container>(find.byType(Container))
          .map((w) => w.decoration)
          .whereType<BoxDecoration>()
          .toList();
      final gradient = boxes
          .map((d) => d.gradient)
          .whereType<LinearGradient>()
          .single;
      expect(gradient.colors, const [Color(0xFFFFF3B0), Color(0xFFF1F6F2)]);
      expect(
        boxes
            .where((d) => d.borderRadius == BorderRadius.circular(13))
            .every((d) => d.color == Colors.white),
        isTrue,
      );
      expect(
        tester.widget<Text>(find.text('DÀNH RIÊNG CHO BẠN')).style!.color,
        const Color(0xFF0F172A),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'switching light → dark → light updates existing widgets and motive selection',
    (tester) async {
      final mode = ValueNotifier(ThemeMode.light);
      await tester.pumpWidget(
        ValueListenableBuilder(
          valueListenable: mode,
          builder: (_, value, child) => MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: value,
            home: child,
          ),
          child: const Scaffold(
            body: MotiveChip(motive: BuyingMotive.sale, isSelected: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final next in [ThemeMode.dark, ThemeMode.light]) {
        mode.value = next;
        await tester.pumpAndSettle();
        final label = tester.widget<Text>(find.text(BuyingMotive.sale.label));
        expect(
          label.style!.color,
          next == ThemeMode.dark ? AppColors.onPrimary : AppColors.textOnDark,
        );
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      mode.dispose();
    },
  );

  testWidgets(
    'dark date picker, dialog, bottom sheet and snackbar render correctly',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  TextButton(
                    onPressed: () {
                      showDatePicker(
                        context: context,
                        initialDate: DateTime(2026, 11, 10),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                    },
                    child: const Text('date'),
                  ),
                  TextButton(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (_) =>
                            const AlertDialog(title: Text('Xác nhận')),
                      );
                    },
                    child: const Text('dialog'),
                  ),
                  TextButton(
                    onPressed: () {
                      AppBottomSheet.show<void>(
                        context,
                        title: 'Chọn tháng',
                        child: const Text('Nội dung'),
                      );
                    },
                    child: const Text('sheet'),
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('Đã lưu')));
                    },
                    child: const Text('snack'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      for (final button in ['date', 'dialog', 'sheet']) {
        await tester.tap(find.text(button));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        tester.state<NavigatorState>(find.byType(Navigator)).pop();
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('snack'));
      await tester.pumpAndSettle();
      expect(find.text('Đã lưu'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
