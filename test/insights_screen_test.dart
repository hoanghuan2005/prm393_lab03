import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/models/buying_motive.dart';
import 'package:prm393_lab03/models/purchase_draft.dart';
import 'package:prm393_lab03/models/purchase_item.dart';
import 'package:prm393_lab03/models/wishlist_item.dart';
import 'package:prm393_lab03/screens/insights_screen.dart';
import 'package:prm393_lab03/services/ai_insight_service.dart';
import 'package:prm393_lab03/services/ai_service.dart';
import 'package:prm393_lab03/services/crashlytics_service.dart';
import 'package:prm393_lab03/services/preferences_service.dart';
import 'package:prm393_lab03/services/purchase_service.dart';
import 'package:prm393_lab03/services/remote_config_service.dart';
import 'package:prm393_lab03/theme/app_theme.dart';
import 'package:prm393_lab03/viewmodels/insights_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/purchase_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The demo data PurchaseViewModel used to seed before B7 (10/2026 + 9/2026)
final _purchases = [
  _p(
    'Cơm tấm',
    40000,
    BuyingMotive.convenience,
    DateTime(2026, 10, 11, 12, 15),
  ),
  _p(
    'Tai nghe Bluetooth',
    389000,
    BuyingMotive.sale,
    DateTime(2026, 10, 10, 23, 40),
  ),
  _p(
    'Trà sữa nướng',
    45000,
    BuyingMotive.emotion,
    DateTime(2026, 10, 10, 15, 30),
  ),
  _p(
    'Sách Tâm lý học về tiền',
    143000,
    BuyingMotive.want,
    DateTime(2026, 10, 9, 9, 20),
  ),
  _p(
    'Áo khoác gió Uniqlo',
    200000,
    BuyingMotive.sale,
    DateTime(2026, 10, 8, 19, 45),
  ),
  _p(
    'Giày chạy bộ thể thao',
    1250000,
    BuyingMotive.need,
    DateTime(2026, 9, 28, 16, 20),
  ),
  _p(
    'Bàn phím cơ văn phòng',
    450000,
    BuyingMotive.want,
    DateTime(2026, 9, 15, 10, 0),
  ),
  _p(
    'Cà phê & Bánh ngọt',
    85000,
    BuyingMotive.emotion,
    DateTime(2026, 9, 5, 14, 30),
  ),
];

PurchaseItem _p(String title, int amount, BuyingMotive motive, DateTime at) =>
    PurchaseItem(
      id: title,
      title: title,
      amountVnd: amount,
      motive: motive,
      occurredAt: at,
    );

class _FakePurchaseService implements PurchaseService {
  @override
  Stream<List<PurchaseItem>> watchPurchases(
    String uid, {
    DateTime? from,
    DateTime? to,
  }) => Stream.value(_purchases);

  @override
  Future<PurchaseItem> add(String uid, PurchaseItem purchase) =>
      throw UnimplementedError();

  @override
  Future<void> update(String uid, PurchaseItem purchase) =>
      throw UnimplementedError();

  @override
  Future<void> delete(String uid, String purchaseId) =>
      throw UnimplementedError();

  @override
  Future<PurchaseItem> buyFromWishlist(
    String uid,
    WishlistItem item,
    PurchaseDraft draft,
  ) => throw UnimplementedError();
}

class _FakeRemoteConfig extends Fake implements FirebaseRemoteConfig {
  @override
  bool getBool(String key) => true;

  @override
  int getInt(String key) => 3;

  @override
  String getString(String key) => '';
}

class _FakeGenerator implements AiService {
  int calls = 0;

  @override
  Future<String> generateJson({
    required String systemInstruction,
    required String prompt,
    required List<String> cardIds,
  }) async {
    calls++;
    return jsonEncode({
      'summary': 'Tháng 10/2026 bạn đã ghi 5 khoản mua.',
      'cards': [
        {
          'id': 'dominant_motive',
          'title': 'Khuyến mãi xuất hiện nhiều',
          'body': 'Có 2 trong 5 khoản bạn ghi là Khuyến mãi.',
        },
      ],
    });
  }

  @override
  Future<String> generateChoice({
    required String systemInstruction,
    required String prompt,
    required AiChoiceSchema schema,
  }) => throw UnimplementedError('Not used by Góc nhìn');
}

void main() {
  late _FakeGenerator generator;

  Future<InsightsViewModel> pumpInsights(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    generator = _FakeGenerator();
    // A signed-in user, as in the app: the screen waits for purchases to load
    final purchaseVm =
        PurchaseViewModel(purchaseService: _FakePurchaseService())
          ..updateUid('user-a')
          ..setSelectedMonth(DateTime(2026, 10));
    final insightsVm = InsightsViewModel(
      aiInsightService: AiInsightService(generator: generator),
      remoteConfigService: RemoteConfigService(
        remoteConfig: _FakeRemoteConfig(),
      ),
      preferencesService: PreferencesService(),
      crashlyticsService: CrashlyticsService(),
    );
    insightsVm.updateSources(
      purchases: _purchases,
      wishlistItems: const [],
      month: purchaseVm.selectedMonth,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: purchaseVm),
          ChangeNotifierProvider.value(value: insightsVm),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const InsightsScreen(),
        ),
      ),
    );
    insightsVm.setVisible(true);
    await tester.pumpAndSettle();
    return insightsVm;
  }

  testWidgets('shows AI-written cards with an AI label on Android', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await pumpInsights(tester);

    expect(generator.calls, 1);
    expect(find.text('Khuyến mãi xuất hiện nhiều'), findsOneWidget);
    expect(find.text('AI'), findsWidgets);
    // Cards the AI did not write keep the template wording
    expect(find.text('Câu mẫu'), findsWidgets);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('falls back to templates on Windows without calling AI', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    await pumpInsights(tester);

    expect(generator.calls, 0);
    expect(
      find.textContaining('AI chưa hỗ trợ trên nền tảng này'),
      findsOneWidget,
    );
    expect(find.text('AI'), findsNothing);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('turning AI off shows templates and remembers the choice', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final vm = await pumpInsights(tester);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(vm.userAiEnabled, isFalse);
    expect(find.textContaining('Bạn đã tắt AI'), findsOneWidget);
    expect(await PreferencesService().getAiInsightEnabled(), isFalse);
    debugDefaultTargetPlatformOverride = null;
  });
}
