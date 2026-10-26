import 'package:flutter/material.dart';

import '../models/purchase_item.dart';
import '../models/wishlist_item.dart';
import '../screens/add_item_screen.dart';
import '../screens/budget_screen.dart';
import '../screens/history_screen.dart';
import '../screens/insights_screen.dart';
import '../screens/item_detail_screen.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/monthly_reflection_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/patterns_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/purchase_detail_screen.dart';
import '../screens/record_purchase_screen.dart';
import '../screens/wishlist_screen.dart';

/// Arguments for [AppRoutes.shell]
class ShellArgs {
  final int initialIndex;

  const ShellArgs({this.initialIndex = 0});
}

/// Arguments for [AppRoutes.itemDetail]
class ItemDetailArgs {
  final WishlistItem item;

  const ItemDetailArgs(this.item);
}

/// Arguments for [AppRoutes.purchaseDetail]
class PurchaseDetailArgs {
  final PurchaseItem purchase;

  const PurchaseDetailArgs(this.purchase);
}

/// Arguments for [AppRoutes.recordPurchase]; all optional (new purchase when empty)
class RecordPurchaseArgs {
  final double? initialAmount;
  final String? initialTitle;
  final PurchaseItem? existingPurchase;

  const RecordPurchaseArgs({
    this.initialAmount,
    this.initialTitle,
    this.existingPurchase,
  });
}

/// Every named route in the app. Screens navigate only through these names.
class AppRoutes {
  AppRoutes._();

  /// Main shell with bottom navigation (Trang chủ, Lịch sử, …)
  static const shell = '/home';
  static const onboarding = '/onboarding';
  static const wishlist = '/wishlist';
  static const wishlistAdd = '/wishlist/add';
  static const itemDetail = '/wishlist/detail';
  static const recordPurchase = '/purchase/record';
  static const purchaseDetail = '/purchase/detail';
  static const history = '/history';
  static const budget = '/budget';
  static const insights = '/insights';
  static const patterns = '/patterns';
  static const reflection = '/reflection';
  static const profile = '/profile';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;
    final Widget? page = switch (settings.name) {
      shell => MainNavigationScreen(
        initialIndex: args is ShellArgs ? args.initialIndex : 0,
      ),
      onboarding => const OnboardingScreen(),
      wishlist => const WishlistScreen(),
      wishlistAdd => const AddItemScreen(),
      itemDetail when args is ItemDetailArgs => ItemDetailScreen(
        item: args.item,
      ),
      recordPurchase => RecordPurchaseScreen(
        initialAmount: args is RecordPurchaseArgs ? args.initialAmount : null,
        initialTitle: args is RecordPurchaseArgs ? args.initialTitle : null,
        existingPurchase: args is RecordPurchaseArgs
            ? args.existingPurchase
            : null,
      ),
      purchaseDetail when args is PurchaseDetailArgs => PurchaseDetailScreen(
        purchase: args.purchase,
      ),
      history => const HistoryScreen(),
      budget => const BudgetScreen(),
      insights => const InsightsScreen(),
      patterns => const PatternsScreen(),
      reflection => const MonthlyReflectionScreen(),
      profile => const ProfileScreen(),
      _ => null,
    };
    if (page == null) return null;
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
