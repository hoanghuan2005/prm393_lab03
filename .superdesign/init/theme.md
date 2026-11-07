# Theme: Why I Buy (Flutter, Material 3)

Design tokens of the mobile app `prm393_lab03/` ("Why I Buy"). Flutter + Material 3, font **Be Vietnam Pro** (via `google_fonts`), brand yellow `#FFDE02` on a Tailwind slate neutral system. Light scaffold `#F8FAFC`, dark scaffold `#020617`. Every widget reads colours, spacing and text from `lib/theme/`; `docs/design-tokens.md` is the written spec the comments refer to.

Token files:

- `prm393_lab03/lib/theme/app_colors.dart`: `AppColors` (all hex values, light + `dark*`)
- `prm393_lab03/lib/theme/app_dimens.dart`: `AppDimens` (spacing, radii, elevation, touch target)
- `prm393_lab03/lib/theme/app_text_styles.dart`: `AppTextStyles` (type scale)
- `prm393_lab03/lib/theme/app_theme.dart`: `AppTheme.lightTheme` / `AppTheme.darkTheme` (`ThemeData`)
- `prm393_lab03/lib/theme/motive_colors.dart`: `MotiveColors` `ThemeExtension` (8 buying-motive palettes)
- `packages/core/lib/src/theme/`: identical copies of the three token files plus `AppTokens`, shared with the web admin `prm393_flutter_admin/`

---

## Part 1: Token summary

### Brand

| Token | Hex | Use |
|---|---|---|
| `primary` | `#FFDE02` | Brand yellow: primary buttons, FAB, logo disc, budget bar fill, dark-mode accents (same in light and dark) |
| `primaryLight` | `#FFE84D` | Lighter brand yellow |
| `primaryContainer` | `#FFFCE6` | Soft yellow background (price chip, tips) |
| `onPrimary` | `#0F172A` | Text/icons on yellow; also the light-mode "accent ink" (focus ring, cursor, loaders, section icons) |

### Neutrals, light vs dark

| Role | Light token | Light hex | Dark token | Dark hex |
|---|---|---|---|---|
| Scaffold background | `background` | `#F8FAFC` | `darkBackground` | `#020617` |
| Surface (cards, sheets, inputs, app bar in light) | `surface` | `#FFFFFF` | `darkSurface` | `#0F172A` |
| Raised card (AppTokens) | `surface` | `#FFFFFF` | `darkCardSurface` | `#1B202A` |
| Variant container | `surfaceVariant` | `#F1F5F9` | `darkSurfaceVariant` | `#1E293B` |
| Muted chip / track | `surfaceVariant` | `#F1F5F9` | `darkSurfaceMuted` | `#262D3B` |
| Divider / border | `divider`, `border` | `#E2E8F0` | `darkBorder` | `#1E293B` |
| Outline | `outline` | `#CBD5E1` | `darkOutline` | `#334155` |
| Inactive page dot | `outline` | `#CBD5E1` | `darkIndicatorInactive` | `#333B49` |
| Text primary | `textPrimary` | `#0F172A` | `darkTextPrimary` | `#F8FAFC` |
| Text body | `textBody` | `#334155` | `darkTextBody` | `#CBD5E1` |
| Text secondary | `textSecondary` | `#64748B` | `darkTextSecondary` | `#94A3B8` |
| Text hint | `textHint` | `#94A3B8` | `darkTextHint` | `#64748B` |
| Text muted | - | - | `darkTextMuted` | `#475569` |
| Text on dark | `textOnDark` | `#FFFFFF` | - | - |
| Nav inactive | `navInactive` | `#94A3B8` | `darkNavInactive` | `#64748B` |
| Neutral accent (figures, "over budget") | `accentNeutral` | `#47667B` | `darkAccentNeutral` | `#93B5CE` |
| Primary container | `primaryContainer` | `#FFFCE6` | `darkPrimaryContainer` | `#2C2706` |
| Primary container border | - | - | `darkPrimaryContainerOutline` | `#5E5410` |
| Text on primary container | `onPrimary` | `#0F172A` | `darkPrimaryContainerText` | `#FEF3C7` |
| Chart strong line | `chartStrong` | `#1E293B` | - | - |

### Status and accents

| Token | Hex | Dark counterpart |
|---|---|---|
| `success` / `successLight` | `#10B981` / `#34D399` | |
| `successContainer` / `onSuccessContainer` | `#ECFDF5` / `#059669` | `darkSuccessContainer` `#064E3B` / `darkOnSuccessContainer` `#6EE7B7` |
| `warning` | `#F59E0B` | |
| `error` / `errorLight` | `#EF4444` / `#F87171` | dark `colorScheme.error` = `errorLight` |
| `errorContainer` / `onErrorContainer` | `#FEE2E2` / `#DC2626` | `darkErrorContainer` `#451A1A` / `darkOnErrorContainer` `#FCA5A5` |
| `info` / `infoLight` / `infoText` | `#3B82F6` / `#60A5FA` / `#2563EB` | |
| `infoContainer` / `onInfoContainer` | `#DBEAFE` / `#1D4ED8` | `darkInfoContainer` `#1E2838` / `darkOnInfoContainer` `#93C5FD` |
| `rose` / `roseLight` | `#F43F5E` / `#FB7185` | crash / alert accent |
| `purple` / `purpleLight` | `#A855F7` / `#C084FC` | dormant / special accent |
| `aiContainer` / `aiAccent` / `onAiContainer` | `#FEF3C7` / `#B45309` / `#92400E` | AI-written insight highlight |
| `slotMorning` / `slotNoon` / `slotEvening` / `slotNight` | `#3B82F6` / `#10B981` / `#F59E0B` / `#6366F1` | time-of-day spending slots |

Design rule baked into the tokens: "over budget" is shown with `accentNeutral`, never red (see `BudgetBar`). Red (`error`) is reserved for destructive actions and failures.

### Buying-motive colours (`BuyingMotive` + `MotiveColors`)

8 motives from `prm393_lab03/lib/models/buying_motive.dart`. Light = Tailwind *-500 foreground on *-100 background; dark = *-400 foreground on *-950 background.

| `BuyingMotive` | Label (vi) | Icon (`Icons.`) | Light fg / bg | Dark fg / bg |
|---|---|---|---|---|
| `need` | Nhu cầu | `inventory_2_outlined` | `#3B82F6` / `#DBEAFE` | `#60A5FA` / `#172554` |
| `want` | Mong muốn | `favorite_outline` | `#EC4899` / `#FCE7F3` | `#F472B6` / `#500724` |
| `sale` | Khuyến mãi | `local_offer_outlined` | `#F59E0B` / `#FEF3C7` | `#FBBF24` / `#451A03` |
| `emotion` | Cảm xúc | `sentiment_very_satisfied_outlined` | `#A855F7` / `#F3E8FF` | `#C084FC` / `#3B0764` |
| `social` | Ảnh hưởng MXH | `trending_up` | `#0EA5E9` / `#E0F2FE` | `#38BDF8` / `#082F49` |
| `convenience` | Tiện lợi | `bolt_outlined` | `#14B8A6` / `#CCFBF1` | `#2DD4BF` / `#042F2E` |
| `ads` | Quảng cáo | `campaign_outlined` | `#2563EB` / `#DBEAFE` | `#60A5FA` / `#172554` |
| `other` | Khác | `more_horiz` | `#64748B` / `#F1F5F9` | `#94A3B8` / `#1E293B` |

Access: theme-aware `MotiveColors.of(context).paletteOf(motive)`; `motive.color` / `motive.backgroundColor` always return the **light** palette (that is what `MotiveChip` uses). The cooldown badge in `WishlistCard` reuses the emotion pair (`motiveEmotion` on `motiveEmotionBg`).

### Typography (`AppTextStyles`, Be Vietnam Pro)

| Style | Size | Weight | Line height | Default colour |
|---|---|---|---|---|
| `displayLarge` | 32 | 700 | 1.25 | `textPrimary` |
| `displayMedium` | 28 | 700 | 1.3 | `textPrimary` |
| `headlineLarge` | 24 | 700 | 1.3 | `textPrimary` |
| `headlineMedium` | 20 | 600 | 1.35 | `textPrimary` |
| `titleLarge` | 18 | 600 | 1.35 | `textPrimary` |
| `titleMedium` | 16 | 600 | 1.4 | `textPrimary` |
| `bodyLarge` | 16 | 400 | 1.45 | `textPrimary` |
| `bodyMedium` | 14 | 400 | 1.45 | `textSecondary` |
| `labelLarge` | 14 | 600 | 1.4 | `textPrimary` |
| `labelMedium` | 12 | 500 | 1.35 | `textSecondary` |
| `caption` | 11 | 500 | default, letterSpacing 0.5 | `textSecondary` |

- Body text is never below 14sp (accessibility rule); 12/11 only for labels and captions.
- `caption` is not mapped into `TextTheme`; widgets use it directly.
- Dark theme recolours every style: `textSecondary` ones become `darkTextSecondary`, the rest `darkTextPrimary`. Dark app bar title is 18 / w700.
- Money uses `titleMedium` w700 (medium), `headlineLarge` w800 (large) or `labelLarge` (small); format `389.000 ₫`.

### Spacing (`AppDimens.space*`, logical px)

`2, 4, 6, 8, 12, 16, 20, 24, 32, 40, 48`. Common: card padding 16, gaps 8/12, section padding 16, sheet bottom padding 24, empty/error view padding 32, button padding 24 x 12 (theme) or 12 x 8 (`AppButton`).

### Radii

| Token | Value | Typical use |
|---|---|---|
| `radiusSmall` / `borderSmall` | 8 | dropdown menu items, small boxes in the price chart |
| `radiusMedium` / `borderMedium` | 12 | inputs, product image, dark chips |
| `radiusLarge` / `borderLarge` | 16 | cards, `SectionCard`, dark dialogs |
| `radiusXLarge` / `borderXLarge` | 24 | `ConfirmDialog`, bottom-sheet top corners |
| `radiusPill` / `borderPill` | 999 | all buttons, chips, badges, progress bars |

### Elevation and shadows

- `elevationNone 0`, `elevationLow 1`, `elevationMedium 3`, `elevationHigh 6`. The UI is flat: app bar, buttons and cards use 0 and separate with a 1px `divider` border. Dark `dialogTheme` uses elevation 4.
- No shadow token. Hero/summary cards in screens (`home_screen.dart`, `budget_screen.dart`, `history_screen.dart`) add a soft ad-hoc shadow:
  `BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02), blurRadius: 8, offset: Offset(0, 2))` (0.03 on history).
- Minimum touch target: `AppDimens.minTouchTarget = 48`.

### Component defaults from `ThemeData`

- Elevated button: `primary` bg, `onPrimary` fg, full width, min height 48, pill, no elevation, `labelLarge`.
- Outlined button: `textPrimary` fg, 1.5px `outline` border (dark: `darkOutline`), pill, min height 48.
- Text button: `onPrimary` (light) / `primary` (dark).
- Input: filled `surface` (dark `darkSurface`), padding 16, radius 12, enabled border `divider` (dark `darkBorder`), focused 1.5px `onPrimary` (dark `primary`), error `error`.
- Card: `surface`, 1px `divider` border, radius 16, elevation 0, zero margin.
- Progress / cursor: `onPrimary` (light), `primary` (dark); selection = `primary` at 40% / 30%.
- Dark only: navigation bar `darkSurface` with `primary` @ 20% indicator, selected icon/label `primary`, labels 12; chips `darkSurfaceVariant` bg, `darkOutline` 0.5 border, radius 12.

### Breakpoints

- Mobile app: no breakpoints; single-column phone layout with bottom navigation. Some forms cap width: login / email verification `maxWidth: 430`, record purchase `maxWidth: 640`.
- Web admin (`prm393_flutter_admin/lib/screens/admin_shell.dart`): `< 720` bottom `NavigationBar`, `720-1099` `NavigationRail`, `>= 1100` full sidebar; top bar compact `< 900`. Screen-level splits at 760 / 900 / 960 / 980; sign-in card `maxWidth: 440`.

---

## Part 2: Source

### `prm393_lab03/lib/theme/app_colors.dart`

```dart
import 'package:flutter/material.dart';

/// Centralized Color Tokens extracted from Figma "Why I Buy ver2".
/// Synchronized with Admin Web Portal (Tailwind CSS) color palette.
/// Names describe the role, not the hue. Screens/widgets use only these tokens
/// (see docs/design-tokens.md).
class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIMARY BRAND COLORS
  // Web/app brand yellow (#FFDE02)
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color primary = Color(0xFFFFDE02);
  static const Color primaryLight = Color(0xFFFFE84D);
  static const Color primaryContainer = Color(
    0xFFFFFCE6,
  ); // Light: Soft yellow bg
  static const Color onPrimary = Color(
    0xFF0F172A,
  ); // Tailwind slate-900 (text on yellow)

  // ═══════════════════════════════════════════════════════════════════════════
  // LIGHT MODE — Neutral Background & Surfaces
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color background = Color(0xFFF8FAFC); // Tailwind slate-50
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Tailwind slate-100
  static const Color divider = Color(0xFFE2E8F0); // Tailwind slate-200
  static const Color border = Color(0xFFE2E8F0); // Tailwind slate-200
  static const Color outline = Color(0xFFCBD5E1); // Tailwind slate-300

  // ═══════════════════════════════════════════════════════════════════════════
  // LIGHT MODE — Text Colors
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color textPrimary = Color(0xFF0F172A); // Tailwind slate-900
  static const Color textBody = Color(0xFF334155); // Tailwind slate-700
  static const Color textSecondary = Color(0xFF64748B); // Tailwind slate-500
  static const Color textHint = Color(0xFF94A3B8); // Tailwind slate-400
  static const Color textOnDark = Color(0xFFFFFFFF);

  /// Neutral emphasis for figures, labels and the "over budget" state
  static const Color accentNeutral = Color(0xFF47667B);

  // Navigation
  static const Color navInactive = Color(0xFF94A3B8); // Tailwind slate-400

  // ═══════════════════════════════════════════════════════════════════════════
  // STATUS COLORS (Shared light/dark — Web uses same Tailwind palette)
  // emerald-500, emerald-400, amber-500, rose-500, blue-500
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color success = Color(0xFF10B981); // Tailwind emerald-500
  static const Color successLight = Color(0xFF34D399); // Tailwind emerald-400
  static const Color successContainer = Color(0xFFECFDF5);
  static const Color onSuccessContainer = Color(0xFF059669); // emerald-600
  static const Color warning = Color(0xFFF59E0B); // Tailwind amber-500
  static const Color error = Color(0xFFEF4444); // Tailwind red-500
  static const Color errorLight = Color(0xFFF87171); // Tailwind red-400 (dark)
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onErrorContainer = Color(0xFFDC2626); // red-600
  static const Color info = Color(0xFF3B82F6); // Tailwind blue-500
  static const Color infoLight = Color(0xFF60A5FA); // Tailwind blue-400 (dark)

  // Rose (Crash/alert accent)
  static const Color rose = Color(0xFFF43F5E); // Tailwind rose-500
  static const Color roseLight = Color(0xFFFB7185); // Tailwind rose-400

  // Purple (Dormant/special accent)
  static const Color purple = Color(0xFFA855F7); // Tailwind purple-500
  static const Color purpleLight = Color(0xFFC084FC); // Tailwind purple-400

  // ═══════════════════════════════════════════════════════════════════════════
  // AI-WRITTEN INSIGHT HIGHLIGHT
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color aiContainer = Color(0xFFFEF3C7); // amber-100
  static const Color aiAccent = Color(0xFFB45309); // amber-700
  static const Color onAiContainer = Color(0xFF92400E); // amber-800

  // ═══════════════════════════════════════════════════════════════════════════
  // TIME-OF-DAY SLOTS (Thói quen chi tiêu)
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color slotMorning = Color(0xFF3B82F6); // blue-500
  static const Color slotNoon = Color(0xFF10B981); // emerald-500
  static const Color slotEvening = Color(0xFFF59E0B); // amber-500
  static const Color slotNight = Color(0xFF6366F1); // indigo-500

  // Charts
  static const Color chartStrong = Color(0xFF1E293B); // Tailwind slate-800

  // ═══════════════════════════════════════════════════════════════════════════
  // 8 MOTIVE CHIP COLORS (Synced with Web motiveDistributionData)
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color motiveNeed = Color(0xFF3B82F6); // blue-500 (Web: #3B82F6)
  static const Color motiveNeedBg = Color(0xFFDBEAFE); // blue-100

  static const Color motiveWant = Color(0xFFEC4899); // pink-500 (Web: #EC4899)
  static const Color motiveWantBg = Color(0xFFFCE7F3); // pink-100

  static const Color motiveSale = Color(0xFFF59E0B); // amber-500 (Web: #F59E0B)
  static const Color motiveSaleBg = Color(0xFFFEF3C7); // amber-100

  static const Color motiveEmotion = Color(
    0xFFA855F7,
  ); // purple-500 (Web: #A855F7)
  static const Color motiveEmotionBg = Color(0xFFF3E8FF); // purple-100

  static const Color motiveSocial = Color(0xFF0EA5E9); // sky-500
  static const Color motiveSocialBg = Color(0xFFE0F2FE); // sky-100

  static const Color motiveConvenience = Color(0xFF14B8A6); // teal-500
  static const Color motiveConvenienceBg = Color(0xFFCCFBF1); // teal-100

  static const Color motiveAds = Color(0xFF2563EB); // blue-600
  static const Color motiveAdsBg = Color(0xFFDBEAFE); // blue-100

  static const Color motiveOther = Color(0xFF64748B); // slate-500
  static const Color motiveOtherBg = Color(0xFFF1F5F9); // slate-100

  // ═══════════════════════════════════════════════════════════════════════════
  // DARK MODE COLORS (Matching Web Admin Portal Tailwind dark palette)
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color darkBackground = Color(0xFF020617); // slate-950
  static const Color darkSurface = Color(0xFF0F172A); // slate-900
  static const Color darkSurfaceVariant = Color(0xFF1E293B); // slate-800
  static const Color darkBorder = Color(0xFF1E293B); // slate-800
  static const Color darkOutline = Color(0xFF334155); // slate-700

  static const Color darkTextPrimary = Color(0xFFF8FAFC); // slate-50
  static const Color darkTextSecondary = Color(0xFF94A3B8); // slate-400
  static const Color darkTextHint = Color(0xFF64748B); // slate-500
  static const Color darkTextMuted = Color(0xFF475569); // slate-600

  // ═══════════════════════════════════════════════════════════════════════════
  // DARK MODE — role tokens for the `isDark ? dark* : light` branches in screens
  // (mapping from the old hex values: docs/design-tokens.md, section 2.5)
  // ═══════════════════════════════════════════════════════════════════════════
  /// Dark counterpart of [primaryContainer] (also `colorScheme.primaryContainer`)
  static const Color darkPrimaryContainer = Color(0xFF2C2706);

  /// Border of a [darkPrimaryContainer] box; active Switch track on that box
  static const Color darkPrimaryContainerOutline = Color(0xFF5E5410);

  /// Text on [darkPrimaryContainer] (AI note, tips)
  static const Color darkPrimaryContainerText = Color(0xFFFEF3C7); // amber-100

  /// Raised card on the dark background (light: [surface])
  static const Color darkCardSurface = Color(0xFF1B202A);

  /// Unselected chip, segmented control, progress track (light: [surfaceVariant])
  static const Color darkSurfaceMuted = Color(0xFF262D3B);

  /// Inactive page dot (light: [outline])
  static const Color darkIndicatorInactive = Color(0xFF333B49);

  static const Color darkTextBody = Color(0xFFCBD5E1); // slate-300
  static const Color darkNavInactive = Color(0xFF64748B); // slate-500

  /// Dark counterpart of [accentNeutral] (also `colorScheme.tertiary`)
  static const Color darkAccentNeutral = Color(0xFF93B5CE);

  static const Color darkSuccessContainer = Color(0xFF064E3B); // emerald-900
  static const Color darkOnSuccessContainer = Color(0xFF6EE7B7); // emerald-300
  static const Color darkErrorContainer = Color(0xFF451A1A);
  static const Color darkOnErrorContainer = Color(0xFFFCA5A5); // red-300
  static const Color darkInfoContainer = Color(0xFF1E2838);
  static const Color darkOnInfoContainer = Color(0xFF93C5FD); // blue-300

  // Info badge, light mode (dark text: [infoLight])
  static const Color infoContainer = Color(0xFFDBEAFE); // blue-100
  static const Color onInfoContainer = Color(0xFF1D4ED8); // blue-700
  static const Color infoText = Color(0xFF2563EB); // blue-600
}
```

### `prm393_lab03/lib/theme/app_dimens.dart`

```dart
import 'package:flutter/material.dart';

/// Centralized Spacing, Radius, and Elevation tokens per Figma Design System
class AppDimens {
  AppDimens._();

  // Spacing & Padding
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  static const double radiusPill = 999.0; // Capsule buttons / chips

  static const BorderRadius borderSmall = BorderRadius.all(
    Radius.circular(radiusSmall),
  );
  static const BorderRadius borderMedium = BorderRadius.all(
    Radius.circular(radiusMedium),
  );
  static const BorderRadius borderLarge = BorderRadius.all(
    Radius.circular(radiusLarge),
  );
  static const BorderRadius borderXLarge = BorderRadius.all(
    Radius.circular(radiusXLarge),
  );
  static const BorderRadius borderPill = BorderRadius.all(
    Radius.circular(radiusPill),
  );

  // Accessibility Requirements
  static const double minTouchTarget = 48.0; // Min 48dp touch target rule

  // Elevations
  static const double elevationNone = 0.0;
  static const double elevationLow = 1.0;
  static const double elevationMedium = 3.0;
  static const double elevationHigh = 6.0;
}
```

### `prm393_lab03/lib/theme/app_text_styles.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Centralized Typography using 'Be Vietnam Pro'
/// Strictly complies with the >= 14sp body text accessibility rule
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get displayLarge => GoogleFonts.beVietnamPro(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static TextStyle get displayMedium => GoogleFonts.beVietnamPro(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get headlineLarge => GoogleFonts.beVietnamPro(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get headlineMedium => GoogleFonts.beVietnamPro(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  static TextStyle get titleLarge => GoogleFonts.beVietnamPro(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  static TextStyle get titleMedium => GoogleFonts.beVietnamPro(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static TextStyle get bodyLarge => GoogleFonts.beVietnamPro(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.45,
  );

  // Must be >= 14sp per Lab 2 accessibility checklist
  static TextStyle get bodyMedium => GoogleFonts.beVietnamPro(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  static TextStyle get labelLarge => GoogleFonts.beVietnamPro(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static TextStyle get labelMedium => GoogleFonts.beVietnamPro(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.35,
  );

  static TextStyle get caption => GoogleFonts.beVietnamPro(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );
}
```

### `prm393_lab03/lib/theme/app_theme.dart` (476 lines, render-relevant parts)

Light theme in full (lines 1-194):

```dart
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_text_styles.dart';
import 'motive_colors.dart';

/// Centralized ThemeData for Why I Buy
/// Color palette synchronized with Admin Web Portal (Tailwind CSS)
/// Both platforms share the same brand identity: amber-400 primary + slate system
class AppTheme {
  AppTheme._();

  // ═══════════════════════════════════════════════════════════════════════════
  // LIGHT THEME
  // Web equivalent: hypothetical light mode (inverse of current dark portal)
  // ═══════════════════════════════════════════════════════════════════════════
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      // Primary: amber-400 brand
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimary,
      // Secondary: slate-900 (dark navy)
      secondary: AppColors.onPrimary,
      onSecondary: AppColors.textOnDark,
      secondaryContainer: AppColors.primaryContainer,
      onSecondaryContainer: AppColors.onPrimary,
      // Tertiary: neutral accent
      tertiary: AppColors.accentNeutral,
      onTertiary: AppColors.textOnDark,
      // Error: red-500
      error: AppColors.error,
      onError: AppColors.textOnDark,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      // Surface: white cards on slate-50 bg
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerHighest: AppColors.surfaceVariant,
      // Borders & outlines: slate-200/300
      outline: AppColors.outline,
      outlineVariant: AppColors.divider,
      // Inverse: dark overlay
      inverseSurface: AppColors.onPrimary,
      onInverseSurface: AppColors.textOnDark,
      inversePrimary: AppColors.primary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Be Vietnam Pro',
      extensions: const [MotiveColors.light],

      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: AppDimens.elevationNone,
        centerTitle: false,
        titleTextStyle: AppTextStyles.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      // Elevated Button Theme (Min 48dp height for accessibility)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(double.infinity, AppDimens.minTouchTarget),
          shape: const RoundedRectangleBorder(
            borderRadius: AppDimens.borderPill,
          ),
          elevation: AppDimens.elevationNone,
          textStyle: AppTextStyles.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space24,
            vertical: AppDimens.space12,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.onPrimary,
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // Loaders / progress bars
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.onPrimary,
        linearTrackColor: AppColors.surfaceVariant,
        circularTrackColor: Colors.transparent,
      ),

      // Text cursor & selection handles
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.onPrimary,
        selectionHandleColor: AppColors.onPrimary,
        selectionColor: AppColors.primary.withValues(alpha: 0.4),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(double.infinity, AppDimens.minTouchTarget),
          side: const BorderSide(color: AppColors.outline, width: 1.5),
          shape: const RoundedRectangleBorder(
            borderRadius: AppDimens.borderPill,
          ),
          textStyle: AppTextStyles.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space24,
            vertical: AppDimens.space12,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppDimens.space16,
          vertical: AppDimens.space16,
        ),
        hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: AppDimens.borderMedium,
          borderSide: BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimens.borderMedium,
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimens.borderMedium,
          borderSide: BorderSide(color: AppColors.onPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDimens.borderMedium,
          borderSide: BorderSide(color: AppColors.error),
        ),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: AppDimens.elevationNone,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimens.borderLarge,
          side: BorderSide(color: AppColors.divider, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
```

Dark theme colour scheme (lines 196-260):

```dart
  // ═══════════════════════════════════════════════════════════════════════════
  // DARK THEME
  // Exactly matches Admin Web Portal Tailwind dark palette:
  //   bg: slate-950 (#020617)  |  surface: slate-900 (#0F172A)
  //   cards: slate-900/80      |  border: slate-800 (#1E293B)
  //   text: slate-50/400       |  primary: amber-400 (#FBBF24)
  // ═══════════════════════════════════════════════════════════════════════════
  static ThemeData get darkTheme {
    // Web: bg-slate-950 → scaffold
    const darkBackground = AppColors.darkBackground; // #020617
    // Web: bg-slate-900/80 → cards, panels
    const darkSurface = AppColors.darkSurface; // #0F172A
    // Web: bg-slate-800 → variant containers
    const darkSurfaceVariant = AppColors.darkSurfaceVariant; // #1E293B
    // Web: border-slate-800
    const darkBorder = AppColors.darkBorder; // #1E293B
    // Web: text-white / text-slate-50
    const darkTextPrimary = AppColors.darkTextPrimary; // #F8FAFC
    // Web: text-slate-400
    const darkTextSecondary = AppColors.darkTextSecondary; // #94A3B8

    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      // Primary: amber-400 (same as web `bg-amber-400`, `text-amber-400`)
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      // Web: bg-amber-400/20 containers
      primaryContainer: AppColors.darkPrimaryContainer,
      onPrimaryContainer: AppColors.primary,
      // Secondary: light text
      secondary: darkTextPrimary,
      onSecondary: Color(0xFF0F172A),
      // Web: bg-slate-800/60 secondary containers
      secondaryContainer: Color(0xFF1E293B),
      onSecondaryContainer: darkTextPrimary,
      // Tertiary: muted blue-gray
      tertiary: AppColors.darkAccentNeutral,
      onTertiary: Color(0xFF0F172A),
      // Error: red-400 for dark (Web: `text-rose-400`)
      error: AppColors.errorLight, // #F87171
      onError: Color(0xFF450A0A),
      errorContainer: AppColors.darkErrorContainer,
      onErrorContainer: AppColors.darkOnErrorContainer, // red-300
      // Surface: slate-900 (matches Web `bg-slate-900/80`)
      surface: darkSurface,
      onSurface: darkTextPrimary,
      onSurfaceVariant: darkTextSecondary,
      // Variant: slate-800 (matches Web `bg-slate-800`)
      surfaceContainerHighest: darkSurfaceVariant,
      // Outline: slate-700 (Web: `border-slate-700`)
      outline: AppColors.darkOutline, // #334155
      // OutlineVariant: slate-800 (Web: `border-slate-800`)
      outlineVariant: darkBorder,
      // Inverse
      inverseSurface: darkTextPrimary,
      onInverseSurface: Color(0xFF0F172A),
      inversePrimary: Color(0xFFD4B800),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBackground,
      fontFamily: 'Be Vietnam Pro',
      extensions: const [MotiveColors.dark],
```

Lines 262-420 of the dark theme repeat the light component themes with dark tokens (summarised in Part 1: text recoloured, app bar `darkBackground` with an 18/w700 title, text button `primary`, progress `primary`, outlined border `darkOutline`, input fill `darkSurface` with `darkBorder` / `primary` focus, card `darkSurface` + `darkBorder`). Components that exist only in the dark theme (lines 422-476):

```dart
      // Dialog: slate-900 bg
      dialogTheme: const DialogThemeData(
        backgroundColor: darkSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: AppDimens.borderLarge),
      ),

      // Bottom Sheet: slate-900 bg
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        modalBackgroundColor: darkSurface,
      ),

      // Navigation Bar (bottom nav): slate-900 bg, amber-400 selected
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary);
          }
          return const IconThemeData(color: AppColors.darkTextSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            color: AppColors.darkTextSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
      ),

      // Chip Theme: matches Web filter pills
      // Web: `bg-slate-800/80 text-slate-300 border border-slate-700/60`
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        selectedColor: AppColors.primary,
        side: BorderSide(color: AppColors.darkOutline, width: 0.5),
        labelStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppDimens.borderMedium),
      ),
    );
  }
}
```

### `prm393_lab03/lib/theme/motive_colors.dart`

```dart
import 'package:flutter/material.dart';

import '../models/buying_motive.dart';
import 'app_colors.dart';

/// Foreground + background pair for one buying motive
@immutable
class MotivePalette {
  final Color foreground;
  final Color background;

  const MotivePalette(this.foreground, this.background);

  MotivePalette lerp(MotivePalette other, double t) => MotivePalette(
    Color.lerp(foreground, other.foreground, t)!,
    Color.lerp(background, other.background, t)!,
  );
}

/// Single source of the 8 motive colors.
/// Synchronized with Admin Web Portal (`motiveDistributionData` in mockData.ts).
/// Widgets: `MotiveColors.of(context).of(motive)`; models read [MotiveColors.light].
@immutable
class MotiveColors extends ThemeExtension<MotiveColors> {
  final Map<BuyingMotive, MotivePalette> palettes;

  const MotiveColors(this.palettes);

  // ═══════════════════════════════════════════════════════════════════════════
  // LIGHT MODE — vibrant fg on pastel bg (Tailwind *-500 / *-100)
  // ═══════════════════════════════════════════════════════════════════════════
  static const light = MotiveColors({
    BuyingMotive.need: MotivePalette(
      AppColors.motiveNeed, // blue-500
      AppColors.motiveNeedBg, // blue-100
    ),
    BuyingMotive.want: MotivePalette(
      AppColors.motiveWant, // pink-500
      AppColors.motiveWantBg, // pink-100
    ),
    BuyingMotive.sale: MotivePalette(
      AppColors.motiveSale, // amber-500
      AppColors.motiveSaleBg, // amber-100
    ),
    BuyingMotive.emotion: MotivePalette(
      AppColors.motiveEmotion, // purple-500
      AppColors.motiveEmotionBg, // purple-100
    ),
    BuyingMotive.social: MotivePalette(
      AppColors.motiveSocial, // sky-500
      AppColors.motiveSocialBg, // sky-100
    ),
    BuyingMotive.convenience: MotivePalette(
      AppColors.motiveConvenience, // teal-500
      AppColors.motiveConvenienceBg, // teal-100
    ),
    BuyingMotive.ads: MotivePalette(
      AppColors.motiveAds, // blue-600
      AppColors.motiveAdsBg, // blue-100
    ),
    BuyingMotive.other: MotivePalette(
      AppColors.motiveOther, // slate-500
      AppColors.motiveOtherBg, // slate-100
    ),
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // DARK MODE — lighter/luminous fg on deep-hued bg
  // Matches Web admin pie chart colors on slate-950 background
  // ═══════════════════════════════════════════════════════════════════════════
  static const dark = MotiveColors({
    BuyingMotive.need: MotivePalette(
      Color(0xFF60A5FA), // blue-400
      Color(0xFF172554), // blue-950
    ),
    BuyingMotive.want: MotivePalette(
      Color(0xFFF472B6), // pink-400
      Color(0xFF500724), // pink-950
    ),
    BuyingMotive.sale: MotivePalette(
      Color(0xFFFBBF24), // amber-400
      Color(0xFF451A03), // amber-950
    ),
    BuyingMotive.emotion: MotivePalette(
      Color(0xFFC084FC), // purple-400
      Color(0xFF3B0764), // purple-950
    ),
    BuyingMotive.social: MotivePalette(
      Color(0xFF38BDF8), // sky-400
      Color(0xFF082F49), // sky-950
    ),
    BuyingMotive.convenience: MotivePalette(
      Color(0xFF2DD4BF), // teal-400
      Color(0xFF042F2E), // teal-950
    ),
    BuyingMotive.ads: MotivePalette(
      Color(0xFF60A5FA), // blue-400
      Color(0xFF172554), // blue-950
    ),
    BuyingMotive.other: MotivePalette(
      Color(0xFF94A3B8), // slate-400
      Color(0xFF1E293B), // slate-800
    ),
  });

  static MotiveColors of(BuildContext context) =>
      Theme.of(context).extension<MotiveColors>() ?? light;

  MotivePalette paletteOf(BuyingMotive motive) =>
      palettes[motive] ?? light.palettes[motive]!;

  @override
  MotiveColors copyWith({Map<BuyingMotive, MotivePalette>? palettes}) =>
      MotiveColors(palettes ?? this.palettes);

  @override
  MotiveColors lerp(covariant MotiveColors? other, double t) {
    if (other == null) return this;
    return MotiveColors({
      for (final m in BuyingMotive.values)
        m: paletteOf(m).lerp(other.paletteOf(m), t),
    });
  }
}
```

### Motive labels and icons: `prm393_lab03/lib/models/buying_motive.dart`

```dart
import 'package:flutter/material.dart';

import '../theme/motive_colors.dart';

/// 8 Buying Motives based on "Why I Buy - The Psychology of Money"
enum BuyingMotive {
  need('need', 'Nhu cầu', Icons.inventory_2_outlined),
  want('want', 'Mong muốn', Icons.favorite_outline),
  sale('sale', 'Khuyến mãi', Icons.local_offer_outlined),
  emotion('emotion', 'Cảm xúc', Icons.sentiment_very_satisfied_outlined),
  social('social', 'Ảnh hưởng MXH', Icons.trending_up),
  convenience('convenience', 'Tiện lợi', Icons.bolt_outlined),
  ads('ads', 'Quảng cáo', Icons.campaign_outlined),
  other('other', 'Khác', Icons.more_horiz);

  final String key;
  final String label;
  final IconData icon;

  const BuyingMotive(this.key, this.label, this.icon);

  /// Colors come from the single source in MotiveColors (theme/motive_colors.dart)
  Color get color => MotiveColors.light.paletteOf(this).foreground;
  Color get backgroundColor => MotiveColors.light.paletteOf(this).background;

  static BuyingMotive fromKey(String? key) {
    return BuyingMotive.values.firstWhere(
      (m) => m.key == key,
      orElse: () => BuyingMotive.other,
    );
  }

  /// "Nhu cầu" items skip the cooling-off period; every other motive waits
  bool get skipsCooldown => this == BuyingMotive.need;

  /// Whether this motive relates to periodic shopping sale dates
  bool get relatesToSales => this == BuyingMotive.sale;
}
```

---

## Web admin tokens (`packages/core`)

The web admin `prm393_flutter_admin/` depends on the shared package `why_i_buy_core` (`packages/core/`). `packages/core/lib/src/theme/app_colors.dart`, `app_dimens.dart` and `app_text_styles.dart` are byte-identical to the mobile files above, so both apps share one palette, spacing scale and type scale. The admin builds its `ThemeData` in `prm393_flutter_admin/lib/app/admin_theme.dart` (`buildAdminTheme(Brightness)`, `ColorScheme.fromSeed(AppColors.primary)` overridden with the same tokens; dark cards use `darkCardSurface`, muted fills `darkSurfaceMuted`) and reads colours through `context.tokens` (`prm393_flutter_admin/lib/utils/tokens.dart`), which returns `AppTokens`:

### `packages/core/lib/src/theme/app_tokens.dart`

```dart
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The design tokens for the current brightness: the light tokens exactly as
/// they are, or their `dark*` counterparts from [AppColors] in a dark theme.
/// Widgets shared by the app and the web admin read colours through this, so
/// one component works in both modes.
class AppTokens {
  final bool isDark;

  const AppTokens._(this.isDark);

  factory AppTokens.of(BuildContext context) =>
      AppTokens._(Theme.of(context).brightness == Brightness.dark);

  Color get background =>
      isDark ? AppColors.darkBackground : AppColors.background;
  Color get surface => isDark ? AppColors.darkCardSurface : AppColors.surface;
  Color get surfaceMuted =>
      isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceVariant;
  Color get divider => isDark ? AppColors.darkBorder : AppColors.divider;
  Color get outline => isDark ? AppColors.darkOutline : AppColors.outline;

  Color get textPrimary =>
      isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color get textBody => isDark ? AppColors.darkTextBody : AppColors.textBody;
  Color get textSecondary =>
      isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get textHint => isDark ? AppColors.darkTextHint : AppColors.textHint;

  Color get primaryContainer =>
      isDark ? AppColors.darkPrimaryContainer : AppColors.primaryContainer;
  Color get onPrimaryContainer =>
      isDark ? AppColors.darkPrimaryContainerText : AppColors.onPrimary;

  Color get successContainer =>
      isDark ? AppColors.darkSuccessContainer : AppColors.successContainer;
  Color get onSuccessContainer =>
      isDark ? AppColors.darkOnSuccessContainer : AppColors.onSuccessContainer;
  Color get errorContainer =>
      isDark ? AppColors.darkErrorContainer : AppColors.errorContainer;
  Color get onErrorContainer =>
      isDark ? AppColors.darkOnErrorContainer : AppColors.onErrorContainer;
  Color get infoContainer =>
      isDark ? AppColors.darkInfoContainer : AppColors.infoContainer;
  Color get onInfoContainer =>
      isDark ? AppColors.darkOnInfoContainer : AppColors.onInfoContainer;
  Color get warningContainer =>
      isDark ? AppColors.darkPrimaryContainer : AppColors.aiContainer;
  Color get onWarningContainer =>
      isDark ? AppColors.darkPrimaryContainerText : AppColors.onAiContainer;

  /// An [AppTextStyles] style recoloured for this brightness (light: unchanged)
  TextStyle text(TextStyle style) {
    if (!isDark) return style;
    final secondary = style.color == AppColors.textSecondary;
    return style.copyWith(
      color: secondary
          ? AppColors.darkTextSecondary
          : AppColors.darkTextPrimary,
    );
  }
}
```
