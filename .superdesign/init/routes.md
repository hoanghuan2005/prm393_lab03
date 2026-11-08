# Routes

Navigation in the mobile app (`prm393_lab03/`) uses Flutter named routes: `MaterialApp(home: AuthGate(), onGenerateRoute: AppRoutes.onGenerateRoute)` in `prm393_lab03/lib/app/app.dart`. Every pushed route is a full-screen `MaterialPageRoute`; screens navigate only through `AppRoutes` names with typed argument classes. The 5-tab shell (`MainNavigationScreen`) is shown by `AuthGate` once the user is signed in, and switching tabs is in-shell state (`IndexedStack`), not a route push.

## Source: `prm393_lab03/lib/app/routes.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/constants/legal_texts.dart';
import '../models/buying_motive.dart';
import '../models/pre_purchase_check.dart';
import '../models/purchase_item.dart';
import '../models/sale_event.dart';
import '../models/same_product.dart';
import '../models/wishlist_item.dart';
import '../screens/add_item_screen.dart';
import '../screens/budget_screen.dart';
import '../screens/compare_items_screen.dart';
import '../screens/dev/widget_gallery_screen.dart';
import '../screens/feedback_screen.dart';
import '../screens/history_screen.dart';
import '../screens/info_text_screen.dart';
import '../screens/insights_screen.dart';
import '../screens/item_detail_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/monthly_reflection_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/patterns_screen.dart';
import '../screens/photo_search_screen.dart';
import '../screens/pre_purchase_result_screen.dart';
import '../screens/pre_purchase_screen.dart';
import '../screens/price_history_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/purchase_detail_screen.dart';
import '../screens/record_purchase_screen.dart';
import '../screens/reminder_permission_screen.dart';
import '../screens/sale_screens.dart';
import '../screens/shopping_profile_screen.dart';
import '../screens/wishlist_screen.dart';
import '../widgets/price_history_chart.dart' show SavedPrice;

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

/// Arguments for [AppRoutes.priceHistory]: a product (can switch to its group) or a group
class PriceHistoryArgs {
  final String? productKey;
  final String? groupId;

  /// Real product (G8): the same item in other shops, for "Cả nhóm"
  final SameProductLinks? sameProduct;

  /// "Giá lúc bạn lưu" line of the chart (G5c)
  final SavedPrice? savedPrice;

  const PriceHistoryArgs({
    this.productKey,
    this.groupId,
    this.sameProduct,
    this.savedPrice,
  });
}

/// Arguments for [AppRoutes.wishlistAdd] and [AppRoutes.wishlistEdit]
class AddItemArgs {
  final WishlistItem? existing;
  final String? initialTitle;
  final String? initialUrl;
  final int? initialPrice;
  final String? initialImageUrl;
  final String? shopName;
  final String? productDescription;

  const AddItemArgs({
    this.existing,
    this.initialTitle,
    this.initialUrl,
    this.initialPrice,
    this.initialImageUrl,
    this.shopName,
    this.productDescription,
  });
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

  /// Pre-selected motive, e.g. from "Trước khi mua" → "Vẫn mua"
  final BuyingMotive? initialMotive;
  final PurchaseItem? existingPurchase;
  final WishlistItem? wishlistItem;

  const RecordPurchaseArgs({
    this.initialAmount,
    this.initialTitle,
    this.initialMotive,
    this.existingPurchase,
    this.wishlistItem,
  }) : assert(existingPurchase == null || wishlistItem == null);
}

/// Arguments for [AppRoutes.prePurchaseResult]
class PrePurchaseArgs {
  final PrePurchaseAnswers answers;

  const PrePurchaseArgs(this.answers);
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
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const onboarding = '/onboarding';
  static const wishlist = '/wishlist';
  static const wishlistAdd = '/wishlist/add';
  static const wishlistEdit = '/wishlist/edit';
  static const itemDetail = '/wishlist/detail';

  /// A-15: items of the same budget group side by side (args: [ItemDetailArgs])
  static const wishlistCompare = '/wishlist/compare';

  /// "Giá tham khảo" (PriceHistoryArgs)
  static const priceHistory = '/price-history';
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

  /// Flow 9 "Trước khi mua": questions (14–16), then AI analysis and result (17–18)
  static const prePurchase = '/before-buy';
  static const prePurchaseResult = '/before-buy/result';

  /// "Chụp để tìm": photo → AI names the item → search / add to the wishlist
  static const photoSearch = '/photo-search';

  /// Screen 05a "Xin quyền thông báo" (returns true when the reminder was turned on)
  static const reminderPermission = '/reminder/permission';

  /// Cá nhân → Hỗ trợ & thông tin
  static const feedback = '/profile/feedback';
  static const terms = '/profile/terms';
  static const privacy = '/profile/privacy';

  /// Debug builds only (shared widget catalogue)
  static const widgetGallery = '/dev/widgets';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;
    final Widget? page = switch (settings.name) {
      shell => MainNavigationScreen(
        initialIndex: args is ShellArgs ? args.initialIndex : 0,
      ),
      login => const LoginScreen(),
      signup => const LoginScreen(mode: AuthMode.signup),
      forgotPassword => const LoginScreen(mode: AuthMode.forgotPassword),
      onboarding => const OnboardingScreen(),
      wishlist => const WishlistScreen(),
      wishlistAdd => AddItemScreen(
        existing: args is AddItemArgs ? args.existing : null,
        initialTitle: args is AddItemArgs ? args.initialTitle : null,
        initialUrl: args is AddItemArgs ? args.initialUrl : null,
        initialPrice: args is AddItemArgs ? args.initialPrice : null,
        initialImageUrl: args is AddItemArgs ? args.initialImageUrl : null,
        shopName: args is AddItemArgs ? args.shopName : null,
        productDescription: args is AddItemArgs
            ? args.productDescription
            : null,
      ),
      wishlistEdit when args is ItemDetailArgs => AddItemScreen(
        existing: args.item,
      ),
      wishlistEdit when args is AddItemArgs => AddItemScreen(
        existing: args.existing,
        initialTitle: args.initialTitle,
        initialUrl: args.initialUrl,
        initialPrice: args.initialPrice,
        initialImageUrl: args.initialImageUrl,
        shopName: args.shopName,
        productDescription: args.productDescription,
      ),
      itemDetail when args is ItemDetailArgs => ItemDetailScreen(
        item: args.item,
      ),
      recordPurchase => RecordPurchaseScreen(
        initialAmount: args is RecordPurchaseArgs ? args.initialAmount : null,
        initialTitle: args is RecordPurchaseArgs ? args.initialTitle : null,
        initialMotive: args is RecordPurchaseArgs ? args.initialMotive : null,
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
      priceHistory
          when args is PriceHistoryArgs &&
              (args.productKey != null || args.groupId != null) =>
        PriceHistoryScreen.withViewModel(
          productKey: args.productKey,
          groupId: args.groupId,
          sameProduct: args.sameProduct,
          savedPrice: args.savedPrice,
        ),
      sales => const SaleCalendarScreen(),
      saleList when args is SaleArgs => SaleListScreen(sale: args.sale),
      salePlan when args is SaleArgs => SalePlanScreen(sale: args.sale),
      prePurchase => const PrePurchaseScreen(),
      prePurchaseResult when args is PrePurchaseArgs => PrePurchaseResultScreen(
        answers: args.answers,
      ),
      photoSearch => const PhotoSearchScreen(),
      reminderPermission => const ReminderPermissionScreen(),
      feedback => const FeedbackScreen(),
      terms => const InfoTextScreen(document: LegalTexts.terms),
      privacy => const InfoTextScreen(document: LegalTexts.privacy),
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
```

## Route table

Screen paths are relative to `prm393_lab03/lib/screens/`. "Tab" marks the screens that are tabs of the shell (`MainNavigationScreen`); when pushed by their own route they open standalone, without the shell's bottom bar and without the shell's back/profile callbacks.

| Route | Screen file (widget) | What it renders | Shell tab |
|---|---|---|---|
| `/home` (`shell`) | `main_navigation_screen.dart` (`MainNavigationScreen`) | The 5-tab shell with the custom bottom bar; `ShellArgs.initialIndex` picks the opening tab | Shell itself |
| (no route; tab 0 only) | `home_screen.dart` (`HomeScreen`) | Trang chủ: greeting, "Ghi khoản mua" CTA, monthly overview, shortcuts (wishlist, Trước khi mua, Chụp để tìm), recent purchases (screen 02) | Tab 0 Trang chủ |
| `/history` | `history_screen.dart` (`HistoryScreen`) | Lịch sử: list of recorded purchases (screen 06) | Tab 1 Lịch sử |
| `/patterns` | `patterns_screen.dart` (`PatternsScreen`) | Mô hình: week/month spending totals, breakdown by motive, shopping time slots (screen 07) | Tab 2 Mô hình |
| `/insights` | `insights_screen.dart` (`InsightsScreen`) | Góc nhìn: code-computed insights with AI-rewritten sentences (screen 08) | Tab 3 Góc nhìn |
| `/profile` | `profile_screen.dart` (`ProfileScreen`) | Cá nhân: profile, settings and Firebase demo area | Tab 4 Cá nhân |
| `/login` | `login_screen.dart` (`LoginScreen`) | Email sign-in plus Google, GitHub and guest options | |
| `/signup` | `login_screen.dart` (`LoginScreen(mode: AuthMode.signup)`) | Same auth screen in sign-up mode | |
| `/forgot-password` | `login_screen.dart` (`LoginScreen(mode: AuthMode.forgotPassword)`) | Same auth screen in password-reset mode | |
| `/onboarding` | `onboarding_screen.dart` (`OnboardingScreen`) | Onboarding / landing pages (screen 01) | |
| `/wishlist` | `wishlist_screen.dart` (`WishlistScreen`) | Smart wishlist with search and motive filters, list of `WishlistCard`s | |
| `/wishlist/add` | `add_item_screen.dart` (`AddItemScreen`) | Add-item form, optionally pre-filled from `AddItemArgs` (share sheet, photo search) (screen 04) | |
| `/wishlist/edit` | `add_item_screen.dart` (`AddItemScreen(existing: ...)`) | Same form editing an existing item (`ItemDetailArgs` or `AddItemArgs`) | |
| `/wishlist/detail` | `item_detail_screen.dart` (`ItemDetailScreen`) | Item detail and decision card (screen 03); needs `ItemDetailArgs` | |
| `/wishlist/compare` | `compare_items_screen.dart` (`CompareItemsScreen`) | Items of the same budget group side by side, facts only (A-15) | |
| `/price-history` | `price_history_screen.dart` (`PriceHistoryScreen.withViewModel`) | "Giá tham khảo": price chart of one product or its whole shop group | |
| `/purchase/record` | `record_purchase_screen.dart` (`RecordPurchaseScreen`) | "Ghi khoản mua" form; route returns the saved `PurchaseItem` | |
| `/purchase/detail` | `purchase_detail_screen.dart` (`PurchaseDetailScreen`) | Chi tiết khoản mua (screen 05); needs `PurchaseDetailArgs` | |
| `/budget` | `budget_screen.dart` (`BudgetScreen`) | Ngân sách theo nhóm with budget meters (screens 31, 31a, 31b) | |
| `/reflection` | `monthly_reflection_screen.dart` (`MonthlyReflectionScreen`) | Monthly reflection plus on-device PDF report (screen 09) | |
| `/profile/shopping` | `shopping_profile_screen.dart` (`ShoppingProfileScreen`) | Hồ sơ mua sắm: empty state, owned items, add/edit sheet (screen 24) | |
| `/sales` | `sale_screens.dart` (`SaleCalendarScreen`) | Lịch sale: public sale days for the next 60 days (screen 26) | |
| `/sales/list` | `sale_screens.dart` (`SaleListScreen`) | "Danh sách cho đợt sale": items still being considered; needs `SaleArgs` | |
| `/sales/plan` | `sale_screens.dart` (`SalePlanScreen`) | "Lập kế hoạch cho đợt sale": three plans within each group's budget; needs `SaleArgs` | |
| `/before-buy` | `pre_purchase_screen.dart` (`PrePurchaseScreen`) | "Trước khi mua" quick question steps (screens 14–16) | |
| `/before-buy/result` | `pre_purchase_result_screen.dart` (`PrePurchaseResultScreen`) | AI analysing, then "Nhận định trước khi mua" result (screens 17–18) | |
| `/photo-search` | `photo_search_screen.dart` (`PhotoSearchScreen`) | "Chụp để tìm": photo frame, AI-named product card, actions pinned to the bottom | |
| `/reminder/permission` | `reminder_permission_screen.dart` (`ReminderPermissionScreen`) | "Xin quyền thông báo" one-time prompt (screen 05a); returns true when enabled | |
| `/profile/feedback` | `feedback_screen.dart` (`FeedbackScreen`) | "Gửi góp ý": bug report / feature request form | |
| `/profile/terms` | `info_text_screen.dart` (`InfoTextScreen(document: LegalTexts.terms)`) | Read-only "Điều khoản sử dụng" text page | |
| `/profile/privacy` | `info_text_screen.dart` (`InfoTextScreen(document: LegalTexts.privacy)`) | Read-only "Chính sách quyền riêng tư" text page | |
| `/dev/widgets` | `dev/widget_gallery_screen.dart` (`WidgetGalleryScreen`) | Debug-only catalogue of the shared widgets with sample values (`kDebugMode`) | |

Screens reached without a named route:
- `email_verification_screen.dart` (`EmailVerificationScreen`): shown by `AuthGate` when the signed-in account still needs email verification.
- `extension_qr_scan_screen.dart` (`ExtensionQrScanScreen`): pushed with a plain `MaterialPageRoute` from `ExtensionQrScanScreen.open` (Cá nhân → Thiết bị đã liên kết → "Quét mã QR").

## Web admin (secondary)

`prm393_flutter_admin/` does not use named routes for its pages: after sign-in (`prm393_flutter_admin/lib/screens/sign_in_screen.dart`) `AdminShell` switches between six sections held in `ShellViewModel` (`AdminSection`: Tổng quan → `dashboard_screen.dart`, Người dùng → `users_screen.dart`, Sự kiện sale → `sale_events_screen.dart`, Duyệt đề xuất → `review_queue_screen.dart`, Thông báo → `announcements_screen.dart`, Trợ lý AI → `ai_assistant_screen.dart`) inside an `IndexedStack`.
