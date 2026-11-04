import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/app/routes.dart';
import 'package:prm393_lab03/core/errors/app_exception.dart';
import 'package:prm393_lab03/models/buying_motive.dart';
import 'package:prm393_lab03/models/purchase_draft.dart';
import 'package:prm393_lab03/models/purchase_item.dart';
import 'package:prm393_lab03/models/wishlist_item.dart';
import 'package:prm393_lab03/services/analytics_service.dart';
import 'package:prm393_lab03/services/budget_service.dart';
import 'package:prm393_lab03/services/purchase_service.dart';
import 'package:prm393_lab03/services/wishlist_service.dart';
import 'package:prm393_lab03/theme/app_theme.dart';
import 'package:prm393_lab03/viewmodels/budget_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/purchase_viewmodel.dart';
import 'package:prm393_lab03/viewmodels/wishlist_viewmodel.dart';
import 'package:provider/provider.dart';

class TestAnalytics extends Fake implements AppAnalyticsService {
  int recordedPurchases = 0;
  int buyDecisions = 0;

  @override
  Future<void> logPurchaseRecorded({
    required String motive,
    required int amountVnd,
    required String budgetGroupId,
  }) async {
    recordedPurchases++;
  }

  @override
  Future<void> logMakeDecision({
    required String decision,
    required String motive,
    required int? priceVnd,
  }) async {
    if (decision == 'buy') buyDecisions++;
  }

  @override
  Future<void> logAddToWishlist({
    required String motive,
    required int? priceVnd,
  }) async {}

  @override
  Future<void> logViewItemDetail({
    required String motive,
    required int daysInCooldown,
  }) async {}
}

/// Real persistence code with controllable request completion, never live Firebase.
class ControlledPurchaseService implements PurchaseService {
  final PurchaseService delegate;
  Completer<void>? gate;
  bool rejectWrites = false;
  int addCalls = 0;
  int buyCalls = 0;
  int updateCalls = 0;

  ControlledPurchaseService(this.delegate);

  Future<void> _beforeWrite() async {
    await gate?.future;
    if (rejectWrites) {
      throw const AppException(
        'unavailable',
        'Chưa lưu được. Vui lòng thử lại.',
      );
    }
  }

  @override
  Stream<List<PurchaseItem>> watchPurchases(
    String uid, {
    DateTime? from,
    DateTime? to,
  }) => delegate.watchPurchases(uid, from: from, to: to);

  @override
  Future<PurchaseItem> add(String uid, PurchaseItem purchase) async {
    addCalls++;
    await _beforeWrite();
    return delegate.add(uid, purchase);
  }

  @override
  Future<PurchaseItem> buyFromWishlist(
    String uid,
    WishlistItem item,
    PurchaseDraft draft,
  ) async {
    buyCalls++;
    await _beforeWrite();
    return delegate.buyFromWishlist(uid, item, draft);
  }

  @override
  Future<void> update(String uid, PurchaseItem purchase) async {
    updateCalls++;
    await _beforeWrite();
    return delegate.update(uid, purchase);
  }

  @override
  Future<void> delete(String uid, String purchaseId) async {
    await _beforeWrite();
    return delegate.delete(uid, purchaseId);
  }

  @override
  Future<void> setSatisfaction(String uid, String purchaseId, int? stars) async {
    await _beforeWrite();
    return delegate.setSatisfaction(uid, purchaseId, stars);
  }
}

class PurchaseHarness {
  static const uid = 'user-a';
  final db = FakeFirebaseFirestore();
  final analytics = TestAnalytics();
  late final service = ControlledPurchaseService(FirestorePurchaseService(db));
  late final purchases = PurchaseViewModel(
    purchaseService: service,
    analyticsService: analytics,
  );
  late final wishlist = WishlistViewModel(
    wishlistService: FirestoreWishlistService(db),
    analyticsService: analytics,
  );
  late final budgetService = FirestoreBudgetService(db);
  late final budget = BudgetViewModel(budgetService: budgetService);

  Future<void> initialize({WishlistItem? item, PurchaseItem? purchase}) async {
    await budgetService.ensureDefaultGroups(uid);
    if (item != null) {
      await db.doc('users/$uid/wishlistItems/${item.id}').set(item.toMap());
    }
    if (purchase != null) {
      await db.doc('users/$uid/purchases/${purchase.id}').set(purchase.toMap());
    }
    purchases.updateUid(uid);
    wishlist.updateUid(uid);
    budget.updateUid(uid);
  }

  Widget app(Widget home, {double textScale = 1}) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: purchases),
      ChangeNotifierProvider.value(value: wishlist),
      ChangeNotifierProxyProvider<PurchaseViewModel, BudgetViewModel>(
        create: (_) => budget,
        update: (_, vm, existing) => existing!
          ..updateSources(purchases: vm.allPurchases, month: vm.selectedMonth),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: home,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
    ),
  );

  void dispose() {
    purchases.dispose();
    wishlist.dispose();
    // The ChangeNotifierProxyProvider owns budget when app() has been mounted.
  }
}

WishlistItem sampleWishlist({int? price = 420000}) => WishlistItem(
  id: 'headphones',
  title: 'Tai nghe Bluetooth',
  latestPriceVnd: price,
  motive: BuyingMotive.sale,
  budgetGroupId: 'tech',
  createdAt: DateTime.now(),
);
