# Extractable Components

Catalog of reusable UI pieces in the Flutter mobile app `prm393_lab03/` (Material 3, Be Vietnam Pro, primary `#FFDE02`, light scaffold `#F8FAFC`). Tokens referenced below live in `prm393_lab03/lib/theme/` (`AppColors`, `AppDimens`, `AppTextStyles`). Key dimensions: `AppDimens.radiusLarge` = 16, `AppDimens.radiusXLarge` = 24, `AppDimens.borderPill` = fully rounded, `AppDimens.minTouchTarget` = 48.

"Extractable props" lists only per-page state a design would vary (labels, selection, amounts). "Hardcoded elements" is what stays fixed inside the component and should be drawn identically everywhere.

## Layout Components

### BottomNav
- Source: `prm393_lab03/lib/screens/main_navigation_screen.dart` (`bottomNavigationBar` container + `_buildNavItem`)
- Category: layout
- Description: Custom 5-tab bottom bar of the app shell (Trang chủ / Lịch sử / Mô hình / Góc nhìn / Cá nhân); not the Material `NavigationBar` widget.
- Extractable props:
  - `activeTab`: 0 to 4 (Trang chủ, Lịch sử, Mô hình, Góc nhìn, Cá nhân)
- Hardcoded elements:
  - 60 px high row inside `SafeArea`, surface background, 1 px top border in `theme.dividerColor`
  - 5 equal-width `InkWell` items: 24 px icon, 3 px gap, 11 px label
  - Tab icons: `home_outlined`/`home_rounded`, `format_list_bulleted_rounded`, `bar_chart_rounded`, `lightbulb_outline_rounded`/`lightbulb_rounded`, `person_outline_rounded`/`person_rounded`
  - Active: filled icon, label w700, colour `AppColors.onPrimary` (light) or `AppColors.primary` (dark); inactive: outlined icon, label w500, `AppColors.navInactive` (light) or `#64748B` (dark)
  - No active pill or indicator, no badges

### TabAppBar
- Source: `prm393_lab03/lib/screens/history_screen.dart` (same `AppBar` block repeated in `home_screen.dart`, `patterns_screen.dart`, `insights_screen.dart`)
- Category: layout
- Description: Top bar of every shell tab: back chevron, Why I Buy logo, screen title, `HeaderActions` on the right.
- Extractable props:
  - `title`: screen name, e.g. "Lịch sử", "Mô hình", "Góc nhìn"
- Hardcoded elements:
  - Surface background (`AppColors.darkSurface` in dark), elevation 0, no scroll tint, `titleSpacing: 0`, `leadingWidth: 42`
  - Leading `chevron_left_rounded` icon at 30 px, tooltip "Trang chủ"
  - `WhyIBuyLogo` at 26 px in `AppColors.onPrimary`, 4 px gap, title text 18 px w800 in `onSurface`
  - Trailing `HeaderActions`

### HeaderActions
- Source: `prm393_lab03/lib/widgets/app_header_actions.dart`
- Category: layout
- Description: Right-hand AppBar cluster: notification bell, wishlist bookmark (both with count badges) and a yellow profile avatar.
- Extractable props:
  - `notificationCount`: number of notifications (0 hides the badge and shows the outlined bell)
  - `wishlistCount`: wishlist items being considered (0 hides the badge)
- Hardcoded elements:
  - `notifications_none_rounded` / `notifications_rounded` and `bookmark_outline_rounded` `IconButton`s at 24 px; colour `AppColors.onPrimary` (light) or `AppColors.primary` (dark)
  - Count badge: red circle (`AppColors.error`), 4 px padding, white 10 px bold number, positioned 7 px from the top-right
  - 34 px circular avatar in `AppColors.primary` with a 20 px `Icons.person` in `AppColors.onPrimary`, 12 px right margin
  - Bell opens a notifications sheet: "Thông báo" title 20 px w800, up to 5 `ListTile`s with a `primaryContainer` `CircleAvatar`, empty text "Chưa có thông báo mới.", optional "Bật thông báo" text button

### BottomSheet
- Source: `prm393_lab03/lib/widgets/app_bottom_sheet.dart` (`AppBottomSheet.show`)
- Category: layout
- Description: Standard modal sheet with drag handle, title and scrollable content that moves above the keyboard; used by the budget, price update, review date and shopping profile sheets.
- Extractable props:
  - `title`: sheet heading, e.g. "Cập nhật giá"
- Hardcoded elements:
  - `AppColors.surface` background, 24 px top corners (`AppDimens.radiusXLarge`), safe-area aware, scroll-controlled
  - Drag handle: 40 x 4 px pill in `AppColors.outline`, 12 px from the top
  - Title in `AppTextStyles.titleLarge` with 16 px side padding (16 top, 8 bottom)
  - Content padding 16 / 8 / 16 / 24 inside a `SingleChildScrollView`

## Basic Components

### AppButton
- Source: `prm393_lab03/lib/widgets/app_button.dart` (token-aware copy for the admin: `packages/core/lib/src/widgets/app_button.dart`)
- Category: basic
- Description: Full-width pill button with three variants, optional leading icon and a loading spinner.
- Extractable props:
  - `label`: button text (wraps to at most 2 lines)
  - `variant`: `primary` | `secondary` | `danger`
  - `isLoading`: shows the spinner instead of the label
  - `disabled`: renders at 50% opacity
  - `icon`: optional leading icon
- Variants:

  | Variant | Background | Foreground | Border |
  |---|---|---|---|
  | `primary` | `AppColors.primary` (yellow `#FFDE02`) | `AppColors.onPrimary` | none |
  | `secondary` | `AppColors.surface` | `AppColors.textPrimary` | 1.5 px `AppColors.outline` |
  | `danger` | `AppColors.error` | `AppColors.textOnDark` | none |

- Hardcoded elements:
  - Pill shape (`AppDimens.borderPill`), elevation 0, min height 48, full width unless a width is given
  - Padding 12 horizontal / 8 vertical, `AppTextStyles.labelLarge`, centred text
  - Icon 20 px with an 8 px gap; spinner 22 px, stroke 2.5, in the foreground colour

### SectionCard
- Source: `prm393_lab03/lib/widgets/section_card.dart` (identical copy in `packages/core/lib/src/widgets/section_card.dart`)
- Category: basic
- Description: Bordered content card with a title row (optional icon and trailing action), a divider, then arbitrary children.
- Extractable props:
  - `title`: section heading
  - `icon`: optional leading icon of the heading
  - `action`: optional trailing widget (e.g. a text button)
- Hardcoded elements:
  - Full width, 16 px padding, 16 px corners (`AppDimens.borderLarge`), surface fill, 1 px border in `theme.dividerColor`
  - Heading icon 20 px in `AppColors.onPrimary` (light) or `AppColors.primary` (dark), 8 px gap, title in `AppTextStyles.titleMedium`
  - 12 px gap, `Divider`, 12 px gap before the children

### MotiveChip
- Source: `prm393_lab03/lib/widgets/motive_chip.dart`
- Category: basic
- Description: Pill chip for one of the 8 buying motives, used as a filter/selector and as a display tag on cards.
- Extractable props:
  - `motive`: one of Nhu cầu, Mong muốn, Khuyến mãi, Cảm xúc, Ảnh hưởng MXH, Tiện lợi, Quảng cáo, Khác
  - `selected`: filled vs tinted state
  - `compact`: smaller display-only size
- Hardcoded elements:
  - Per-motive icon and colour pair from `MotiveColors` (`prm393_lab03/lib/theme/motive_colors.dart`): unselected = motive background tint, motive-coloured icon/text, 1.2 px border at 30% motive colour; selected = solid motive colour, white text (`AppColors.textOnDark`), full-opacity border
  - Pill shape, 200 ms colour animation, icon 18 px (16 compact) with a 6 px gap
  - Padding 16 x 8 (12 x 4 compact); `labelLarge` (`labelMedium` compact), w600 selected / w500 unselected
  - Min height 48 when tappable or regular, 32 when compact display-only

### PriceChip
- Source: `prm393_lab03/lib/widgets/price_chip.dart`
- Category: basic
- Description: Small pill showing an item's latest price, or "Cần giá" when the price is unknown.
- Extractable props:
  - `amount`: price in VND, or null for the "Cần giá" state
- Hardcoded elements:
  - Pill, padding 8 x 4, 1 px `AppColors.border`
  - Known price: `AppColors.primaryContainer` fill, `sell_rounded` 14 px icon and text in `AppColors.onPrimary`, VND formatting
  - Missing price: `AppColors.surfaceVariant` fill, `sell_outlined` icon and text in `AppColors.accentNeutral`
  - Text `AppTextStyles.labelMedium` w600, 4 px icon gap

### WishlistCard
- Source: `prm393_lab03/lib/widgets/wishlist_card.dart`
- Category: basic
- Description: Tappable wishlist item card: optional thumbnail, title, price, optional variant line and a row of motive/status badges.
- Extractable props:
  - `title`: item name (max 2 lines)
  - `price`: latest price in VND (muted style when unknown)
  - `motive`: the item's buying motive (rendered as a compact `MotiveChip`)
  - `status`: cooling-off countdown ("... hoãn"), "Xem lại dd/MM", "Đến hẹn xem lại", or the item status label
  - `variantLabel`: optional "Phân loại: ..." line
  - `imageUrl`: optional product thumbnail
  - `isDemo`, `isFromExtension`: show the demo badge and the "Từ máy tính" badge
- Hardcoded elements:
  - Flat `Card`, 16 px corners, 1 px `AppColors.divider` border, 12 px bottom margin, 16 px padding
  - Title `AppTextStyles.titleMedium`; price `titleMedium` w700 in `AppColors.onPrimary` (or `labelMedium` `textSecondary` when missing)
  - Badges in a `Wrap` (12 px spacing, 8 px run spacing): pill, 8 x 4 padding, 14 px icon, `labelMedium`, background = badge colour at 12% opacity
  - Cooling-off badge uses `AppColors.motiveEmotionBg` / `AppColors.motiveEmotion` with `timer_outlined`

### BudgetBar
- Source: `prm393_lab03/lib/widgets/budget_bar.dart`
- Category: basic
- Description: Budget meter with a pill progress bar, "spent / limit" text and a neutral over-limit note (never red).
- Extractable props:
  - `spent`: amount spent in VND
  - `limit`: budget limit in VND
  - `label`: optional group name, e.g. "Công nghệ" (screen-reader only)
- Hardcoded elements:
  - 8 px high pill `LinearProgressIndicator`, track `AppColors.surfaceVariant`, fill `AppColors.primary` (switches to `AppColors.accentNeutral` when over the limit)
  - Text "{spent} / {limit}" in `labelMedium` `textPrimary`, 6 px below the bar
  - Over limit: extra line "Đã vượt {x} so với mốc bạn đặt. App không chặn mua." in `labelMedium` `accentNeutral`

### AppTextField
- Source: `prm393_lab03/lib/widgets/app_text_field.dart` (token-aware copy: `packages/core/lib/src/widgets/app_text_field.dart`)
- Category: basic
- Description: Labelled text input wrapping `TextFormField`; box styling comes from the theme's `InputDecorationTheme`.
- Extractable props:
  - `label`: optional label above the field
  - `hint`: placeholder text
  - `value`: current text
  - `obscureText`: password-style input
  - `prefixIcon`: optional leading icon
  - `errorText`: validation message from the form
- Hardcoded elements:
  - Label `AppTextStyles.labelLarge`, 8 px gap to the field
  - Input text `AppTextStyles.bodyLarge`
  - Prefix icon 20 px in `AppColors.textSecondary`
  - Fill, border radius and focus colours from `AppTheme` (`prm393_lab03/lib/theme/app_theme.dart`)

### EmptyView
- Source: `prm393_lab03/lib/widgets/states/empty_view.dart` (siblings: `loading_view.dart`, `error_view.dart`; shared copies in `packages/core/lib/src/widgets/states/`)
- Category: basic
- Description: Centred empty state with a circular icon, title, optional subtitle and optional action button.
- Extractable props:
  - `title`: empty-state headline
  - `subtitle`: optional explanation
  - `icon`: illustration icon (default `inbox_outlined`)
  - `actionLabel`: optional button text
- Hardcoded elements:
  - Centred column with 32 px padding
  - 72 px circle in `AppColors.surfaceVariant` with a 36 px icon in `AppColors.textSecondary`
  - 20 px gap, title `AppTextStyles.titleMedium` centred; 8 px gap, subtitle `AppTextStyles.bodyMedium` centred
  - 24 px gap, theme `ElevatedButton` for the action

## Web admin (secondary)

`prm393_flutter_admin/` reuses `AppButton`, `AppTextField`, `SectionCard`, `ConfirmDialog` and the state views from `packages/core/lib/src/widgets/` (the button and text field read colours through `AppTokens.of(context)` so they follow the admin's light/dark mode). Admin-only pieces in `prm393_flutter_admin/lib/widgets/`: `admin_page.dart` (page scaffold), `brand_mark.dart`, `stat_card.dart`, `status_badge.dart`, `message_box.dart`, plus dialogs (`reason_dialog.dart`, `sale_event_form_dialog.dart`, `user_message_dialog.dart`). Its shell navigation (bottom `NavigationBar` / `NavigationRail` / 264 px sidebar) is described in `layouts.md`.
