# Components: shared UI primitives (mobile app)

Reusable widgets of `prm393_lab03/lib/widgets/` used across the screens of "Why I Buy". All of them style themselves only with the tokens in `prm393_lab03/lib/theme/` (`AppColors`, `AppDimens`, `AppTextStyles`; see `theme.md`). UI copy is Vietnamese.

Conventions shared by these widgets:

- Shape language: pills (`AppDimens.borderPill`) for buttons, chips and badges; 16 radius (`borderLarge`) for cards; 24 (`radiusXLarge`) for dialogs and bottom-sheet tops.
- Flat surfaces: elevation 0 with a 1px `AppColors.divider` border instead of shadows.
- Accessibility: tappable things get `minHeight: AppDimens.minTouchTarget` (48) and a `Semantics` label in Vietnamese.
- Most primitives use the light `AppColors` constants directly (`AppButton`, `PriceChip`, `BudgetBar`, `WishlistCard`, `AppBottomSheet`, the state views); `SectionCard` is the one that reads `Theme.of(context)` and adapts to dark mode.
- Money is an `int` of VND formatted by `formatVnd` (`lib/core/formatters/money_format.dart`) as `389.000 ₫`; a missing price is `null`, never 0.
- Dialogs, sheets and snack bars are exposed as static helpers (`ConfirmDialog.show`, `AppBottomSheet.show`, `showUndoSnackBar`), not widgets.

| Component | File | Kind |
|---|---|---|
| `AppButton` | `lib/widgets/app_button.dart` | button (primary / secondary / danger) |
| `AppTextField` | `lib/widgets/app_text_field.dart` | labelled text input |
| `SectionCard` | `lib/widgets/section_card.dart` | titled card container |
| `MotiveChip` | `lib/widgets/motive_chip.dart` | buying-motive chip |
| `PriceChip` | `lib/widgets/price_chip.dart` | price pill |
| `MoneyText` | `lib/widgets/money_text.dart` | formatted VND text |
| `BudgetBar` | `lib/widgets/budget_bar.dart` | budget meter |
| `WishlistCard` | `lib/widgets/wishlist_card.dart` | wishlist list item |
| `ProductImage` | `lib/widgets/product_image.dart` | network product thumbnail |
| `WhyIBuyLogo` | `lib/widgets/why_i_buy_logo.dart` | brand mark |
| `ConfirmDialog` | `lib/widgets/confirm_dialog.dart` | yes/no dialog helper |
| `AppBottomSheet` | `lib/widgets/app_bottom_sheet.dart` | modal sheet helper |
| `showUndoSnackBar` | `lib/widgets/undo_snack_bar.dart` | undo snack bar helper |
| `InsightSourceChip` | `lib/widgets/insight_source_chip.dart` | AI / template source tag |
| `EmptyView` | `lib/widgets/states/empty_view.dart` | empty state |
| `LoadingView` | `lib/widgets/states/loading_view.dart` | loading state |
| `ErrorView` | `lib/widgets/states/error_view.dart` | error state with retry |

---

## Buttons and inputs

### `AppButton` (`prm393_lab03/lib/widgets/app_button.dart`)

Full-width pill button with three variants, optional leading icon and a loading spinner; never shorter than 48.

Key props: `title` (required), `onPressed` (required, null disables), `variant` (`AppButtonVariant.primary` yellow `#FFDE02` / `secondary` white with 1.5px outline / `danger` red), `isLoading`, `icon`, `width` (default full width). Disabled = colours at 50% alpha.

```dart
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, danger }

/// Reusable App Button conforming to >=48dp touch target accessibility rule
class AppButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const AppButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;
    BorderSide? side;

    switch (variant) {
      case AppButtonVariant.primary:
        bgColor = AppColors.primary;
        fgColor = AppColors.onPrimary;
        side = BorderSide.none;
        break;
      case AppButtonVariant.secondary:
        bgColor = AppColors.surface;
        fgColor = AppColors.textPrimary;
        side = const BorderSide(color: AppColors.outline, width: 1.5);
        break;
      case AppButtonVariant.danger:
        bgColor = AppColors.error;
        fgColor = AppColors.textOnDark;
        side = BorderSide.none;
        break;
    }

    final isInteractive = !isLoading && onPressed != null;

    return Semantics(
      button: true,
      enabled: isInteractive,
      label: title,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: AppDimens.minTouchTarget,
          minWidth: width ?? double.infinity,
        ),
        child: SizedBox(
          width: width,
          child: ElevatedButton(
            onPressed: isInteractive ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              disabledBackgroundColor: bgColor.withValues(alpha: 0.5),
              disabledForegroundColor: fgColor.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: AppDimens.borderPill,
                side: side,
              ),
              elevation: AppDimens.elevationNone,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space12,
                vertical: AppDimens.space8,
              ),
            ),
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 20, color: fgColor),
                        const SizedBox(width: AppDimens.space8),
                      ],
                      Flexible(
                        child: Text(
                          title,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: fgColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
```

### `AppTextField` (`prm393_lab03/lib/widgets/app_text_field.dart`)

Optional `labelLarge` label above a `TextFormField` that takes its look (filled white, radius 12, divider border, dark focus ring) from the theme's `inputDecorationTheme`.

Key props: `label`, `hint`, `controller`, `onChanged`, `validator`, `keyboardType`, `obscureText`, `prefixIcon` (20px, `textSecondary`), `suffixIcon`, `maxLines`, `readOnly`, `onTap`.

```dart
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// Reusable App Text Field conforming to Figma specs
class AppTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextInputType keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.onChanged,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTextStyles.labelLarge),
          const SizedBox(height: AppDimens.space8),
        ],
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.textSecondary, size: 20)
                : null,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
```

---

## Containers

### `SectionCard` (`prm393_lab03/lib/widgets/section_card.dart`)

Surface card (padding 16, radius 16, 1px divider border) with a title row (optional icon, trailing action), a divider, then the children. Theme-aware: icon is `onPrimary` in light, `primary` yellow in dark.

Key props: `title` (required), `icon`, `action` (trailing widget, e.g. a `TextButton`), `children` (required).

```dart
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// Card with a title row (optional icon and trailing [action]), a divider and content
class SectionCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? action;
  final List<Widget> children;

  const SectionCard({
    super.key,
    required this.title,
    this.icon,
    this.action,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppDimens.borderLarge,
        border: Border.all(color: theme.dividerColor),
      ),
      // Own Material so ListTile ink in [children] shows above the card's colour
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: isDark ? AppColors.primary : AppColors.onPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: AppDimens.space8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                ?action,
              ],
            ),
            const SizedBox(height: AppDimens.space12),
            Divider(color: theme.dividerColor),
            const SizedBox(height: AppDimens.space12),
            ...children,
          ],
        ),
      ),
    );
  }
}
```

### `WishlistCard` (`prm393_lab03/lib/widgets/wishlist_card.dart`)

Tappable card for one wishlist item: optional product thumbnail, 2-line title, price at the right (bold `onPrimary`, or grey "Chưa có giá"), optional variant line, then a wrap of badges: motive chip, demo badge, "Từ máy tính" (saved from the Chrome extension) and a status badge (cooldown timer in the emotion purple, review date, or the item status colour at 12% alpha).

Key props: `item` (`WishlistItem`, required), `onTap` (required). Static `WishlistCard.fromExtensionChip()` is reused in `item_detail_screen.dart`.

```dart
import 'package:flutter/material.dart';

import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../models/wishlist_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import 'demo_data_badge.dart';
import 'motive_chip.dart';
import 'product_image.dart';

/// Reusable Wishlist Item Card conforming to Figma specs
class WishlistCard extends StatelessWidget {
  final WishlistItem item;
  final VoidCallback onTap;

  const WishlistCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          'Món ${item.title}, giá ${formatVnd(item.latestPriceVnd)}, động cơ ${item.displayMotive.label}',
      child: Card(
        margin: const EdgeInsets.only(bottom: AppDimens.space12),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: AppDimens.borderLarge,
          side: BorderSide(color: AppColors.divider, width: 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppDimens.borderLarge,
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ProductImage.canShow(item.imageUrl)) ...[
                      ProductImage(url: item.imageUrl),
                      const SizedBox(width: AppDimens.space12),
                    ],
                    Expanded(
                      child: Text(
                        item.title,
                        style: AppTextStyles.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppDimens.space12),
                    Text(
                      formatVnd(item.latestPriceVnd),
                      style: item.hasPrice
                          ? AppTextStyles.titleMedium.copyWith(
                              color: AppColors.onPrimary,
                              fontWeight: FontWeight.w700,
                            )
                          : AppTextStyles.labelMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                    ),
                  ],
                ),
                if (item.variantLabel != null) ...[
                  const SizedBox(height: AppDimens.space4),
                  Text(
                    'Phân loại: ${item.variantLabel}',
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppDimens.space12),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: AppDimens.space12,
                  runSpacing: AppDimens.space8,
                  children: [
                    MotiveChip(motive: item.displayMotive, isCompact: true),
                    if (item.isDemo) const DemoDataBadge(),
                    if (item.isFromExtension) fromExtensionChip(),
                    _buildStatusBadge(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (item.isInCooldown) {
      final timeText = '${item.remainingCooldownLabel} hoãn';

      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space8,
          vertical: AppDimens.space4,
        ),
        decoration: const BoxDecoration(
          color: AppColors.motiveEmotionBg,
          borderRadius: AppDimens.borderPill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.timer_outlined,
              size: 14,
              color: AppColors.motiveEmotion,
            ),
            const SizedBox(width: AppDimens.space4),
            Text(
              timeText,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.motiveEmotion,
              ),
            ),
          ],
        ),
      );
    }

    // "Chờ" keeps the status "Đang cân nhắc"; the review date is what the user needs to see
    if (item.isWaiting || item.isReviewDue) {
      return _badge(
        icon: item.isReviewDue
            ? Icons.notifications_active_outlined
            : Icons.event,
        text: item.isReviewDue
            ? 'Đến hẹn xem lại'
            : 'Xem lại ${formatDayMonth(item.reviewAt!)}',
      );
    }

    return _badge(
      icon: item.status.icon,
      text: item.status.label,
      color: item.status.color,
    );
  }

  /// "Từ máy tính": saved with the Chrome extension (saveChannel extension)
  static Widget fromExtensionChip() => _badge(
    icon: Icons.computer_rounded,
    text: 'Từ máy tính',
    color: AppColors.textSecondary,
  );

  static Widget _badge({
    required IconData icon,
    required String text,
    Color color = AppColors.accentNeutral,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space8,
        vertical: AppDimens.space4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppDimens.borderPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppDimens.space4),
          Text(text, style: AppTextStyles.labelMedium.copyWith(color: color)),
        ],
      ),
    );
  }
}
```

`DemoDataBadge` (`lib/widgets/demo_data_badge.dart`) is the small "Dữ liệu mẫu" pill shown next to every sample product, price or chart (`isDemo`) so it is never taken for real data.

---

## Chips, money and meters

### `MotiveChip` (`prm393_lab03/lib/widgets/motive_chip.dart`)

Pill chip for one of the 8 buying motives: motive icon + Vietnamese label in the motive colour on its pastel background with a 30% border; selected = solid motive colour with white text. Animates 200ms between states.

Key props: `motive` (`BuyingMotive`, required), `isSelected`, `onSelected` (makes it tappable, forces 48 height), `isCompact` (display-only 32 height, `labelMedium`, 16px icon).

```dart
import 'package:flutter/material.dart';

import '../models/buying_motive.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// Reusable Motive Chip for the 8 Buying Motives.
/// Tappable chips always get a 48dp touch target; [isCompact] only shrinks display-only chips.
class MotiveChip extends StatelessWidget {
  final BuyingMotive motive;
  final bool isSelected;
  final ValueChanged<BuyingMotive>? onSelected;
  final bool isCompact;

  const MotiveChip({
    super.key,
    required this.motive,
    this.isSelected = false,
    this.onSelected,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected ? motive.color : motive.backgroundColor;
    final fgColor = isSelected ? AppColors.textOnDark : motive.color;
    final isInteractive = onSelected != null;

    return Semantics(
      button: isInteractive,
      selected: isSelected,
      label: 'Động cơ: ${motive.label}',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: isInteractive || !isCompact
              ? AppDimens.minTouchTarget
              : 32,
        ),
        child: InkWell(
          onTap: onSelected != null ? () => onSelected!(motive) : null,
          borderRadius: AppDimens.borderPill,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? AppDimens.space12 : AppDimens.space16,
              vertical: isCompact ? AppDimens.space4 : AppDimens.space8,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: AppDimens.borderPill,
              border: Border.all(
                color: isSelected
                    ? motive.color
                    : motive.color.withValues(alpha: 0.3),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(motive.icon, size: isCompact ? 16 : 18, color: fgColor),
                const SizedBox(width: AppDimens.space6),
                Text(
                  motive.label,
                  style:
                      (isCompact
                              ? AppTextStyles.labelMedium
                              : AppTextStyles.labelLarge)
                          .copyWith(
                            color: fgColor,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

### `PriceChip` (`prm393_lab03/lib/widgets/price_chip.dart`)

Small pill with a tag icon showing the latest price on `primaryContainer` (`#FFFCE6`), or "Cần giá" on `surfaceVariant` in `accentNeutral` when the price is unknown.

Key props: `priceVnd` (`int?`, required).

```dart
import 'package:flutter/material.dart';

import '../core/formatters/money_format.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// Latest price of a wishlist item; "Cần giá" when the price is not known (null)
class PriceChip extends StatelessWidget {
  final int? priceVnd;

  const PriceChip({super.key, required this.priceVnd});

  @override
  Widget build(BuildContext context) {
    final price = priceVnd;
    final missing = price == null;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space8,
        vertical: AppDimens.space4,
      ),
      decoration: BoxDecoration(
        color: missing ? AppColors.surfaceVariant : AppColors.primaryContainer,
        borderRadius: AppDimens.borderPill,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            missing ? Icons.sell_outlined : Icons.sell_rounded,
            size: 14,
            color: missing ? AppColors.accentNeutral : AppColors.onPrimary,
          ),
          const SizedBox(width: AppDimens.space4),
          Text(
            missing ? 'Cần giá' : formatVnd(price),
            style: AppTextStyles.labelMedium.copyWith(
              color: missing ? AppColors.accentNeutral : AppColors.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
```

### `MoneyText` (`prm393_lab03/lib/widgets/money_text.dart`)

VND amount as text in three sizes with a spoken label ("... đồng"); `null` shows `emptyLabel` in `textSecondary`, never "0 ₫".

Key props: `amountVnd` (positional `int?`), `size` (`MoneyTextSize.small` = `labelLarge`, `medium` = `titleMedium` w700, `large` = `headlineLarge` w800), `color`, `emptyLabel` (default "Chưa có giá").

```dart
import 'package:flutter/material.dart';

import '../core/formatters/money_format.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum MoneyTextSize { small, medium, large }

/// int VND → "389.000 ₫"; null → [emptyLabel] ("Chưa có giá"), never "0 ₫"
class MoneyText extends StatelessWidget {
  final int? amountVnd;
  final MoneyTextSize size;
  final Color? color;
  final String emptyLabel;

  const MoneyText(
    this.amountVnd, {
    super.key,
    this.size = MoneyTextSize.medium,
    this.color,
    this.emptyLabel = 'Chưa có giá',
  });

  TextStyle get _style => switch (size) {
    MoneyTextSize.small => AppTextStyles.labelLarge,
    MoneyTextSize.medium => AppTextStyles.titleMedium.copyWith(
      fontWeight: FontWeight.w700,
    ),
    MoneyTextSize.large => AppTextStyles.headlineLarge.copyWith(
      fontWeight: FontWeight.w800,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final amount = amountVnd;
    return Semantics(
      label: amount == null
          ? emptyLabel
          : '${formatVnd(amount).replaceAll(' ₫', '')} đồng',
      excludeSemantics: true,
      child: Text(
        formatVnd(amount, empty: emptyLabel),
        style: _style.copyWith(
          color: color ?? (amount == null ? AppColors.textSecondary : null),
        ),
      ),
    );
  }
}
```

### `BudgetBar` (`prm393_lab03/lib/widgets/budget_bar.dart`)

8px pill progress bar (yellow fill on `surfaceVariant` track) with a "spent / limit" caption. Over the limit the fill turns `accentNeutral` (never red) and a note "Đã vượt ... App không chặn mua." is added.

Key props: `spentVnd` (required), `limitVnd` (required), `label` (group name for the screen-reader label).

```dart
import 'package:flutter/material.dart';

import '../core/formatters/money_format.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// Budget meter (handoff "Budget meter"): neutral colors; over the limit the bar stays
/// neutral and a line "Đã vượt …" is added — never red.
class BudgetBar extends StatelessWidget {
  final int spentVnd;
  final int limitVnd;

  /// Group name for the screen-reader label, e.g. "Công nghệ"
  final String? label;

  const BudgetBar({
    super.key,
    required this.spentVnd,
    required this.limitVnd,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final exceeded = limitVnd > 0 && spentVnd > limitVnd;
    final progress = limitVnd > 0 ? (spentVnd / limitVnd).clamp(0.0, 1.0) : 0.0;
    final remaining = limitVnd - spentVnd;
    final prefix = label == null ? '' : '$label: ';

    return Semantics(
      label:
          '$prefixđã chi ${formatVnd(spentVnd)} trên ${formatVnd(limitVnd)}, '
          '${exceeded ? 'đã vượt ${formatVnd(-remaining)}' : 'còn lại ${formatVnd(remaining)}'}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: AppDimens.borderPill,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceVariant,
              color: exceeded ? AppColors.accentNeutral : AppColors.primary,
            ),
          ),
          const SizedBox(height: AppDimens.space6),
          Text(
            '${formatVnd(spentVnd)} / ${formatVnd(limitVnd)}',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          if (exceeded) ...[
            const SizedBox(height: AppDimens.space2),
            Text(
              'Đã vượt ${formatVnd(-remaining)} so với mốc bạn đặt. App không chặn mua.',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.accentNeutral,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

### `InsightSourceChip` (`prm393_lab03/lib/widgets/insight_source_chip.dart`)

Tiny pill (11px w700) marking an insight sentence as AI-written ("AI", sparkle icon, amber `aiContainer`) or the built-in template ("Câu mẫu", notes icon, `surfaceVariant`).

Key props: `fromAi` (`bool`, required).

```dart
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Tells the user whether a sentence was written by AI or is the built-in template
class InsightSourceChip extends StatelessWidget {
  final bool fromAi;

  const InsightSourceChip({super.key, required this.fromAi});

  @override
  Widget build(BuildContext context) {
    final foreground = fromAi ? AppColors.onAiContainer : AppColors.textBody;
    return Semantics(
      label: fromAi ? 'Do AI viết' : 'Câu mẫu',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: fromAi ? AppColors.aiContainer : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              fromAi ? Icons.auto_awesome : Icons.notes_rounded,
              size: 12,
              color: foreground,
            ),
            const SizedBox(width: 4),
            Text(
              fromAi ? 'AI' : 'Câu mẫu',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Imagery and brand

### `ProductImage` (`prm393_lab03/lib/widgets/product_image.dart`)

Square rounded network thumbnail (Shopee CDN link saved by the Chrome extension). Renders nothing for a non-http(s) URL and a grey `surfaceVariant` placeholder icon while loading or on error.

Key props: `url` (required, `String?`), `size` (default 56), `borderRadius` (default `borderMedium`, 12). Static `ProductImage.canShow(url)` lets callers skip layout space.

```dart
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Product photo saved by the Chrome extension (`WishlistItem.imageUrl`, a Shopee CDN link).
/// Shows nothing when there is no usable http(s) link, and a quiet placeholder while
/// loading or when the image cannot be fetched (offline, link expired).
class ProductImage extends StatelessWidget {
  final String? url;
  final double size;
  final BorderRadius borderRadius;

  const ProductImage({
    super.key,
    required this.url,
    this.size = 56,
    this.borderRadius = AppDimens.borderMedium,
  });

  /// Only web links are shown; anything else (empty, data:, file paths) is ignored
  static bool canShow(String? url) {
    final uri = url == null ? null : Uri.tryParse(url.trim());
    return uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (!canShow(url)) return const SizedBox.shrink();
    final cacheSize = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.network(
        url!.trim(),
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: cacheSize,
        excludeFromSemantics: true,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _placeholder(),
        errorBuilder: (context, error, stack) =>
            _placeholder(icon: Icons.image_not_supported_outlined),
      ),
    );
  }

  Widget _placeholder({IconData icon = Icons.image_outlined}) => Container(
    width: size,
    height: size,
    color: AppColors.surfaceVariant,
    alignment: Alignment.center,
    child: Icon(icon, size: size * 0.4, color: AppColors.textSecondary),
  );
}
```

### `WhyIBuyLogo` (`prm393_lab03/lib/widgets/why_i_buy_logo.dart`)

Brand mark: yellow `primary` circle with a `spa_rounded` icon at 58% of the size.

Key props: `size` (default 48), `color` (icon colour, default `onPrimary`).

```dart
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shared brand mark for "Why I Buy".
class WhyIBuyLogo extends StatelessWidget {
  final double size;
  final Color color;

  const WhyIBuyLogo({
    super.key,
    this.size = 48,
    this.color = AppColors.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.spa_rounded, size: size * 0.58, color: color),
      ),
    );
  }
}
```

---

## Overlays

### `ConfirmDialog` (`prm393_lab03/lib/widgets/confirm_dialog.dart`)

Static `ConfirmDialog.show(...)` opens an `AlertDialog` (radius 24) with "Huỷ" and a confirm button; returns `true` only on confirm. Danger mode adds a warning icon and a red confirm button.

Key params: `title` (required), `message` (required), `confirmLabel` (default "Đồng ý"), `isDanger`.

```dart
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// Yes/no dialog with a "Huỷ" button. [isDanger] colors the confirm button with `error`
/// (deletes); otherwise it uses `primary` with `onPrimary` text.
class ConfirmDialog {
  ConfirmDialog._();

  /// true only when the user tapped the confirm button
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Đồng ý',
    bool isDanger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: AppDimens.borderXLarge,
        ),
        icon: isDanger
            ? const Icon(Icons.warning_amber_rounded, color: AppColors.error)
            : null,
        title: Text(title),
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, AppDimens.minTouchTarget),
              backgroundColor: isDanger ? AppColors.error : AppColors.primary,
              foregroundColor: isDanger
                  ? AppColors.textOnDark
                  : AppColors.onPrimary,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
```

### `AppBottomSheet` (`prm393_lab03/lib/widgets/app_bottom_sheet.dart`)

Static `AppBottomSheet.show<T>(...)`: white modal sheet with 24 top corners, 40x4 drag handle, `titleLarge` title and a scrolling body that lifts above the keyboard.

Key params: `title` (required), `child` (required).

```dart
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// Modal sheet with 24 top corners, drag handle and title. The content scrolls and moves
/// above the keyboard.
class AppBottomSheet {
  AppBottomSheet._();

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusXLarge),
        ),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppDimens.space12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: AppDimens.borderPill,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.space16,
                AppDimens.space16,
                AppDimens.space16,
                AppDimens.space8,
              ),
              child: Text(title, style: AppTextStyles.titleLarge),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.space16,
                  AppDimens.space8,
                  AppDimens.space16,
                  AppDimens.space24,
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### `showUndoSnackBar` (`prm393_lab03/lib/widgets/undo_snack_bar.dart`)

Floating Material snack bar for 5 seconds with a "Hoàn tác" (undo) action; replaces any current snack bar.

Params: `context`, `message`, `onUndo`.

```dart
import 'package:flutter/material.dart';

/// Floating snack bar shown for 5 seconds with a "Hoàn tác" action
void showUndoSnackBar(
  BuildContext context,
  String message,
  VoidCallback onUndo,
) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        // With an action, Flutter keeps the SnackBar until dismissed unless persist is false
        persist: false,
        action: SnackBarAction(label: 'Hoàn tác', onPressed: onUndo),
      ),
    );
}
```

---

## State views (`prm393_lab03/lib/widgets/states/`)

Full-area centred views used as screen bodies. `stateView([...])` in `states/state_view.dart` picks `ErrorView` (error wins) or `LoadingView`, else returns null so the screen shows its content or its own `EmptyView`.

### `EmptyView` (`prm393_lab03/lib/widgets/states/empty_view.dart`)

72px grey circle with a 36px icon, `titleMedium` title, optional `bodyMedium` subtitle and an optional yellow elevated action button.

Key props: `title` (required), `subtitle`, `icon` (default `Icons.inbox_outlined`), `actionTitle` + `onAction` (both needed for the button).

```dart
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_text_styles.dart';

/// Standard Empty View when list/content is empty
class EmptyView extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final String? actionTitle;
  final VoidCallback? onAction;

  const EmptyView({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.actionTitle,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Danh sách trống: $title',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppDimens.space20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.titleMedium,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppDimens.space8),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
              ],
              if (actionTitle != null && onAction != null) ...[
                const SizedBox(height: AppDimens.space24),
                ElevatedButton(onPressed: onAction, child: Text(actionTitle!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

### `LoadingView` (`prm393_lab03/lib/widgets/states/loading_view.dart`)

40px dark (`onPrimary`) circular spinner with an optional message below.

Key props: `message`.

```dart
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_text_styles.dart';

/// Standard Loading View with accessible Semantics
class LoadingView extends StatelessWidget {
  final String? message;

  const LoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Đang tải dữ liệu',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.onPrimary,
                  ),
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: AppDimens.space16),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

### `ErrorView` (`prm393_lab03/lib/widgets/states/error_view.dart`)

72px circle in `error` at 10% alpha with a red error icon, fixed title "Đã xảy ra sự cố", the message, and an optional retry button (refresh icon, min 140 x 48).

Key props: `message` (required), `onRetry`, `retryTitle` (default "Thử lại").

```dart
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_text_styles.dart';

/// Standard Error View with Retry Button per Lab 3 requirement (Section 5)
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String retryTitle;

  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.retryTitle = 'Thử lại',
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Thông báo lỗi: $message',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 38,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: AppDimens.space20),
              Text(
                'Đã xảy ra sự cố',
                style: AppTextStyles.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimens.space8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: AppDimens.space24),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppDimens.minTouchTarget,
                    minWidth: 140,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 20),
                    label: Text(retryTitle),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```
