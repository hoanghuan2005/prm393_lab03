# Pages: Why I Buy (mobile)

Key screens of the Flutter mobile app in `prm393_lab03/`, each with its local-import dependency tree.
Material 3, Provider, MVVM. Font: Be Vietnam Pro (`theme/app_text_styles.dart`, via `GoogleFonts.beVietnamPro`).
Primary `#FFDE02`, light scaffold `#F8FAFC` (`theme/app_colors.dart`).

## How to read this file

- Paths in the trees are relative to `prm393_lab03/lib/`. Entry paths are relative to the repo root.
- Only UI-touching files are in the tree: `screens/`, `widgets/`, `theme/`, `core/formatters/`.
  Viewmodels, models, services, validators and constants are listed on one `logic:` line per screen (no visual code).
- Each file is expanded once per tree. A widget that shows up again is listed without children,
  marked `(dup)` when it has children shown above. Repeated `theme/` and `core/formatters/` leaves are left out.
- `app/routes.dart` imports every screen and `app/app.dart` is the app root, so both are leaves (not expanded).
- Every screen also gets the global theme: `app/app.dart` sets `theme: AppTheme.lightTheme` and
  `darkTheme: AppTheme.darkTheme` from `theme/app_theme.dart` (which builds on `app_colors`, `app_dimens`,
  `app_text_styles` and `motive_colors`). Screens never import `app_theme.dart` directly.
- Navigation is by named routes only: `AppRoutes.onGenerateRoute` in `app/routes.dart` maps each route to a screen.

## The shell (`/home`)

`/home` builds `MainNavigationScreen` (`prm393_lab03/lib/screens/main_navigation_screen.dart`), a bottom
navigation bar with five tabs: Trang chủ, Lịch sử, Mô hình, Góc nhìn, Cá nhân. Its tab list:

```dart
    final screens = [
      HomeScreen(onNavigateTab: _navigateToTab),
      HistoryScreen(
        onProfileTap: () => _navigateToTab(4),
        onBackTap: () => _navigateToTab(0),
      ),
      PatternsScreen(
        onProfileTap: () => _navigateToTab(4),
        onBackTap: () => _navigateToTab(0),
      ),
      InsightsScreen(
        onProfileTap: () => _navigateToTab(4),
        onBackTap: () => _navigateToTab(0),
      ),
      ProfileScreen(onBackTap: () => _navigateToTab(0)),
    ];
```

## /login, /signup, /forgot-password (LoginScreen)

One screen serves all three `AuthMode` values. A centered scroll column (max width 430) shows a back button, the brand header, a large title and subtitle, an optional error banner, then a `Form` with icon-prefixed fields (name on signup, email, password with show/hide toggle, confirm password on signup).
Below the form: a "Quên mật khẩu?" text link, the primary `AppButton`, then secondary `AppButton`s for Google, GitHub and "Dùng thử chế độ Khách", and a footer link that switches between Đăng nhập and Đăng ký.

Entry: `prm393_lab03/lib/screens/login_screen.dart`

Dependencies:

- `app/routes.dart` (route table; imports every screen, not expanded)
- `theme/app_colors.dart`
- `theme/app_dimens.dart`
- `theme/app_text_styles.dart`
- `widgets/app_button.dart`
- logic: `viewmodels/auth_viewmodel.dart`

## /onboarding (OnboardingScreen)

Top bar with `WhyIBuyLogo` + "Why I Buy?" and a "Bỏ qua" text button, then a non-swipeable `PageView` of three illustrated slides (motive tracking benefits, the 72-hour cooling-off wishlist mock card, a monthly budget / savings mock card), each with an uppercase eyebrow label, headline and body copy.
Bottom: a full-width yellow pill button "Bắt đầu trải nghiệm" and a small privacy note "Dữ liệu an toàn • Không phán xét chi tiêu".

Entry: `prm393_lab03/lib/screens/onboarding_screen.dart`

Dependencies:

- `app/routes.dart` (route table; imports every screen, not expanded)
- `theme/app_colors.dart`
- `widgets/why_i_buy_logo.dart`
- logic: `viewmodels/auth_viewmodel.dart`

## /home, shell tab 0 (HomeScreen)

Tab 0 of `MainNavigationScreen`. AppBar with back chevron, `WhyIBuyLogo` + "Trang chủ" and `AppHeaderActions` (notifications, wishlist, profile). Scroll body: greeting, the "TỔNG QUAN THÁNG" summary card (month picker, total spent, top motive, monthly budget progress), the "Danh sách mong muốn" entry card, the "Trước khi mua" section with "Trước khi mua" and "Chụp để tìm" buttons, and the "Khoản mua gần đây" list (motive-coloured rows, "Xem tất cả").
A full-width yellow pill FAB "Ghi khoản mua" floats at the bottom centre.

Entry: `prm393_lab03/lib/screens/home_screen.dart`

Dependencies:

- `app/routes.dart` (route table; imports every screen, not expanded)
- `core/formatters/date_format.dart`
- `core/formatters/money_format.dart`
- `theme/app_colors.dart`
- `theme/app_dimens.dart`
- `theme/motive_colors.dart`
- `widgets/app_header_actions.dart`
  - `app/app.dart` (app root / navigator key, not expanded)
- `widgets/month_picker_sheet.dart`
- `widgets/why_i_buy_logo.dart`
- logic: `viewmodels/budget_viewmodel.dart`, `viewmodels/purchase_viewmodel.dart`, `viewmodels/settings_viewmodel.dart`, `viewmodels/wishlist_viewmodel.dart`, `models/buying_motive.dart`, `models/purchase_item.dart`

## /wishlist/add, /wishlist/edit (AddItemScreen)

Form screen titled "Thêm món cân nhắc" / "Sửa thông tin món". Shows a Shopee metadata loading banner and a product preview card (image, Shopee tag, shop name) when a link was shared, then `AppTextField`s for title, URL and shop, an `AmountField` for the expected price (new items only), a `DuplicateHint` under the title, and a budget-group `AppDropdownField` with `BudgetGroupSuggestion`.
Then a 1-5 star "Mức ưu tiên" row, a `Wrap` of 8 `MotiveChip`s for "Tại sao bạn muốn mua món này?", and the "Lưu vào Wishlist" / "Lưu thay đổi" `AppButton`.

Entry: `prm393_lab03/lib/screens/add_item_screen.dart`

Dependencies:

- `core/formatters/money_format.dart`
- `theme/app_colors.dart`
- `theme/app_dimens.dart`
- `theme/app_text_styles.dart`
- `widgets/amount_field.dart`
- `widgets/app_button.dart`
- `widgets/app_dropdown_field.dart`
- `widgets/app_text_field.dart`
- `widgets/item_suggestions.dart`
  - `core/formatters/date_format.dart`
  - `widgets/insight_source_chip.dart`
- `widgets/motive_chip.dart`
- logic: `viewmodels/budget_viewmodel.dart`, `viewmodels/item_suggestion_viewmodel.dart`, `viewmodels/wishlist_viewmodel.dart`, `models/budget_group.dart`, `models/buying_motive.dart`, `models/item_suggestion.dart`, `models/wishlist_item.dart`, `services/analytics_events.dart`, `services/product_metadata_service.dart`, `core/constants/app_constants.dart`, `core/validators/validators.dart`

## /wishlist (WishlistScreen)

AppBar "Smart Wishlist" with "Lịch sale" and "Thêm món" actions. Under it: a search `AppTextField` with clear button, a horizontal row of `MotiveChip` filters, status filter chips ("Tất cả", "Cần xem lại (n)", one per status) and the `BuyIntentSection` ("Định mua từ máy tính").
Body is a `ListView` of `WishlistCard`s with a "Xem thêm n món" expander, switching to `LoadingView` / `EmptyView` / `ErrorView` from the view model's `UiState`.

Entry: `prm393_lab03/lib/screens/wishlist_screen.dart`

Dependencies:

- `app/routes.dart` (route table; imports every screen, not expanded)
- `theme/app_colors.dart`
- `theme/app_dimens.dart`
- `theme/app_text_styles.dart`
- `widgets/app_text_field.dart`
- `widgets/buy_intent_section.dart`
- `widgets/motive_chip.dart`
- `widgets/states/empty_view.dart`
- `widgets/states/error_view.dart`
- `widgets/states/loading_view.dart`
- `widgets/wishlist_card.dart`
  - `core/formatters/date_format.dart`
  - `core/formatters/money_format.dart`
  - `widgets/demo_data_badge.dart`
  - `widgets/motive_chip.dart`
  - `widgets/product_image.dart`
- logic: `viewmodels/wishlist_viewmodel.dart`, `models/buying_motive.dart`, `models/purchase_item.dart`, `models/ui_state.dart`, `models/wishlist_item.dart`, `models/wishlist_status.dart`

## /wishlist/detail (ItemDetailScreen)

AppBar "Chi tiết & Quyết định" with edit and delete actions. A header card shows `ProductImage`, title, variant, `ShopeeRatingLine`, big price with "Cập nhật giá", and a `Wrap` of `MotiveChip`, `DemoDataBadge`, shop pill, extension chip and saved date. Then `PriceHistoryPanel` (chart + recorded prices + shared prices), `SameProductCard`, a shop price comparison section and a cooling-off countdown box.
Bottom half: `DuplicateHint`, the "Thẻ Quyết Định (Decision Card)" heading with `DecisionCardPanel`, review-date info, and three equal secondary `AppButton`s "Mua" / "Chờ" / "Bỏ qua" (or "Cân nhắc lại" when skipped).

Entry: `prm393_lab03/lib/screens/item_detail_screen.dart`

Dependencies:

- `app/routes.dart` (route table; imports every screen, not expanded)
- `core/formatters/date_format.dart`
- `core/formatters/money_format.dart`
- `theme/app_colors.dart`
- `theme/app_dimens.dart`
- `theme/app_text_styles.dart`
- `widgets/app_button.dart`
- `widgets/confirm_dialog.dart`
- `widgets/decision_card_panel.dart`
  - `widgets/insight_source_chip.dart`
- `widgets/demo_data_badge.dart`
- `widgets/item_suggestions.dart`
  - `widgets/insight_source_chip.dart`
- `widgets/motive_chip.dart`
- `widgets/price_history_panel.dart`
  - `widgets/price_history_chart.dart`
    - `widgets/demo_data_badge.dart`
  - `widgets/price_history_entry_card.dart`
    - `widgets/demo_data_badge.dart`
    - `widgets/price_history_chart.dart` (dup)
  - `widgets/shared_price_section.dart`
- `widgets/price_update_sheet.dart`
  - `widgets/amount_field.dart`
  - `widgets/app_bottom_sheet.dart`
  - `widgets/app_button.dart`
- `widgets/product_image.dart`
- `widgets/review_date_sheet.dart`
  - `widgets/app_bottom_sheet.dart`
- `widgets/same_product_card.dart`
  - `core/formatters/rating_format.dart`
  - `widgets/demo_data_badge.dart`
  - `widgets/section_card.dart`
  - `widgets/undo_snack_bar.dart`
- `widgets/shopee_rating_line.dart`
- `widgets/undo_snack_bar.dart`
- `widgets/wishlist_card.dart`
  - `widgets/demo_data_badge.dart`
  - `widgets/motive_chip.dart`
  - `widgets/product_image.dart`
- logic: `viewmodels/decision_support_viewmodel.dart`, `viewmodels/item_suggestion_viewmodel.dart`, `viewmodels/own_price_view.dart`, `viewmodels/price_history_viewmodel.dart`, `viewmodels/same_product_viewmodel.dart`, `viewmodels/shared_price_viewmodel.dart`, `viewmodels/wishlist_viewmodel.dart`, `models/budget_group.dart`, `models/buying_motive.dart`, `models/daily_price.dart`, `models/decision_rules.dart`, `models/item_suggestion.dart`, `models/price_history_contribution.dart`, `models/price_insights.dart`, `models/price_snapshot.dart`, `models/purchase_item.dart`, `models/sale_event.dart`, `models/same_product.dart`, `models/shared_price.dart`, `models/shopee_link.dart`, `models/ui_state.dart`, `models/wishlist_item.dart`, `models/wishlist_status.dart`, `services/analytics_events.dart`, `services/price_history_service.dart`, `core/constants/app_constants.dart`, `core/validators/validators.dart`

## /before-buy (PrePurchaseScreen)

Four-step questionnaire (item, motive, sale, usage) with an AppBar title that changes per step and a back chevron that steps backwards. Each step has a `_StepHeader` ("Bước x trên y" + heading) and `_Question` blocks answered through `_OptionGrid` / `_OptionList` tiles; step 1 uses `AppTextField` + `AmountField`.
A pinned bottom `AppButton` reads "Tiếp tục", then "Xem nhận định" on the last step (pushes `/before-buy/result`).

Entry: `prm393_lab03/lib/screens/pre_purchase_screen.dart`

Dependencies:

- `app/routes.dart` (route table; imports every screen, not expanded)
- `core/formatters/money_format.dart`
- `theme/app_colors.dart`
- `theme/app_dimens.dart`
- `theme/app_text_styles.dart`
- `widgets/amount_field.dart`
- `widgets/app_button.dart`
- `widgets/app_text_field.dart`
- logic: `models/pre_purchase_check.dart`, `core/constants/app_constants.dart`, `core/validators/validators.dart`

## /purchase/record (RecordPurchaseScreen)

Two-step form ("Ghi khoản mua" / "Chỉnh sửa khoản mua"), max width 640, with a "Bước 1/2" / "Bước 2/2" label. Step 1: `AmountField` for the amount paid, +20k/+50k/+100k `ActionChip`s, title field, budget-group `AppDropdownField` with `BudgetGroupSuggestion`, a date-time `OutlinedButton` and a discount-code checkbox.
Step 2: yellow summary box, a two-column grid of motive `OutlinedButton`s (selected = primary container), and a note field. A pinned `AppButton` reads "Tiếp tục" then "Lưu khoản mua"; an AppBar help icon explains motives.

Entry: `prm393_lab03/lib/screens/record_purchase_screen.dart`

Dependencies:

- `app/routes.dart` (route table; imports every screen, not expanded)
- `core/formatters/date_format.dart`
- `core/formatters/money_format.dart`
- `theme/app_colors.dart`
- `theme/app_dimens.dart`
- `theme/app_text_styles.dart`
- `widgets/amount_field.dart`
- `widgets/app_button.dart`
- `widgets/app_dropdown_field.dart`
- `widgets/item_suggestions.dart`
  - `widgets/insight_source_chip.dart`
- logic: `viewmodels/auth_viewmodel.dart`, `viewmodels/budget_viewmodel.dart`, `viewmodels/item_suggestion_viewmodel.dart`, `viewmodels/purchase_viewmodel.dart`, `viewmodels/settings_viewmodel.dart`, `models/budget_group.dart`, `models/buying_motive.dart`, `models/item_suggestion.dart`, `models/purchase_item.dart`, `models/wishlist_item.dart`, `services/analytics_events.dart`, `core/constants/app_constants.dart`, `core/validators/validators.dart`

## /budget (BudgetScreen)

AppBar "Ngân sách theo nhóm" with a help icon. Body (guarded by `stateView`) has a month selector, then either an empty state or the "Tổng ngân sách tháng" card (status pill "Trong hạn mức" / "Đã vượt mốc", rounded `LinearProgressIndicator`, remaining/exceeded note).
Then "CÁC NHÓM NGÂN SÁCH" category cards (icon, progress bar, "Vì sao con số này?" dialog, unlimited-group card), a footnote and a full-width yellow pill "Cài đặt mức ngân sách" button that opens `BudgetSettingSheet`.

Entry: `prm393_lab03/lib/screens/budget_screen.dart`

Dependencies:

- `core/formatters/date_format.dart`
- `core/formatters/money_format.dart`
- `theme/app_colors.dart`
- `widgets/budget_setting_sheet.dart`
  - `theme/app_dimens.dart`
  - `theme/app_text_styles.dart`
  - `widgets/amount_field.dart`
  - `widgets/app_bottom_sheet.dart`
  - `widgets/app_button.dart`
- `widgets/month_picker_sheet.dart`
- `widgets/states/state_view.dart`
  - `widgets/states/error_view.dart`
  - `widgets/states/loading_view.dart`
- logic: `viewmodels/budget_viewmodel.dart`, `viewmodels/purchase_viewmodel.dart`, `models/available_budget.dart`, `models/ui_state.dart`, `core/constants/app_constants.dart`, `core/validators/validators.dart`

## /insights, shell tab 3 (InsightsScreen)

Tab 3 "Góc nhìn" of `MainNavigationScreen` (also pushed as `/insights`). AppBar mirrors Home (logo + title + `AppHeaderActions`). A pull-to-refresh `ListView` holds the month selector, an AI status card ("Dùng AI" switch, status text, retry, privacy note) and either an `EmptyView` or one `_InsightCardView` per insight (coloured icon badge, title, `InsightSourceChip` AI/template, body).
Ends with an outlined pill button "Xem chiêm nghiệm tháng" to `/reflection`.

Entry: `prm393_lab03/lib/screens/insights_screen.dart`

Dependencies:

- `app/routes.dart` (route table; imports every screen, not expanded)
- `core/formatters/date_format.dart`
- `theme/app_colors.dart`
- `widgets/app_header_actions.dart`
  - `app/app.dart` (app root / navigator key, not expanded)
- `widgets/insight_source_chip.dart`
- `widgets/month_picker_sheet.dart`
- `widgets/states/empty_view.dart`
  - `theme/app_dimens.dart`
  - `theme/app_text_styles.dart`
- `widgets/states/state_view.dart`
  - `widgets/states/error_view.dart`
  - `widgets/states/loading_view.dart`
- `widgets/why_i_buy_logo.dart`
- logic: `viewmodels/insights_viewmodel.dart`, `viewmodels/purchase_viewmodel.dart`, `viewmodels/settings_viewmodel.dart`, `viewmodels/wishlist_viewmodel.dart`, `models/spending_insight.dart`, `models/ui_state.dart`

## Other UI surfaces (not traced)

- Web admin `prm393_flutter_admin/` (Flutter web): screens in `lib/screens/` (`admin_shell.dart`,
  `sign_in_screen.dart`, `dashboard_screen.dart`, `review_queue_screen.dart`, `users_screen.dart`,
  `sale_events_screen.dart`, `announcements_screen.dart`, `ai_assistant_screen.dart`) and widgets in
  `lib/widgets/` (`admin_page.dart`, `stat_card.dart`, `status_badge.dart`, `brand_mark.dart`, dialogs).
  Shared theme and widgets come from the package `packages/core/lib/src/` (`theme/`, `widgets/`).
- `presentation_web/`: a fresh Vite scaffold for a scroll-driven presentation site (three, gsap, Be Vietnam Pro).
  Its `src/` subfolders (`data`, `engine`, `screens`, `styles`, `three`, `ui`) are empty, so it has no pages yet.
