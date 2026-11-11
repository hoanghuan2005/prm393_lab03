import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:prm393_lab03/core/constants/legal_texts.dart';
import 'package:prm393_lab03/core/utils/month_key.dart';
import 'package:prm393_lab03/models/app_notification_item.dart';
import 'package:prm393_lab03/models/buying_motive.dart';
import 'package:prm393_lab03/models/item_recognition.dart';
import 'package:prm393_lab03/models/owned_item.dart';
import 'package:prm393_lab03/models/pre_purchase_check.dart';
import 'package:prm393_lab03/models/price_offer.dart';
import 'package:prm393_lab03/models/purchase_item.dart';
import 'package:prm393_lab03/models/sale_event.dart';
import 'package:prm393_lab03/models/ui_state.dart';
import 'package:prm393_lab03/models/wishlist_item.dart';
import 'package:prm393_lab03/screens/add_item_screen.dart';
import 'package:prm393_lab03/screens/budget_screen.dart';
import 'package:prm393_lab03/screens/compare_items_screen.dart';
import 'package:prm393_lab03/screens/dev/price_chart_gallery.dart';
import 'package:prm393_lab03/screens/dev/widget_gallery_screen.dart';
import 'package:prm393_lab03/screens/email_verification_screen.dart';
import 'package:prm393_lab03/screens/extension_qr_scan_screen.dart';
import 'package:prm393_lab03/screens/feedback_screen.dart';
import 'package:prm393_lab03/screens/history_screen.dart';
import 'package:prm393_lab03/screens/home_screen.dart';
import 'package:prm393_lab03/screens/inbox_screen.dart';
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
import 'package:prm393_lab03/screens/price_history_screen.dart';
import 'package:prm393_lab03/screens/profile_screen.dart';
import 'package:prm393_lab03/screens/purchase_detail_screen.dart';
import 'package:prm393_lab03/screens/record_purchase_screen.dart';
import 'package:prm393_lab03/screens/reminder_permission_screen.dart';
import 'package:prm393_lab03/screens/sale_screens.dart';
import 'package:prm393_lab03/screens/sale_suggestion_screen.dart';
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
import 'package:prm393_lab03/services/price_history_service.dart';
import 'package:prm393_lab03/services/reflection_service.dart';
import 'package:prm393_lab03/services/remote_config_service.dart';
import 'package:prm393_lab03/services/report_service.dart';
import 'package:prm393_lab03/services/report_share_service.dart';
import 'package:prm393_lab03/services/review_reminder_service.dart';
import 'package:prm393_lab03/services/share_intent_service.dart';
import 'package:prm393_lab03/services/shopping_profile_service.dart';
import 'package:prm393_lab03/services/user_service.dart';
import 'package:prm393_lab03/services/wishlist_service.dart';
import 'package:prm393_lab03/viewmodels/auth_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/decision_support_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/extension_link_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/inbox_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/insights_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/linked_accounts_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/photo_search_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/pre_purchase_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/price_history_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/reflection_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/report_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/sale_suggestion_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/settings_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/shopping_profile_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/theme_viewmodel.dart';
import 'package:prm393_lab03/widgets/app_header_actions.dart';
import 'package:prm393_lab03/widgets/budget_setting_sheet.dart';
import 'package:prm393_lab03/widgets/confirm_dialog.dart';
import 'package:prm393_lab03/widgets/month_picker_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart' as core;

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
  final bool populated;
  _Auth(this.populated);
  @override
  bool get isAnonymous => !populated;
  @override
  bool get isAuthenticated => populated;
  @override
  String get displayName => populated ? auditLongName : 'Bạn';
  @override
  Null get user => null;
  @override
  String? get errorMessage => null;
}

/// No network/native calls: this suite exercises rendering, not settings actions.
class _Settings extends ChangeNotifier implements SettingsViewModel {
  final bool populated;
  _Settings(this.populated);
  @override
  Future<void> markDailyReminderOffered() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      switch (invocation.memberName) {
        #notifications => <AppNotificationItem>[
          if (populated)
            for (var i = 0; i < 20; i++)
              AppNotificationItem(
                id: 'notification-$i',
                title: auditLongName,
                body: '$auditLongName. $auditLongName.',
                receivedAt: DateTime.now(),
                data: const {},
                source: NotificationSource.foreground,
              ),
        ],
        #coolingOffDays => 3,
        #maxWishlistItems => 50,
        #dailyReminderHour => 20,
        #dailyReminderMinute => 0,
        #dailyReminderTimeText => '20:00',
        _ => false,
      };
}

const auditLongName =
    'Tai nghe không dây chống ồn phiên bản đặc biệt màu xanh lá cây';

class _Photo extends PhotoSearchViewModel {
  final bool populated;
  static final _preview = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4////fwAJ+wP9KobjigAAAABJRU5ErkJggg==',
  );
  _Photo(this.populated, RemoteConfigService remote)
    : super(
        aiService: AiPhotoSearchService(generator: _ImageGenerator()),
        remoteConfigService: remote,
        preferencesService: PreferencesService(),
        platformSupportsAi: () => false,
      );

  @override
  Uint8List? get imageBytes => populated ? _preview : null;

  @override
  UiState<ItemRecognition> get state => populated
      ? const UiSuccess(
          ItemRecognition(
            name: auditLongName,
            brand: auditLongName,
            category: auditLongName,
            alternatives: [auditLongName],
            priceMinVnd: 888888888,
            priceMaxVnd: 999999999,
          ),
        )
      : const UiInitial();

  @override
  String? get selectedName => populated ? auditLongName : null;

  @override
  String get searchQuery => populated ? auditLongName : '';

  @override
  bool get canSearchPrices => populated;

  @override
  UiState<PriceSearchResult> get priceState => populated
      ? UiSuccess(
          PriceSearchResult(
            query: auditLongName,
            offers: List.generate(
              20,
              (_) => const PriceOffer(shop: auditLongName, priceVnd: 999999999),
            ),
          ),
        )
      : const UiInitial();
}

/// Fake camera preview; no native camera or permission dialog.
class AuditScanner extends MobileScannerPlatform {
  final bool denied;
  AuditScanner({this.denied = false});
  @override
  Stream<BarcodeCapture?> get barcodesStream => const Stream.empty();
  @override
  Stream<TorchState> get torchStateStream => const Stream.empty();
  @override
  Stream<double> get zoomScaleStateStream => const Stream.empty();
  @override
  Widget buildCameraView() => const ColoredBox(color: Colors.black);
  @override
  Future<MobileScannerViewAttributes> start(StartOptions options) async {
    if (denied) {
      throw const MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
      );
    }
    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.off,
      size: Size(360, 480),
    );
  }

  @override
  Future<void> stop() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> dispose() async {}
  @override
  Future<void> updateScanWindow(Rect? window) async {}
}

/// Real ViewModels over in-memory Firestore, never a live Firebase project.
class UiAuditHarness {
  final bool populated;
  final h = PurchaseHarness();
  final _owned = <ChangeNotifier>[];
  UiAuditHarness(this.populated);
  final now = DateTime.now();
  late final item = WishlistItem(
    id: 'audit-item',
    title: auditLongName,
    latestPriceVnd: 999999999,
    motive: BuyingMotive.sale,
    budgetGroupId: 'tech',
    createdAt: now,
    shopName: 'Cửa hàng thiết bị âm thanh chính hãng phiên bản đặc biệt',
    note: auditLongName,
    variantLabel: auditLongName,
    vouchers: const [
      'Giảm 20% khi đơn hàng đủ điều kiện theo chính sách của shop',
    ],
  );
  late final purchase = PurchaseItem(
    id: 'audit-purchase',
    title: auditLongName,
    amountVnd: 999999999,
    motive: BuyingMotive.sale,
    occurredAt: now,
    budgetGroupId: 'tech',
    note: auditLongName,
  );
  late final sale = SaleEvent(
    id: 'sale',
    name: auditLongName,
    date: now,
    type: SaleType.doubleDay,
    confirmed: true,
  );

  Map<String, Widget> get screens => {
    'onboarding': const OnboardingScreen(),
    'login': const LoginScreen(),
    'signup': const LoginScreen(mode: AuthMode.signup),
    'forgot_password': const LoginScreen(mode: AuthMode.forgotPassword),
    'home': const HomeScreen(),
    'history': const HistoryScreen(),
    'patterns': const PatternsScreen(),
    'profile': const ProfileScreen(),
    'budget': const BudgetScreen(),
    'wishlist': const WishlistScreen(),
    'add_item': populated
        ? AddItemScreen(existing: item)
        : const AddItemScreen(),
    'item_detail': ItemDetailScreen(
      item: populated ? item : sampleWishlist(price: null),
    ),
    'record_purchase': RecordPurchaseScreen(
      initialTitle: populated ? auditLongName : null,
      initialAmount: populated ? 999999999 : null,
    ),
    'record_purchase_step2': const RecordPurchaseScreen(
      initialTitle: auditLongName,
      initialAmount: 999999999,
    ),
    'record_purchase_keyboard': const RecordPurchaseScreen(),
    'add_item_keyboard': const AddItemScreen(),
    'purchase_detail': PurchaseDetailScreen(purchase: purchase),
    'pre_purchase': const PrePurchaseScreen(),
    'shopping_profile': const ShoppingProfileScreen(),
    'feedback': const FeedbackScreen(),
    'info_text': const InfoTextScreen(document: LegalTexts.privacy),
    'insights': const InsightsScreen(),
    'monthly_reflection': const MonthlyReflectionScreen(),
    'main_navigation': const MainNavigationScreen(),
    'compare_items': CompareItemsScreen(item: item),
    'sale_calendar': const SaleCalendarScreen(),
    'sale_suggestion': const SaleSuggestionScreen(),
    'inbox': const InboxScreen(),
    'sale_list': SaleListScreen(sale: sale),
    'sale_plan': SalePlanScreen(sale: sale),
    'email_verification': const EmailVerificationScreen(),
    'reminder_permission': const ReminderPermissionScreen(),
    'photo_search': const PhotoSearchScreen(),
    'pre_purchase_result': PrePurchaseResultScreen(
      answers: PrePurchaseAnswers(
        title: auditLongName,
        why: WhyAnswer.need,
        influence: InfluenceAnswer.none,
        usage: UsageAnswer.daily,
        similar: SimilarOwnedAnswer.none,
      ),
    ),
    'price_history': PriceHistoryScreen(
      productKey: InMemoryPriceHistoryService.keys.first,
    ),
    'extension_qr_scan': const ExtensionQrScanScreen(),
    'dev/widget_gallery': const WidgetGalleryScreen(),
    'dev/price_chart_gallery': const Scaffold(
      body: SingleChildScrollView(child: PriceChartGallerySection()),
    ),
    'modal/budget': const _BudgetModal(),
    'modal/month_picker': const _MonthModal(),
    'modal/notifications': const _NotificationsModal(),
    'dialog/delete': const _DeleteDialog(),
  };

  Future<Widget> app(String screen, ThemeData theme, double scale) async {
    SharedPreferences.setMockInitialValues({});
    final auth = _Auth(populated);
    final settings = _Settings(populated);
    final themeVm = ThemeViewModel();
    final shopping = ShoppingProfileViewModel(
      service: FirestoreShoppingProfileService(h.db),
    )..updateUid(PurchaseHarness.uid);
    final linked = LinkedAccountsViewModel(
      authService: FakeLinkAuthService(null),
      userService: FirestoreUserService(h.db),
      isAvailable: true,
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
    final report = ReportViewModel(
      reportService: ReportService(),
      shareService: _Share(),
      analyticsService: h.analytics,
    );
    final reflection = ReflectionViewModel(
      reflectionService: FirestoreReflectionService(h.db),
    )..updateUid(PurchaseHarness.uid);
    final prePurchase = PrePurchaseViewModel(
      aiService: AiPrePurchaseService(generator: _Generator()),
      remoteConfigService: remote,
      preferencesService: PreferencesService(),
      platformSupportsAi: () => false,
    );
    final photo = _Photo(populated, remote);
    final decisions = DecisionSupportViewModel(
      budgetService: h.budgetService,
      wishlistService: FirestoreWishlistService(h.db),
      aiDecisionService: AiDecisionService(generator: _Generator()),
      remoteConfigService: remote,
      preferencesService: PreferencesService(),
      platformSupportsAi: () => false,
    );
    final priceService = populated
        ? InMemoryPriceHistoryService.sample(now)
        : InMemoryPriceHistoryService(products: {}, reports: {});
    final price = PriceHistoryViewModel(service: priceService);
    // Cross-role flow: long texts in every row, dates at both ends of the range
    if (populated) {
      for (var i = 0; i < 12; i++) {
        await h.db.collection('announcements').add({
          'title': auditLongName,
          'body': '$auditLongName. $auditLongName.',
          'status': 'published',
          'createdAt': DateTime(2026, 11, 1 + i),
        });
        await h.db.collection('saleSuggestions').add({
          'uid': PurchaseHarness.uid,
          'name': 'Sale 12.12 dài bốn mươi ký tự cho kiểm',
          'date': DateTime(2026, 12, 12),
          'note': auditLongName,
          'status': ['pending', 'approved', 'rejected'][i % 3],
          'reason': auditLongName,
          'createdAt': DateTime(2026, 11, 1 + i),
        });
      }
    }
    final inbox = InboxViewModel(
      announcementService: core.FirestoreAnnouncementService(h.db),
      inboxService: core.FirestoreInboxService(h.db),
      preferencesService: PreferencesService(),
    )..updateUid(PurchaseHarness.uid);
    final suggestions = SaleSuggestionViewModel(
      service: core.FirestoreSaleSuggestionService(h.db),
    )..updateUser(PurchaseHarness.uid, isAnonymous: false);
    await price.openProduct(InMemoryPriceHistoryService.keys.first);
    await h.initialize();
    if (populated) {
      for (var i = 0; i < 20; i++) {
        await h.db
            .doc('users/user-a/wishlistItems/item-$i')
            .set(item.copyWith(buyIntentAt: i == 0 ? now : null).toMap());
        await h.db
            .doc('users/user-a/purchases/purchase-$i')
            .set(purchase.toMap());
        await h.db
            .doc('users/user-a/ownedItems/owned-$i')
            .set(
              OwnedItem(
                id: 'owned-$i',
                name: auditLongName,
                note: auditLongName,
                tags: const [auditLongName],
                createdAt: now,
              ).toMap(),
            );
      }
      await h.db
          .doc('users/user-a')
          .set(
            const ShoppingTags(
              styles: [auditLongName],
              brands: [auditLongName],
            ).toMap(),
          );
      await h.budgetService.setGroupLimit(
        PurchaseHarness.uid,
        monthKey(now),
        'tech',
        999999999,
      );
    }
    insights.updateSources(
      purchases: populated ? List.filled(20, purchase) : [],
      wishlistItems: populated ? List.filled(20, item) : [],
      month: now,
    );
    _owned.addAll([
      auth,
      settings,
      themeVm,
      shopping,
      linked,
      devices,
      decisions,
      insights,
      report,
      reflection,
      prePurchase,
      photo,
      price,
      inbox,
      suggestions,
    ]);
    return h.app(
      MultiProvider(
        providers: [
          Provider<ReviewReminderService>.value(value: _Reminders()),
          Provider<ShareIntentService>(create: (_) => ShareIntentService()),
          Provider<PriceHistoryService>.value(value: priceService),
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
          ChangeNotifierProvider<PhotoSearchViewModel>.value(value: photo),
          ChangeNotifierProvider.value(value: price),
          ChangeNotifierProvider.value(value: inbox),
          ChangeNotifierProvider.value(value: suggestions),
        ],
        child: screens[screen]!,
      ),
      theme: theme,
      textScale: scale,
    );
  }

  void dispose() {
    h.dispose();
    for (final vm in _owned) {
      vm.dispose();
    }
  }
}

class _BudgetModal extends StatelessWidget {
  const _BudgetModal();
  @override
  Widget build(BuildContext context) => Scaffold(
    body: TextButton(
      onPressed: () => BudgetSettingSheet.show(context),
      child: const Text('Mở kiểm tra'),
    ),
  );
}

class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog();
  @override
  Widget build(BuildContext context) => Scaffold(
    body: TextButton(
      onPressed: () => ConfirmDialog.show(
        context,
        title: 'Xoá món này?',
        message: auditLongName,
        confirmLabel: 'Xoá',
        isDanger: true,
      ),
      child: const Text('Mở kiểm tra'),
    ),
  );
}

class _MonthModal extends StatelessWidget {
  const _MonthModal();
  @override
  Widget build(BuildContext context) => Scaffold(
    body: TextButton(
      onPressed: () => MonthPickerSheet.show(context, DateTime.now()),
      child: const Text('Mở kiểm tra'),
    ),
  );
}

class _NotificationsModal extends StatelessWidget {
  const _NotificationsModal();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(appBar: null, body: AppHeaderActions());
}
