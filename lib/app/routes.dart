import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/purchase_item.dart';
import '../models/sale_event.dart';
import '../models/wishlist_item.dart';
import '../screens/add_item_screen.dart';
import '../screens/budget_screen.dart';
import '../screens/compare_items_screen.dart';
import '../screens/dev/widget_gallery_screen.dart';
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
import '../screens/sale_screens.dart';
import '../screens/shopping_profile_screen.dart';
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
  final int? initialAmount;
  final String? initialTitle;
  final PurchaseItem? existingPurchase;
  final WishlistItem? wishlistItem;

  const RecordPurchaseArgs({
    this.initialAmount,
    this.initialTitle,
    this.existingPurchase,
    this.wishlistItem,
  }) : assert(existingPurchase == null || wishlistItem == null);
}

/// Arguments for [AppRoutes.saleList] and [AppRoutes.salePlan]
class SaleArgs {
  final SaleEvent sale;

  const SaleArgs(this.sale);
}

/// Every named route in the app. Screens navigate only through these names.
class AppRoutes {
  AppRoutes._();

  /// Main shell with bottom navigation (Trang chủ, Lịch sử, …)
  static const shell = '/home';
  static const onboarding = '/onboarding';
  static const wishlist = '/wishlist';
  static const wishlistAdd = '/wishlist/add';
  static const wishlistEdit = '/wishlist/edit';
  static const itemDetail = '/wishlist/detail';

  /// A-15: items of the same budget group side by side (args: [ItemDetailArgs])
  static const wishlistCompare = '/wishlist/compare';
  static const recordPurchase = '/purchase/record';
  static const purchaseDetail = '/purchase/detail';
  static const history = '/history';
  static const budget = '/budget';
  static const insights = '/insights';
  static const patterns = '/patterns';
  static const reflection = '/reflection';
  static const profile = '/profile';

  /// Hồ sơ mua sắm (screen 24, spec 7.2)
  static const shoppingProfile = '/profile/shopping';

  /// Lịch sale (screen 26), "Danh sách cho đợt sale" and "Lập kế hoạch cho đợt sale"
  static const sales = '/sales';
  static const saleList = '/sales/list';
  static const salePlan = '/sales/plan';

  /// Debug builds only (shared widget catalogue)
  static const widgetGallery = '/dev/widgets';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;
    final Widget? page = switch (settings.name) {
      shell => MainNavigationScreen(
        initialIndex: args is ShellArgs ? args.initialIndex : 0,
      ),
      onboarding => const OnboardingScreen(),
      wishlist => const WishlistScreen(),
      wishlistAdd => const AddItemScreen(),
      wishlistEdit when args is ItemDetailArgs => AddItemScreen(
        existing: args.item,
      ),
      itemDetail when args is ItemDetailArgs => ItemDetailScreen(
        item: args.item,
      ),
      recordPurchase => RecordPurchaseScreen(
        initialAmount: args is RecordPurchaseArgs ? args.initialAmount : null,
        initialTitle: args is RecordPurchaseArgs ? args.initialTitle : null,
        existingPurchase: args is RecordPurchaseArgs
            ? args.existingPurchase
            : null,
        wishlistItem: args is RecordPurchaseArgs ? args.wishlistItem : null,
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
      shoppingProfile => const ShoppingProfileScreen(),
      wishlistCompare when args is ItemDetailArgs => CompareItemsScreen(
        item: args.item,
      ),
      sales => const SaleCalendarScreen(),
      saleList when args is SaleArgs => SaleListScreen(sale: args.sale),
      salePlan when args is SaleArgs => SalePlanScreen(sale: args.sale),
      widgetGallery when kDebugMode => const WidgetGalleryScreen(),
      _ => null,
    };
    if (page == null) return null;
    if (settings.name == recordPurchase) {
      return MaterialPageRoute<PurchaseItem>(
        builder: (_) => page,
        settings: settings,
      );
    }
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
