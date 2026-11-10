# Dark mode — D1–D3

Ngày đo và sửa: 10/11/2026. Phạm vi: app Flutter mobile; giữ light mode, bố cục, dữ liệu và logic.

## Kết quả

- D1: có hàm WCAG 2.1 contrastRatio, kiểm thử đen/trắng, alpha và bảng đo dưới đây.
- D2: thống nhất surface/card; tăng tương phản hint, chữ phụ, nav và input; thêm AppSemanticColors; cấu hình dark SnackBar, DatePicker, Switch, Slider, Chip.
- D3: chuyển màu màn hình/widget sang token; dùng MotiveColors theo theme, kể cả chip đang chọn; giữ nguyên màu light của các nhánh cũ.
- D4: còn cần người dùng rà bằng mắt trên Redmi. Kiểm thử widget không thay thế đo/quan sát trên thiết bị.

## Cách đọc phép đo

Chữ thường/phụ/hint ≥ 4,5:1; icon/viền input ≥ 3:1; viền thẻ ≥ 1,5:1. Màu có alpha được pha trên nền trước khi tính. Nền đo phải đục.
Ma trận dưới đây liệt kê cả các cặp **giả định không được sử dụng** (ví dụ chữ success trên nền error). Dấu ! nghĩa là không được dùng cặp đó cho chữ thường, không có nghĩa mọi cặp trong ma trận xuất hiện trong UI.

## Ma trận trước sửa

| Chữ / nền | Background | Surface | CardSurface | SurfaceVariant | SurfaceMuted | PrimaryContainer | SuccessContainer | ErrorContainer | InfoContainer |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| darkTextPrimary | 19.28 | 17.06 | 15.60 | 13.98 | 13.20 | 14.34 | 9.29 | 14.18 | 14.18 |
| darkTextBody | 13.59 | 12.02 | 10.99 | 9.85 | 9.30 | 10.10 | 6.55 | 9.99 | 9.99 |
| darkTextSecondary | 7.87 | 6.96 | 6.37 | 5.71 | 5.39 | 5.85 | 3.79 ! | 5.79 | 5.78 |
| darkTextHint | 4.24 ! | 3.75 ! | 3.43 ! | 3.07 ! | 2.90 ! | 3.15 ! | 2.04 ! | 3.12 ! | 3.12 ! |
| darkTextMuted | 2.66 ! | 2.36 ! | 2.15 ! | 1.93 ! | 1.82 ! | 1.98 ! | 1.28 ! | 1.96 ! | 1.96 ! |
| darkNavInactive | 4.24 ! | 3.75 ! | 3.43 ! | 3.07 ! | 2.90 ! | 3.15 ! | 2.04 ! | 3.12 ! | 3.12 ! |
| primary | 15.08 | 13.35 | 12.20 | 10.94 | 10.32 | 11.22 | 7.27 | 11.09 | 11.09 |
| darkAccentNeutral | 9.36 | 8.28 | 7.57 | 6.79 | 6.40 | 6.96 | 4.51 | 6.88 | 6.88 |
| errorLight | 7.29 | 6.45 | 5.90 | 5.29 | 4.99 | 5.42 | 3.51 ! | 5.36 | 5.36 |
| darkPrimaryContainerText | 18.12 | 16.03 | 14.66 | 13.14 | 12.40 | 13.47 | 8.73 | 13.32 | 13.32 |
| darkOnSuccessContainer | 13.23 | 11.71 | 10.71 | 9.60 | 9.06 | 9.84 | 6.38 | 9.73 | 9.73 |
| darkOnErrorContainer | 10.63 | 9.41 | 8.60 | 7.71 | 7.27 | 7.90 | 5.12 | 7.82 | 7.81 |
| darkOnInfoContainer | 11.19 | 9.90 | 9.05 | 8.11 | 7.66 | 8.32 | 5.39 | 8.23 | 8.23 |

## Ma trận token hiện tại

| Chữ / nền | Background | Surface | CardSurface | SurfaceVariant | SurfaceMuted | PrimaryContainer | SuccessContainer | ErrorContainer | InfoContainer |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| darkTextPrimary | 18.45 | 13.09 | 13.09 | 11.33 | 11.33 | 14.34 | 9.29 | 14.18 | 14.18 |
| darkTextBody | 13.00 | 9.23 | 9.23 | 7.99 | 7.99 | 10.10 | 6.55 | 9.99 | 9.99 |
| darkTextSecondary | 10.29 | 7.30 | 7.30 | 6.32 | 6.32 | 8.00 | 5.18 | 7.91 | 7.91 |
| darkTextHint | 10.29 | 7.30 | 7.30 | 6.32 | 6.32 | 8.00 | 5.18 | 7.91 | 7.91 |
| darkTextMuted | 2.55 ! | 1.81 ! | 1.81 ! | 1.56 ! | 1.56 ! | 1.98 ! | 1.28 ! | 1.96 ! | 1.96 ! |
| darkNavInactive | 10.29 | 7.30 | 7.30 | 6.32 | 6.32 | 8.00 | 5.18 | 7.91 | 7.91 |
| primary | 14.43 | 10.24 | 10.24 | 8.86 | 8.86 | 11.22 | 7.27 | 11.09 | 11.09 |
| darkAccentNeutral | 8.95 | 6.36 | 6.36 | 5.50 | 5.50 | 6.96 | 4.51 | 6.88 | 6.88 |
| errorLight | 6.98 | 4.95 | 4.95 | 4.29 ! | 4.29 ! | 5.42 | 3.51 ! | 5.36 | 5.36 |
| darkPrimaryContainerText | 17.33 | 12.30 | 12.30 | 10.65 | 10.65 | 13.47 | 8.73 | 13.32 | 13.32 |
| darkOnSuccessContainer | 12.66 | 8.99 | 8.99 | 7.78 | 7.78 | 9.84 | 6.38 | 9.73 | 9.73 |
| darkOnErrorContainer | 10.17 | 7.22 | 7.22 | 6.25 | 6.25 | 7.90 | 5.12 | 7.82 | 7.81 |
| darkOnInfoContainer | 10.70 | 7.60 | 7.60 | 6.57 | 6.57 | 8.32 | 5.39 | 8.23 | 8.23 |

darkTextMuted chỉ dành cho trang trí; UI không dùng token này cho chữ. errorLight còn dùng cho viền; chữ lỗi dùng onErrorContainer sáng hơn trên nền phụ. Primary vàng là nền control; chữ nhấn dùng emphasis/brandText.

| Cặp viền/nền | Trước | Sau | Ngưỡng |
|---|---:|---:|---:|
| darkBorder / darkSurface | 1.22 | 2.88 | 1,5 |
| darkBorder / darkCardSurface | 1.12 | 2.88 | 1,5 |
| darkOutline / darkSurface | 1.72 | 4.84 | 3 |
| darkOutline / darkCardSurface | 1.58 | 4.84 | 3 |
| Surface / background | 1.13 | 1.41 | tách lớp |

## Palette triển khai — light giữ nguyên

Tất cả giá trị được xuất từ extension thật, không chép tay. Tỉ lệ cuối dùng nền card để tham khảo; container phải ghép đúng on-colour, kiểm thử ở dark_contrast_test.dart.

| Vai trò | Light giữ nguyên | Dark | So với card dark |
|---|---|---|---:|
| linkedAccountAccent | #4CAF50 | #6EE7B7 | 8.99 |
| linkedAccountText | #2E7D32 | #6EE7B7 | 8.99 |
| inputEnabledBorder | #E2E8F0 | #8A9BB3 | 4.84 |
| cardSurface | #FFFFFF | #222E40 | 1.00 |
| cardBorder | #E2E8F0 | #64748B | 2.88 |
| mutedSurface | #F1F5F9 | #2A384D | 1.16 |
| background | #F8FAFC | #080E1A | 1.41 |
| divider | #E2E8F0 | #64748B | 2.88 |
| inputBorder | #CBD5E1 | #8A9BB3 | 4.84 |
| textPrimary | #0F172A | #F8FAFC | 13.09 |
| textBody | #334155 | #CBD5E1 | 9.23 |
| textSecondary | #64748B | #B3BED0 | 7.30 |
| hint | #94A3B8 | #B3BED0 | 7.30 |
| accent | #47667B | #93B5CE | 6.36 |
| navInactive | #94A3B8 | #B3BED0 | 7.30 |
| emphasis | #0F172A | #E5D99B | 9.61 |
| primaryContainer | #FFFCE6 | #2C2706 | 1.09 |
| primaryContainerBorder | #FFDE02 alpha=0.500 | #7C7145 | 2.81 |
| onPrimaryContainer | #0F172A | #FEF3C7 | 12.30 |
| successContainer | #ECFDF5 | #064E3B | 1.41 |
| onSuccessContainer | #059669 | #6EE7B7 | 8.99 |
| infoContainer | #DBEAFE | #1E2838 | 1.08 |
| onInfoContainer | #1D4ED8 | #93C5FD | 7.60 |
| infoText | #2563EB | #60A5FA | 5.39 |
| warningContainer | #FEF3C7 | #45320C | 1.12 |
| onWarningContainer | #92400E | #FCD68A | 9.87 |
| aiContainer | #FEF3C7 | #2C2706 | 1.09 |
| onAiContainer | #92400E | #FEF3C7 | 12.30 |
| aiAccent | #B45309 | #E5D99B | 9.61 |
| success | #10B981 | #6EE7B7 | 8.99 |
| error | #EF4444 | #FCA5A5 | 7.22 |
| info | #3B82F6 | #60A5FA | 5.39 |
| warning | #F59E0B | #FCD68A | 9.87 |
| errorContainer | #FEE2E2 | #451A1A | 1.08 |
| onErrorContainer | #DC2626 | #FCA5A5 | 7.22 |
| chartLine | #A855F7 | #C084FC | 5.18 |
| chartBand | #A855F7 alpha=0.200 | #C084FC alpha=0.200 | 1.39 |
| chartLowest | #059669 | #34D399 | 7.13 |
| selectedChip | #0F172A | #FFDE02 | 10.24 |
| onSelectedChip | #FFFFFF | #0F172A | 1.30 |
| aiBody | #334155 | #FEF3C7 | 12.30 |
| mutedText | #47667B | #CBD5E1 | 9.23 |
| snackbarSuccess | #10B981 | #064E3B | 1.41 |
| onSnackbarSuccess | #FFFFFF | #6EE7B7 | 8.99 |
| shopeeBrand | #EE4D2D | #FFAA93 | 7.45 |
| lazadaBrand | #0F146D | #BCBFFF | 7.85 |
| shopeeButton | #EE4D2D | #EE4D2D | 3.74 |
| lazadaButton | #0F146D | #0F146D | 1.14 |
| onBrandButton | #FFFFFF | #0F172A | 1.30 |
| savingsText | #047857 | #6EE7B7 | 8.99 |
| budgetActionBorder | #EAB308 | #64748B | 2.88 |
| onboardingGradientStart | #FFF3B0 | #2C2706 | 1.09 |
| onboardingGradientEnd | #F1F6F2 | #222E40 | 1.00 |
| illustrationSurface | #FFFFFF | #2A384D | 1.16 |
| illustrationInset | #E8F1ED | #263B31 | 1.14 |
| illustrationBadge | #263B1E | #FFDE02 | 10.24 |
| illustrationBadgeBorder | #E6F1EC | #2A384D | 1.16 |
| onboardingBorder | #E8EDF2 | #64748B | 2.88 |
| comparisonSurface | #0F172A | #2A384D | 1.16 |
| comparisonHint | #94A3B8 | #B3BED0 | 7.30 |
| switchTrack | #0F172A | #7C7145 | 2.81 |
| secondaryActionBorder | #CBD5E1 | #8A9BB3 | 4.84 |
| secondaryActionText | #64748B | #CBD5E1 | 9.23 |
| subtleText | #64748B alpha=0.700 | #B3BED0 | 7.30 |
| appBarSurface | #FFFFFF | #080E1A | 1.41 |
| budgetCardShadow | #000000 alpha=0.030 | #000000 alpha=0.200 | 1.13 |
| summaryCardShadow | #000000 alpha=0.020 | #000000 alpha=0.200 | 1.13 |
| illustrationShadow | #000000 alpha=0.080 | #000000 alpha=0.300 | 1.19 |
| illustrationBadgeShadow | #000000 alpha=0.100 | #000000 alpha=0.200 | 1.13 |
| budgetCardShadow5 | #000000 alpha=0.035 | #000000 alpha=0.160 | 1.10 |
| previewShadow | #000000 alpha=0.040 | #000000 alpha=0.300 | 1.19 |
| segmentShadow | #000000 alpha=0.060 | #000000 alpha=0.300 | 1.19 |
| statusOverlay | #000000 alpha=0.100 | #000000 alpha=0.150 | 1.10 |
| insightOverlay | #000000 alpha=0.100 | #000000 alpha=0.200 | 1.13 |
| brandShadow | #000000 alpha=0.050 | #000000 alpha=0.080 | 1.05 |
| photoStatusContainer | #ECFDF5 | #2A384D | 1.16 |
| onStatusFill | #FFFFFF | #0F172A | 1.30 |
| notificationBadge | #EF4444 | #451A1A | 1.08 |
| onNotificationBadge | #FFFFFF | #FCA5A5 | 7.22 |
| brandText | #FFDE02 | #E5D99B | 9.61 |
| slotMorning | #3B82F6 | #93C5FD | 7.60 |
| slotNoon | #10B981 | #6EE7B7 | 8.99 |
| slotEvening | #F59E0B | #E5D99B | 9.61 |
| slotNight | #6366F1 | #BCBFFF | 7.85 |
| chartStrong | #1E293B | #CBD5E1 | 9.23 |
| statusNeutral | #47667B | #B3BED0 | 7.30 |
| captionText | #64748B alpha=0.800 | #B3BED0 | 7.30 |
| chartGuide | #64748B alpha=0.500 | #8A9BB3 | 4.84 |
| chartSelection | #0F172A alpha=0.350 | #8A9BB3 | 4.84 |

## Inventory trước sửa: vị trí và cách thay

Số dòng là vị trí **trước sửa** ngày 10/11. Mỗi hàng là một lần xuất hiện màu cứng, biến/nhánh theme hoặc control cần kiểm tra.

| File:dòng | Mã trước sửa | Token/cách xử lý |
|---|---|---|
| lib/screens/add_item_screen.dart:222 | ScaffoldMessenger.of(context).showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/add_item_screen.dart:223 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/add_item_screen.dart:238 | ..hideCurrentSnackBar() | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/add_item_screen.dart:239 | ..showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/add_item_screen.dart:240 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/add_item_screen.dart:259 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/add_item_screen.dart:265 | backgroundColor: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/add_item_screen.dart:385 | color: const Color(0xFFEE4D2D) | shopeeBrand/lazadaBrand + onBrandButton |
| lib/screens/add_item_screen.dart:394 | color: Color(0xFFEE4D2D), | shopeeBrand/lazadaBrand + onBrandButton |
| lib/screens/budget_screen.dart:29 | showDialog( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/budget_screen.dart:78 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/budget_screen.dart:83 | backgroundColor: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/budget_screen.dart:526 | showDialog<void>( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/compare_items_screen.dart:31 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/compare_items_screen.dart:36 | backgroundColor: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/dev/widget_gallery_screen.dart:116 | onPressed: () => showUndoSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/email_verification_screen.dart:111 | ScaffoldMessenger.of(context).showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/email_verification_screen.dart:112 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/email_verification_screen.dart:127 | ScaffoldMessenger.of(context).showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/email_verification_screen.dart:128 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/extension_qr_scan_screen.dart:82 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/extension_qr_scan_screen.dart:87 | backgroundColor: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/feedback_screen.dart:40 | messenger.showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/feedback_screen.dart:41 | const SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/feedback_screen.dart:55 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/feedback_screen.dart:60 | backgroundColor: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/history_screen.dart:28 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/history_screen.dart:44 | backgroundColor: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/history_screen.dart:299 | color: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/history_screen.dart:364 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/history_screen.dart:403 | ? (isDark ? const Color(0xFFEF4444) : AppColors.outline) | Ngân sách vượt mốc: mutedSurface/accent/secondaryActionBorder (trung tính) |
| lib/screens/history_screen.dart:409 | color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03), | Token shadow/overlay theo vai trò, giữ alpha light |
| lib/screens/history_screen.dart:428 | color: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/history_screen.dart:453 | ? (isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/history_screen.dart:454 | ? const Color(0xFF451A1A) | Ngân sách vượt mốc: mutedSurface/accent/secondaryActionBorder (trung tính) |
| lib/screens/history_screen.dart:456 | : (isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/history_screen.dart:457 | ? const Color(0xFF064E3B) | successContainer / onSuccessContainer |
| lib/screens/history_screen.dart:467 | ? (isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/history_screen.dart:468 | ? const Color(0xFFFCA5A5) | Ngân sách vượt mốc: mutedSurface/accent/secondaryActionBorder (trung tính) |
| lib/screens/history_screen.dart:470 | : (isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/history_screen.dart:471 | ? const Color(0xFF6EE7B7) | successContainer / onSuccessContainer |
| lib/screens/history_screen.dart:497 | color: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/history_screen.dart:507 | color: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/history_screen.dart:531 | color: isDark ? AppColors.primary : AppColors.accentNeutral, | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/history_screen.dart:560 | backgroundColor: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/history_screen.dart:561 | ? const Color(0xFF262D3B) | mutedSurface |
| lib/screens/history_screen.dart:564 | ? (isDark ? const Color(0xFFEF4444) : AppColors.accentNeutral) | Ngân sách vượt mốc: mutedSurface/accent/secondaryActionBorder (trung tính) |
| lib/screens/history_screen.dart:595 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/history_screen.dart:598 | ? (isDark ? AppColors.primary : AppColors.onPrimary) | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/history_screen.dart:599 | : (isDark ? const Color(0xFF252D3C) : AppColors.surfaceVariant); | mutedSurface |
| lib/screens/history_screen.dart:602 | ? (isDark ? AppColors.onPrimary : Colors.white) | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/history_screen.dart:603 | : (isDark ? const Color(0xFFCBD5E1) : AppColors.accentNeutral); | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/history_screen.dart:606 | ? (isDark ? AppColors.onPrimary : Colors.white) | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/history_screen.dart:607 | : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary); | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/history_screen.dart:646 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/history_screen.dart:716 | color: isDark ? AppColors.primary : AppColors.accentNeutral, | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/home_screen.dart:35 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/home_screen.dart:42 | backgroundColor: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/home_screen.dart:172 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/home_screen.dart:184 | color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02), | Token shadow/overlay theo vai trò, giữ alpha light |
| lib/screens/home_screen.dart:272 | color: isDark ? AppColors.primary : AppColors.accentNeutral, | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/home_screen.dart:375 | color: isDark ? AppColors.primary : AppColors.accentNeutral, | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/home_screen.dart:408 | ? (isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/home_screen.dart:409 | ? const Color(0xFF451A1A) | Ngân sách vượt mốc: mutedSurface/accent/secondaryActionBorder (trung tính) |
| lib/screens/home_screen.dart:411 | : (isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/home_screen.dart:412 | ? const Color(0xFF064E3B) | successContainer / onSuccessContainer |
| lib/screens/home_screen.dart:422 | ? (isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/home_screen.dart:423 | ? const Color(0xFFFCA5A5) | Ngân sách vượt mốc: mutedSurface/accent/secondaryActionBorder (trung tính) |
| lib/screens/home_screen.dart:425 | : (isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/home_screen.dart:426 | ? const Color(0xFF6EE7B7) | successContainer / onSuccessContainer |
| lib/screens/home_screen.dart:452 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/home_screen.dart:470 | color: isDark ? AppColors.primary : AppColors.onPrimary, | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/home_screen.dart:559 | side: const BorderSide(color: Color(0xFFEAB308), width: 1), | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/home_screen.dart:582 | side: const BorderSide(color: Color(0xFFEAB308), width: 1), | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/home_screen.dart:602 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/home_screen.dart:653 | color: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/home_screen.dart:661 | color: isDark ? AppColors.primary : AppColors.accentNeutral, | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/home_screen.dart:709 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/home_screen.dart:811 | color: isDark ? AppColors.primary : AppColors.accentNeutral, | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/info_text_screen.dart:18 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/info_text_screen.dart:23 | backgroundColor: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/insights_screen.dart:28 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/insights_screen.dart:69 | color: isDark ? AppColors.primary : AppColors.onPrimary, | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/insights_screen.dart:98 | foregroundColor: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/insights_screen.dart:196 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/insights_screen.dart:212 | color: isDark ? const Color(0xFF2C2706) : AppColors.primaryContainer, | primaryContainer/aiContainer và onPrimaryContainer/onAiContainer |
| lib/screens/insights_screen.dart:215 | color: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/insights_screen.dart:216 | ? const Color(0xFF5E5410) | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/insights_screen.dart:227 | color: isDark ? AppColors.primary : AppColors.aiAccent, | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/insights_screen.dart:237 | color: isDark ? AppColors.primary : AppColors.onPrimary, | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/insights_screen.dart:241 | Switch( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/insights_screen.dart:245 | activeTrackColor: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/insights_screen.dart:266 | color: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/insights_screen.dart:267 | ? const Color(0xFFFEF3C7) | primaryContainer/aiContainer và onPrimaryContainer/onAiContainer |
| lib/screens/insights_screen.dart:278 | foregroundColor: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/insights_screen.dart:291 | color: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/insights_screen.dart:292 | ? const Color(0xFF93B5CE) | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/insights_screen.dart:328 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/insights_screen.dart:348 | color: color.withValues(alpha: isDark ? 0.2 : 0.1), | Token shadow/overlay theo vai trò, giữ alpha light |
| lib/screens/item_detail_screen.dart:80 | ..hideCurrentSnackBar() | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/item_detail_screen.dart:81 | ..showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/item_detail_screen.dart:82 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/item_detail_screen.dart:117 | ..hideCurrentSnackBar() | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/item_detail_screen.dart:118 | ..showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/item_detail_screen.dart:119 | SnackBar(content: Text(message), behavior: SnackBarBehavior.floating), | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/item_detail_screen.dart:130 | showUndoSnackBar(context, 'Đã bỏ qua "${item.title}".', () { | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/item_detail_screen.dart:143 | ..hideCurrentSnackBar() | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/item_detail_screen.dart:144 | ..showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/item_detail_screen.dart:145 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/item_detail_screen.dart:168 | ..hideCurrentSnackBar() | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/item_detail_screen.dart:169 | ..showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/item_detail_screen.dart:170 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/item_detail_screen.dart:186 | ..hideCurrentSnackBar() | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/item_detail_screen.dart:187 | ..showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/item_detail_screen.dart:188 | const SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/item_detail_screen.dart:218 | ..hideCurrentSnackBar() | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/item_detail_screen.dart:219 | ..showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/item_detail_screen.dart:220 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/item_detail_screen.dart:248 | ..hideCurrentSnackBar() | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/item_detail_screen.dart:249 | ..showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/item_detail_screen.dart:250 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/item_detail_screen.dart:275 | ..hideCurrentSnackBar() | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/item_detail_screen.dart:276 | ..showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/item_detail_screen.dart:277 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/item_detail_screen.dart:324 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/item_detail_screen.dart:329 | backgroundColor: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/item_detail_screen.dart:505 | color: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/item_detail_screen.dart:513 | color: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/item_detail_screen.dart:717 | backgroundColor: const Color(0xFF10B981), // Emerald green | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/item_detail_screen.dart:739 | backgroundColor: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/item_detail_screen.dart:740 | ? const Color(0xFF262D37) | mutedSurface |
| lib/screens/item_detail_screen.dart:741 | : const Color(0xFFF1F5F9), // Slate neutral | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/item_detail_screen.dart:742 | foregroundColor: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/item_detail_screen.dart:743 | ? const Color(0xFFCBD5E1) | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/item_detail_screen.dart:744 | : const Color(0xFF64748B), | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/item_detail_screen.dart:745 | borderColor: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/item_detail_screen.dart:746 | ? const Color(0xFF3E4856) | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/item_detail_screen.dart:747 | : const Color(0xFFCBD5E1), | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/item_detail_screen.dart:966 | ? const Color(0xFF10B981) | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/item_detail_screen.dart:979 | ? const Color(0xFF10B981) | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/item_detail_screen.dart:1032 | color: const Color(0xFF10B981) | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/item_detail_screen.dart:1040 | color: Color(0xFF10B981), | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/item_detail_screen.dart:1065 | ? const Color(0xFF10B981) | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/item_detail_screen.dart:1079 | color: const Color(0xFF10B981).withValues(alpha: 0.1), | Token shadow/overlay theo vai trò, giữ alpha light |
| lib/screens/item_detail_screen.dart:1086 | color: Color(0xFF10B981), | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/item_detail_screen.dart:1094 | color: const Color(0xFF047857), | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/login_screen.dart:473 | ScaffoldMessenger.of(context).showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/login_screen.dart:474 | const SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/main_navigation_screen.dart:112 | ScaffoldMessenger.of(context).showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/main_navigation_screen.dart:113 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/main_navigation_screen.dart:220 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/main_navigation_screen.dart:223 | final selectedColor = isDark ? AppColors.primary : AppColors.onPrimary; | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/main_navigation_screen.dart:224 | final unselectedColor = isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/main_navigation_screen.dart:225 | ? const Color(0xFF64748B) | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/monthly_reflection_screen.dart:39 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/monthly_reflection_screen.dart:44 | backgroundColor: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/monthly_reflection_screen.dart:283 | messenger.showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/monthly_reflection_screen.dart:284 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/monthly_reflection_screen.dart:293 | messenger.showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/monthly_reflection_screen.dart:294 | SnackBar(content: Text('Đã lưu chiêm nghiệm tháng ${vm.month.month}')), | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/onboarding_screen.dart:193 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/onboarding_screen.dart:208 | colors: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:209 | ? const [Color(0xFF3B3212), Color(0xFF1F2937)] | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:210 | : const [Color(0xFFFFF3B0), Color(0xFFF1F6F2)], | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:220 | color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08), | Token shadow/overlay theo vai trò, giữ alpha light |
| lib/screens/onboarding_screen.dart:236 | color: isDark ? const Color(0xFF344A3D) : Colors.white, | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:241 | alpha: isDark ? 0.2 : 0.1, | Token shadow/overlay theo vai trò, giữ alpha light |
| lib/screens/onboarding_screen.dart:253 | color: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:254 | ? const Color(0xFF263B31) | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:255 | : const Color(0xFFE8F1ED), | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:261 | color: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:275 | color: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:277 | : const Color(0xFF263B1E), | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:280 | color: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:281 | ? const Color(0xFF344A3D) | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:282 | : const Color(0xFFE6F1EC), | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:289 | color: isDark ? AppColors.onPrimary : Colors.white, | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:305 | color: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:306 | ? const Color(0xFF2C2706) | primaryContainer/aiContainer và onPrimaryContainer/onAiContainer |
| lib/screens/onboarding_screen.dart:316 | color: isDark ? AppColors.primary : AppColors.onPrimary, | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:380 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/onboarding_screen.dart:385 | color: isDark ? const Color(0xFF1B2535) : Colors.white, | cardSurface (darkSurface duy nhất) |
| lib/screens/onboarding_screen.dart:388 | color: isDark ? const Color(0xFF334155) : const Color(0xFFE8EDF2), | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:392 | color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.035), | Token shadow/overlay theo vai trò, giữ alpha light |
| lib/screens/onboarding_screen.dart:404 | color: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:405 | ? const Color(0xFF3B3212) | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:412 | color: isDark ? AppColors.primaryLight : AppColors.onPrimary, | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:448 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/onboarding_screen.dart:463 | color: isDark ? const Color(0xFF1B202A) : Colors.white, | cardSurface (darkSurface duy nhất) |
| lib/screens/onboarding_screen.dart:468 | color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04), | Token shadow/overlay theo vai trò, giữ alpha light |
| lib/screens/onboarding_screen.dart:484 | color: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:485 | ? const Color(0xFF252D3C) | mutedSurface |
| lib/screens/onboarding_screen.dart:522 | color: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:523 | ? const Color(0xFF60A5FA) | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:524 | : const Color(0xFF2563EB), | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:536 | color: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:537 | ? const Color(0xFF1E2838) | infoContainer / onInfoContainer |
| lib/screens/onboarding_screen.dart:538 | : const Color(0xFFDBEAFE), | infoContainer / onInfoContainer |
| lib/screens/onboarding_screen.dart:546 | color: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:547 | ? const Color(0xFF93C5FD) | infoContainer / onInfoContainer |
| lib/screens/onboarding_screen.dart:548 | : const Color(0xFF1D4ED8), | infoContainer / onInfoContainer |
| lib/screens/onboarding_screen.dart:566 | isDark: isDark, | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:572 | color: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:573 | ? const Color(0xFF94A3B8) | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:575 | isDark: isDark, | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:589 | color: isDark ? const Color(0xFF1E2838) : const Color(0xFFDBEAFE), | infoContainer / onInfoContainer |
| lib/screens/onboarding_screen.dart:598 | color: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:599 | ? const Color(0xFF93C5FD) | infoContainer / onInfoContainer |
| lib/screens/onboarding_screen.dart:600 | : const Color(0xFF1D4ED8), | infoContainer / onInfoContainer |
| lib/screens/onboarding_screen.dart:639 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/onboarding_screen.dart:654 | color: isDark ? const Color(0xFF1B202A) : Colors.white, | cardSurface (darkSurface duy nhất) |
| lib/screens/onboarding_screen.dart:659 | color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04), | Token shadow/overlay theo vai trò, giữ alpha light |
| lib/screens/onboarding_screen.dart:678 | color: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:699 | color: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:700 | ? const Color(0xFF064E3B) | successContainer / onSuccessContainer |
| lib/screens/onboarding_screen.dart:709 | color: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:710 | ? const Color(0xFF6EE7B7) | successContainer / onSuccessContainer |
| lib/screens/onboarding_screen.dart:725 | backgroundColor: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:726 | ? const Color(0xFF262D3B) | mutedSurface |
| lib/screens/onboarding_screen.dart:738 | color: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:739 | ? const Color(0xFF2C2706) | primaryContainer/aiContainer và onPrimaryContainer/onAiContainer |
| lib/screens/onboarding_screen.dart:748 | color: isDark ? AppColors.primary : AppColors.aiAccent, | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:758 | color: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:759 | ? const Color(0xFFFEF3C7) | primaryContainer/aiContainer và onPrimaryContainer/onAiContainer |
| lib/screens/onboarding_screen.dart:777 | color: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:778 | ? const Color(0xFF064E3B) | successContainer / onSuccessContainer |
| lib/screens/onboarding_screen.dart:788 | color: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:789 | ? const Color(0xFF6EE7B7) | successContainer / onSuccessContainer |
| lib/screens/onboarding_screen.dart:831 | required bool isDark, | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/onboarding_screen.dart:836 | color: color.withValues(alpha: isDark ? 0.15 : 0.1), | Token shadow/overlay theo vai trò, giữ alpha light |
| lib/screens/patterns_screen.dart:60 | final picked = await showDatePicker( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/patterns_screen.dart:84 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/patterns_screen.dart:138 | color: isDark ? const Color(0xFF252D3C) : AppColors.divider, | mutedSurface |
| lib/screens/patterns_screen.dart:289 | color: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/patterns_screen.dart:309 | color: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/patterns_screen.dart:310 | ? const Color(0xFF2C2706) | primaryContainer/aiContainer và onPrimaryContainer/onAiContainer |
| lib/screens/patterns_screen.dart:316 | color: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/patterns_screen.dart:414 | color: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/patterns_screen.dart:460 | backgroundColor: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/patterns_screen.dart:461 | ? const Color(0xFF262D3B) | mutedSurface |
| lib/screens/patterns_screen.dart:525 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/patterns_screen.dart:535 | ? (isDark ? const Color(0xFF1B202A) : Colors.white) | cardSurface (darkSurface duy nhất) |
| lib/screens/patterns_screen.dart:541 | color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06), | Token shadow/overlay theo vai trò, giữ alpha light |
| lib/screens/patterns_screen.dart:555 | ? (isDark ? AppColors.primary : AppColors.onPrimary) | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/patterns_screen.dart:572 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/patterns_screen.dart:605 | backgroundColor: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/patterns_screen.dart:606 | ? const Color(0xFF262D3B) | mutedSurface |
| lib/screens/photo_search_screen.dart:150 | ..hideCurrentSnackBar() | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/photo_search_screen.dart:151 | ..showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/photo_search_screen.dart:152 | SnackBar(content: Text(message), behavior: SnackBarBehavior.floating), | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/photo_search_screen.dart:173 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/photo_search_screen.dart:178 | backgroundColor: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/photo_search_screen.dart:1160 | color: theme.brightness == Brightness.dark | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/pre_purchase_result_screen.dart:119 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/pre_purchase_result_screen.dart:124 | backgroundColor: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/pre_purchase_screen.dart:141 | backgroundColor: Theme.of(context).brightness == Brightness.dark | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/profile_screen.dart:38 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/profile_screen.dart:46 | backgroundColor: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/profile_screen.dart:123 | isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/profile_screen.dart:129 | child: Switch( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/profile_screen.dart:130 | value: isDark, | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/profile_screen.dart:256 | color: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/profile_screen.dart:257 | ? const Color(0xFF2C2706) | primaryContainer/aiContainer và onPrimaryContainer/onAiContainer |
| lib/screens/profile_screen.dart:264 | color: isDark ? AppColors.primary : AppColors.onPrimary, | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/profile_screen.dart:413 | ScaffoldMessenger.of(context).showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/profile_screen.dart:414 | const SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/profile_screen.dart:454 | messenger.showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/profile_screen.dart:455 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/profile_screen.dart:588 | void show(String text) => messenger.showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/profile_screen.dart:589 | SnackBar(content: Text(text), behavior: SnackBarBehavior.floating), | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/profile_screen.dart:625 | messenger.showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/profile_screen.dart:626 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/profile_screen.dart:652 | messenger.showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/profile_screen.dart:653 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/profile_screen.dart:818 | messenger.showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/profile_screen.dart:819 | const SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/profile_screen.dart:874 | child: Switch( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/profile_screen.dart:945 | final grant = await showDialog<bool>( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/profile_screen.dart:992 | messenger.showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/profile_screen.dart:993 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/profile_screen.dart:1008 | messenger.hideCurrentSnackBar(); | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/profile_screen.dart:1048 | child: Switch( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/profile_screen.dart:1194 | ScaffoldMessenger.of(context).showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/profile_screen.dart:1195 | const SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/profile_screen.dart:1229 | ScaffoldMessenger.of(context).showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/profile_screen.dart:1230 | const SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/profile_screen.dart:1463 | messenger.showSnackBar(SnackBar(content: Text(text))); | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/purchase_detail_screen.dart:56 | messenger.hideCurrentSnackBar(); | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/purchase_detail_screen.dart:58 | messenger.showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/purchase_detail_screen.dart:59 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/purchase_detail_screen.dart:75 | messenger.showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/purchase_detail_screen.dart:76 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/purchase_detail_screen.dart:94 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/purchase_detail_screen.dart:99 | backgroundColor: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/record_purchase_screen.dart:126 | ScaffoldMessenger.of(context).showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/record_purchase_screen.dart:127 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/record_purchase_screen.dart:139 | final date = await showDatePicker( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/record_purchase_screen.dart:246 | ScaffoldMessenger.of(context).showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/record_purchase_screen.dart:247 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/record_purchase_screen.dart:302 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/record_purchase_screen.dart:315 | backgroundColor: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/record_purchase_screen.dart:643 | showDialog<void>( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/reminder_permission_screen.dart:39 | messenger.showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/reminder_permission_screen.dart:40 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/sale_screens.dart:56 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/sale_screens.dart:61 | backgroundColor: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/sale_screens.dart:150 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/sale_screens.dart:155 | backgroundColor: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/sale_screens.dart:289 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/sale_screens.dart:294 | backgroundColor: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/sale_screens.dart:451 | ..hideCurrentSnackBar() | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/sale_screens.dart:452 | ..showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/sale_screens.dart:453 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/shopping_profile_screen.dart:39 | messenger.showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/shopping_profile_screen.dart:40 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/shopping_profile_screen.dart:56 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/shopping_profile_screen.dart:61 | backgroundColor: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/shopping_profile_screen.dart:197 | messenger.showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/shopping_profile_screen.dart:198 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/screens/wishlist_screen.dart:90 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/wishlist_screen.dart:98 | backgroundColor: isDark | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/wishlist_screen.dart:420 | final isDark = Theme.of(context).brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/screens/wishlist_screen.dart:449 | color: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A), | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/wishlist_screen.dart:457 | color: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A), | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/screens/wishlist_screen.dart:520 | color: Color(0xFF94A3B8), | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/widgets/app_bottom_sheet.dart:17 | return showModalBottomSheet<T>( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/app_header_actions.dart:17 | final isDark = Theme.of(context).brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/widgets/app_header_actions.dart:21 | final iconColor = isDark ? AppColors.primary : AppColors.onPrimary; | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/widgets/app_header_actions.dart:113 | showModalBottomSheet<void>( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/app_header_actions.dart:168 | messenger.showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/app_header_actions.dart:169 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/budget_setting_sheet.dart:74 | ..hideCurrentSnackBar() | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/budget_setting_sheet.dart:75 | ..showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/budget_setting_sheet.dart:76 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/buy_intent_section.dart:125 | ScaffoldMessenger.of(context).showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/buy_intent_section.dart:126 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/confirm_dialog.dart:20 | final result = await showDialog<bool>( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/extension_approval_dialog.dart:15 | return showDialog<bool>( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/linked_devices_section.dart:73 | messenger.showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/linked_devices_section.dart:74 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/linked_devices_section.dart:93 | messenger.showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/linked_devices_section.dart:94 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/linked_devices_section.dart:121 | ScaffoldMessenger.of(context).showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/linked_devices_section.dart:122 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/month_picker_sheet.dart:19 | return showModalBottomSheet<DateTime>( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/motive_chip.dart:29 | final isDark = Theme.of(context).brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/widgets/motive_chip.dart:32 | ? (isDark ? AppColors.textPrimary : AppColors.textOnDark) | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/widgets/price_history_chart.dart:97 | Color priceLineColor(ThemeData theme) => theme.brightness == Brightness.dark | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/widgets/price_history_chart.dart:102 | Color lowestDotColor(ThemeData theme) => theme.brightness == Brightness.dark | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/widgets/price_history_chart.dart:1110 | ?..hideCurrentSnackBar() | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/price_history_chart.dart:1111 | ..showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/price_history_chart.dart:1112 | SnackBar(content: Text(text), behavior: SnackBarBehavior.floating), | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/price_history_demo_section.dart:118 | messenger.showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/price_history_demo_section.dart:119 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/price_history_demo_section.dart:145 | messenger.showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/price_history_demo_section.dart:146 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/price_history_demo_section.dart:171 | messenger.showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/price_history_demo_section.dart:172 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/price_history_demo_section.dart:200 | messenger.showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/price_history_demo_section.dart:201 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/review_date_sheet.dart:60 | final picked = await showDatePicker( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/same_product_card.dart:43 | showUndoSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/same_product_card.dart:50 | ..hideCurrentSnackBar() | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/same_product_card.dart:51 | ..showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/same_product_card.dart:52 | const SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/satisfaction_dialog.dart:22 | final answer = await showDialog<({int? stars})>( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/satisfaction_dialog.dart:31 | ..hideCurrentSnackBar() | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/satisfaction_dialog.dart:32 | ..showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/satisfaction_dialog.dart:33 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/section_card.dart:25 | final isDark = theme.brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/widgets/section_card.dart:46 | color: isDark ? AppColors.primary : AppColors.onPrimary, | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/widgets/shared_price_section.dart:118 | _SharingSwitch(item: widget.item), | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/shared_price_section.dart:218 | const _SharingSwitch({required this.item}); | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/undo_snack_bar.dart:4 | void showUndoSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/undo_snack_bar.dart:10 | ..hideCurrentSnackBar() | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/undo_snack_bar.dart:11 | ..showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/undo_snack_bar.dart:12 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/voucher_suggestion_card.dart:73 | final isDark = Theme.of(context).brightness == Brightness.dark; | Bỏ phân nhánh màu; chỉ giữ isDark cho icon/giá trị switch ở Cá nhân |
| lib/widgets/voucher_suggestion_card.dart:74 | final cardBg = isDark ? AppColors.darkSurface : AppColors.surface; | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/widgets/voucher_suggestion_card.dart:76 | final brandColor = isShopee ? const Color(0xFFEE4D2D) : const Color(0xFF0F146D); | shopeeBrand/lazadaBrand + onBrandButton |
| lib/widgets/voucher_suggestion_card.dart:91 | color: brandColor.withValues(alpha: isDark ? 0.08 : 0.05), | Token shadow/overlay theo vai trò, giữ alpha light |
| lib/widgets/voucher_suggestion_card.dart:124 | color: isDark ? AppColors.textOnDark : AppColors.textPrimary, | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/widgets/voucher_suggestion_card.dart:165 | _buildVoucherRow(context, bestVoucher, brandColor, isDark), | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/widgets/voucher_suggestion_card.dart:171 | color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant, | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/widgets/voucher_suggestion_card.dart:182 | color: isDark ? AppColors.textOnDark : AppColors.textBody, | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/widgets/voucher_suggestion_card.dart:200 | child: _buildVoucherRow(context, v, brandColor, isDark, isSecondary: true), | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/widgets/voucher_suggestion_card.dart:213 | bool isDark, { | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/widgets/voucher_suggestion_card.dart:219 | color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant, | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/widgets/voucher_suggestion_card.dart:240 | color: isDark ? AppColors.darkSurface : AppColors.surface, | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/widgets/voucher_suggestion_card.dart:267 | color: isDark ? AppColors.textOnDark : AppColors.textBody, | AppSemanticColors theo vai trò; giữ nguyên nhánh light |
| lib/widgets/voucher_suggestion_card.dart:288 | ScaffoldMessenger.of(context).showSnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
| lib/widgets/voucher_suggestion_card.dart:289 | SnackBar( | Dark AppTheme + on-colour của control; nội dung/logic giữ nguyên |
## Thành phần và xác minh

| Thành phần | Trước | D2–D3 |
|---|---|---|
| Biểu đồ giá | Có nhánh dark cho đường/chấm, band alpha cục bộ | chartLine/chartBand/chartLowest; nhãn theo colorScheme |
| Chip động cơ | Có palette dark, chữ chip được chọn vẫn màu sáng trên nền sáng | MotiveColors theo context; onSelectedChip tối trên nền sáng |
| Badge trạng thái/AI/voucher | Nhiều nền sáng cố định, màu model light | Semantic container + on-colour; motive palette theo theme |
| SnackBar | Chủ yếu mặc định; success fill và chữ chưa ghép đúng | Dark SnackBar theme; snackbarSuccess đậm; giữ light fill |
| Bottom navigation | Nhãn chưa chọn #64748B, selected vàng | navInactive sáng hơn, emphasis dịu hơn |
| Switch / Slider | Material mặc định và track cục bộ | Dark theme rõ thumb/track/outline; thông số light giữ nguyên |
| DatePicker | Material mặc định | Dark header/day/year/today; onPrimary cho ngày chọn |
| Dialog / BottomSheet | Có theme nhưng widget riêng còn nền trắng | Surface tối chung + chữ theo theme; bỏ nền trắng cố định |
| Minh hoạ onboarding | Màu gradient/vòng tròn/viền cục bộ | Token minh hoạ theo theme; giữ nguyên hình, gradient light |

### Kiểm tra

- Chạy flutter analyze và flutter test tại thư mục app.
- Chạy lại flow/widget suite với flutter test --dart-define=TEST_DARK_THEME=true.
- test/theme/dark_contrast_test.dart: chữ trên các nền trung tính và container thực dùng, selected motive/brand/status, input ≥3, card border ≥1,5, hồi quy màu light và guard source.
- test/theme/dark_widgets_test.dart: các màn, light onboarding, chuyển theme, dialog/date picker/bottom sheet và selected chip.

### Kiểm tra trên Redmi (D4)

Chuyển Cá nhân → chế độ tối; đi qua Trang chủ, Lịch sử, Mô hình, Góc nhìn, Cá nhân, Wishlist, chi tiết món, Ngân sách và các form. Mở chọn tháng/ngày, dialog xoá, thử SnackBar; đổi system → light → dark. Đối chiếu light và kiểm tra chữ khi bật cỡ chữ lớn. Không cần xoá dữ liệu thật để thử onboarding: widget test đã mở trực tiếp màn này.

### Ngoài phạm vi

Không đổi layout, nghiệp vụ, dữ liệu/rules, AI, voucher logic, nhắc chiêm nghiệm, package, admin/web; không commit/push hoặc cài APK. Các cặp light vốn tương phản thấp được giữ theo yêu cầu không đổi light mode. Chưa xác nhận hình ảnh/hiệu năng trên Redmi.

### Kết quả kiểm tra thực tế (10/11/2026)

- **37 test theme đạt**, gồm WCAG, alpha, hồi quy màu light, 27 màn ở dark, chuyển theme và dialog/DatePicker/BottomSheet/SnackBar. Smoke test màu dùng viewport 600×1200 để tránh overflow có sẵn của font môi trường test; chưa xác nhận responsive trên Redmi. Các flow test sẵn có vẫn kiểm tra các kích thước của chúng.
- Vòng xác nhận cuối với `TEST_DARK_THEME=true`: **79 test theme + biểu đồ đều đạt**. Switch trên thẻ AI: thumb/track 3,65:1, track/nền 3,08:1; giữ màu light cũ.
- **Toàn bộ suite ở cả light và dark: 659 đạt / 4 lỗi**, tổng 663 test mỗi lần. Bốn lỗi dưới đây được tái hiện nguyên vẹn trên **bản sao độc lập của mã trước khi sửa**; không phải hồi quy của dark mode.
- Analyzer: không còn error/warning mới. Còn hai info `use_null_aware_elements` có sẵn ở `lib/viewmodels/own_price_view.dart:71,75`; không sửa file này.
- Static scan: **0** `Color(0x...)` trong screens/widgets. `isDark` chỉ còn ở Cá nhân để chọn icon và giá trị switch, không còn nhánh màu.
- Đã đối chiếu phần `lightTheme`: giữ nguyên nội dung ngoài việc đăng ký extension. Diff không có thay đổi package, dữ liệu/rules, backend hoặc admin.
- Smoke test phát hiện lỗi lifecycle có sẵn ở Wishlist: Provider chỉ được lấy lần đầu lúc `dispose`. Đã cache trong `initState`; giữ hành vi xoá bộ lọc khi rời màn.

Bốn test cũ còn lỗi trong `test/purchase_flow_test.dart`:

1. `Home bookmark opens Wishlist even inside the tab shell`: fake `SignedInAuthViewModel` thiếu getter `isAnonymous`.
2. `Home wishlist card opens Wishlist even inside the tab shell`: cùng lỗi fake trên.
3. `manual form validates required fields and saves the selected group`: RenderFlex overflow 84px trong môi trường test.
4. `confirmed buy navigates from wishlist detail to the actual purchase detail`: cùng overflow 84px.

Đối chiếu baseline: chạy riêng `purchase_flow_test.dart` trên bản sao nguồn trước sửa cho **10 đạt / đúng 4 lỗi trên**. Không sửa nghiệp vụ hoặc bố cục để xử lý các lỗi này trong D1–D3.


### File thực tế thay đổi

Các đường dẫn bên dưới tính từ thư mục app `prm393_lab03/`.

- `docs/ai-log.md`
- `docs/dark-mode-audit.md`
- `docs/design-tokens.md`
- `lib/core/utils/contrast.dart`
- `lib/screens/add_item_screen.dart`
- `lib/screens/budget_screen.dart`
- `lib/screens/compare_items_screen.dart`
- `lib/screens/dev/price_chart_gallery.dart`
- `lib/screens/dev/widget_gallery_screen.dart`
- `lib/screens/email_verification_screen.dart`
- `lib/screens/extension_qr_scan_screen.dart`
- `lib/screens/feedback_screen.dart`
- `lib/screens/history_screen.dart`
- `lib/screens/home_screen.dart`
- `lib/screens/info_text_screen.dart`
- `lib/screens/insights_screen.dart`
- `lib/screens/item_detail_screen.dart`
- `lib/screens/login_screen.dart`
- `lib/screens/main_navigation_screen.dart`
- `lib/screens/monthly_reflection_screen.dart`
- `lib/screens/onboarding_screen.dart`
- `lib/screens/patterns_screen.dart`
- `lib/screens/photo_search_screen.dart`
- `lib/screens/pre_purchase_result_screen.dart`
- `lib/screens/pre_purchase_screen.dart`
- `lib/screens/price_history_screen.dart`
- `lib/screens/profile_screen.dart`
- `lib/screens/purchase_detail_screen.dart`
- `lib/screens/record_purchase_screen.dart`
- `lib/screens/reminder_permission_screen.dart`
- `lib/screens/sale_screens.dart`
- `lib/screens/shopping_profile_screen.dart`
- `lib/screens/wishlist_screen.dart`
- `lib/theme/app_colors.dart`
- `lib/theme/app_semantic_colors.dart`
- `lib/theme/app_text_styles.dart`
- `lib/theme/app_theme.dart`
- `lib/widgets/amount_field.dart`
- `lib/widgets/app_bottom_sheet.dart`
- `lib/widgets/app_button.dart`
- `lib/widgets/app_dropdown_field.dart`
- `lib/widgets/app_header_actions.dart`
- `lib/widgets/app_text_field.dart`
- `lib/widgets/budget_bar.dart`
- `lib/widgets/budget_setting_sheet.dart`
- `lib/widgets/buy_intent_section.dart`
- `lib/widgets/confirm_dialog.dart`
- `lib/widgets/decision_card_panel.dart`
- `lib/widgets/demo_data_badge.dart`
- `lib/widgets/extension_approval_dialog.dart`
- `lib/widgets/insight_source_chip.dart`
- `lib/widgets/item_suggestions.dart`
- `lib/widgets/linked_devices_section.dart`
- `lib/widgets/money_text.dart`
- `lib/widgets/month_picker_sheet.dart`
- `lib/widgets/motive_chip.dart`
- `lib/widgets/price_chip.dart`
- `lib/widgets/price_history_chart.dart`
- `lib/widgets/price_history_demo_section.dart`
- `lib/widgets/price_history_entry_card.dart`
- `lib/widgets/price_update_sheet.dart`
- `lib/widgets/product_image.dart`
- `lib/widgets/review_date_sheet.dart`
- `lib/widgets/same_product_card.dart`
- `lib/widgets/satisfaction_dialog.dart`
- `lib/widgets/section_card.dart`
- `lib/widgets/shared_price_section.dart`
- `lib/widgets/shopee_rating_line.dart`
- `lib/widgets/states/error_view.dart`
- `lib/widgets/states/loading_view.dart`
- `lib/widgets/voucher_suggestion_card.dart`
- `lib/widgets/wishlist_card.dart`
- `test/account_header_card_test.dart`
- `test/auth_error_message_test.dart`
- `test/demo_data_separation_test.dart`
- `test/demo_price_history_test.dart`
- `test/history_price_sale_reminder_test.dart`
- `test/insights_screen_test.dart`
- `test/linked_accounts_section_test.dart`
- `test/price_history_chart_test.dart`
- `test/price_history_contribution_test.dart`
- `test/price_history_panel_test.dart`
- `test/price_history_screen_test.dart`
- `test/product_identity_test.dart`
- `test/same_product_test.dart`
- `test/shared_price_test.dart`
- `test/support/purchase_harness.dart`
- `test/support/test_theme.dart`
- `test/theme/contrast_test.dart`
- `test/theme/dark_contrast_test.dart`
- `test/theme/dark_widgets_test.dart`
- `test/widget_test.dart`
