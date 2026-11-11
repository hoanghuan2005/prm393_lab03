# Design tokens — Why I Buy?

Cập nhật 10/11/2026. Nguồn thật: lib/theme. Báo cáo trước/sau và inventory: [dark-mode-audit.md](dark-mode-audit.md).

## Quy tắc

- Screens/widgets không viết hex hoặc tự phân nhánh màu theo brightness. Dùng colorScheme, AppSemanticColors.of(context), MotiveColors.of(context).paletteOf(motive).
- Primary vàng dùng cho nền nút/chip, chữ trên vàng là onPrimary. Chữ nhấn dark dùng emphasis/brandText. Giữ ngoại lệ màu light cũ theo phạm vi D1–D3.
- Vượt ngân sách dùng mutedSurface + accent, không dùng error.
- darkTextMuted chỉ trang trí. Hint, chữ phụ, nhãn tab dùng màu đạt ≥4,5:1. Viền input dùng inputBorder ≥3:1; viền card ≥1,5:1.
- Light palette không thay đổi. AppTextStyles.*.themed(context) giữ nguyên style ở light, đổi đúng vai trò chữ ở dark; không đổi font/cỡ chữ/spacing.
- Thêm màu theo mục đích tại theme, kèm đo tương phản và kiểm thử. Không thêm màu hex vào screen/widget.

## AppColors: giá trị đang dùng

| Token | Hex |
|---|---|
| primary | #FFDE02 |
| primaryLight | #FFE84D |
| primaryContainer | #FFFCE6 |
| onPrimary | #0F172A |
| background | #F8FAFC |
| surface | #FFFFFF |
| surfaceVariant | #F1F5F9 |
| divider | #E2E8F0 |
| border | #E2E8F0 |
| outline | #CBD5E1 |
| textPrimary | #0F172A |
| textBody | #334155 |
| textSecondary | #64748B |
| textHint | #94A3B8 |
| textOnDark | #FFFFFF |
| accentNeutral | #47667B |
| navInactive | #94A3B8 |
| success | #10B981 |
| successLight | #34D399 |
| successContainer | #ECFDF5 |
| onSuccessContainer | #059669 |
| warning | #F59E0B |
| error | #EF4444 |
| errorLight | #F87171 |
| errorContainer | #FEE2E2 |
| onErrorContainer | #DC2626 |
| info | #3B82F6 |
| infoLight | #60A5FA |
| rose | #F43F5E |
| roseLight | #FB7185 |
| purple | #A855F7 |
| purpleLight | #C084FC |
| aiContainer | #FEF3C7 |
| aiAccent | #B45309 |
| onAiContainer | #92400E |
| slotMorning | #3B82F6 |
| slotNoon | #10B981 |
| slotEvening | #F59E0B |
| slotNight | #6366F1 |
| chartStrong | #1E293B |
| motiveNeed | #3B82F6 |
| motiveNeedBg | #DBEAFE |
| motiveWant | #EC4899 |
| motiveWantBg | #FCE7F3 |
| motiveSale | #F59E0B |
| motiveSaleBg | #FEF3C7 |
| motiveEmotion | #A855F7 |
| motiveEmotionBg | #F3E8FF |
| motiveSocial | #0EA5E9 |
| motiveSocialBg | #E0F2FE |
| motiveConvenience | #14B8A6 |
| motiveConvenienceBg | #CCFBF1 |
| motiveAds | #2563EB |
| motiveAdsBg | #DBEAFE |
| motiveOther | #64748B |
| motiveOtherBg | #F1F5F9 |
| darkBackground | #080E1A |
| darkSurface | #222E40 |
| darkSurfaceVariant | #2A384D |
| darkBorder | #64748B |
| darkOutline | #8A9BB3 |
| darkTextPrimary | #F8FAFC |
| darkTextSecondary | #B3BED0 |
| darkTextHint | #B3BED0 |
| darkTextMuted | #475569 |
| darkPrimaryContainer | #2C2706 |
| darkPrimaryContainerOutline | #7C7145 |
| darkPrimaryText | #E5D99B |
| darkPrimaryContainerText | #FEF3C7 |
| darkCardSurface | #222E40 |
| darkSurfaceMuted | #2A384D |
| darkIndicatorInactive | #333B49 |
| darkTextBody | #CBD5E1 |
| darkNavInactive | #B3BED0 |
| darkAccentNeutral | #93B5CE |
| darkSuccessContainer | #064E3B |
| darkOnSuccessContainer | #6EE7B7 |
| darkErrorContainer | #451A1A |
| darkOnErrorContainer | #FCA5A5 |
| darkInfoContainer | #1E2838 |
| darkOnInfoContainer | #93C5FD |
| infoContainer | #DBEAFE |
| onInfoContainer | #1D4ED8 |
| infoText | #2563EB |
## AppSemanticColors

ThemeExtension bất biến đăng ký trong cả lightTheme/darkTheme, có copyWith/lerp. of(context) theo dõi theme; fromTheme(theme) dành cho helper biểu đồ. Không cache palette ngoài build khi theme có thể đổi.

- cardSurface/cardBorder/background/mutedSurface: lớp thẻ, viền và lớp nền.
- inputBorder: viền input/outlined action; divider chỉ để phân tách, không dùng làm viền ô nhập.
- textPrimary/textBody/textSecondary/hint/navInactive: chữ đúng vai trò.
- success/info/warning/error Container + on-colour: luôn ghép cặp.
- selectedChip/onSelectedChip: nền chọn và chữ; onSelectedChip dùng cả motive chip sáng.
- chartLine/chartBand/chartLowest: nét, vùng tô, điểm giá thấp; nhãn dùng textSecondary.
- emphasis/brandText/aiAccent: nhấn dịu ở dark, giữ từng màu light cũ.
- onStatusFill/onBrandButton: chữ tối trên màu fill sáng ở dark, giữ chữ trắng light.
- notificationBadge/onNotificationBadge: nền đậm và nhãn đủ tương phản ở dark.
- illustration*, onboarding*, *Shadow, *Overlay: giữ hình minh hoạ và alpha light; thích nghi dark.

| Vai trò | Light | Dark |
|---|---|---|

| linkedAccountAccent | #4CAF50 | #6EE7B7 |
| linkedAccountText | #2E7D32 | #6EE7B7 |
| inputEnabledBorder | #E2E8F0 | #8A9BB3 |
| cardSurface | #FFFFFF | #222E40 |
| cardBorder | #E2E8F0 | #64748B |
| mutedSurface | #F1F5F9 | #2A384D |
| background | #F8FAFC | #080E1A |
| divider | #E2E8F0 | #64748B |
| inputBorder | #CBD5E1 | #8A9BB3 |
| textPrimary | #0F172A | #F8FAFC |
| textBody | #334155 | #CBD5E1 |
| textSecondary | #64748B | #B3BED0 |
| hint | #94A3B8 | #B3BED0 |
| accent | #47667B | #93B5CE |
| navInactive | #94A3B8 | #B3BED0 |
| emphasis | #0F172A | #E5D99B |
| primaryContainer | #FFFCE6 | #2C2706 |
| primaryContainerBorder | #FFDE02 / alpha 0.500 | #7C7145 |
| onPrimaryContainer | #0F172A | #FEF3C7 |
| successContainer | #ECFDF5 | #064E3B |
| onSuccessContainer | #059669 | #6EE7B7 |
| infoContainer | #DBEAFE | #1E2838 |
| onInfoContainer | #1D4ED8 | #93C5FD |
| infoText | #2563EB | #60A5FA |
| warningContainer | #FEF3C7 | #45320C |
| onWarningContainer | #92400E | #FCD68A |
| aiContainer | #FEF3C7 | #2C2706 |
| onAiContainer | #92400E | #FEF3C7 |
| aiAccent | #B45309 | #E5D99B |
| success | #10B981 | #6EE7B7 |
| error | #EF4444 | #FCA5A5 |
| info | #3B82F6 | #60A5FA |
| warning | #F59E0B | #FCD68A |
| errorContainer | #FEE2E2 | #451A1A |
| onErrorContainer | #DC2626 | #FCA5A5 |
| chartLine | #A855F7 | #C084FC |
| chartBand | #A855F7 / alpha 0.200 | #C084FC / alpha 0.200 |
| chartLowest | #059669 | #34D399 |
| selectedChip | #0F172A | #FFDE02 |
| onSelectedChip | #FFFFFF | #0F172A |
| aiBody | #334155 | #FEF3C7 |
| mutedText | #47667B | #CBD5E1 |
| snackbarSuccess | #10B981 | #064E3B |
| onSnackbarSuccess | #FFFFFF | #6EE7B7 |
| shopeeBrand | #EE4D2D | #FFAA93 |
| lazadaBrand | #0F146D | #BCBFFF |
| shopeeButton | #EE4D2D | #EE4D2D |
| lazadaButton | #0F146D | #0F146D |
| onBrandButton | #FFFFFF | #0F172A |
| savingsText | #047857 | #6EE7B7 |
| budgetActionBorder | #EAB308 | #64748B |
| onboardingGradientStart | #FFF3B0 | #2C2706 |
| onboardingGradientEnd | #F1F6F2 | #222E40 |
| illustrationSurface | #FFFFFF | #2A384D |
| illustrationInset | #E8F1ED | #263B31 |
| illustrationBadge | #263B1E | #FFDE02 |
| illustrationBadgeBorder | #E6F1EC | #2A384D |
| onboardingBorder | #E8EDF2 | #64748B |
| comparisonSurface | #0F172A | #2A384D |
| comparisonHint | #94A3B8 | #B3BED0 |
| switchTrack | #0F172A | #7C7145 |
| secondaryActionBorder | #CBD5E1 | #8A9BB3 |
| secondaryActionText | #64748B | #CBD5E1 |
| subtleText | #64748B / alpha 0.700 | #B3BED0 |
| appBarSurface | #FFFFFF | #080E1A |
| budgetCardShadow | #000000 / alpha 0.030 | #000000 / alpha 0.200 |
| summaryCardShadow | #000000 / alpha 0.020 | #000000 / alpha 0.200 |
| illustrationShadow | #000000 / alpha 0.080 | #000000 / alpha 0.300 |
| illustrationBadgeShadow | #000000 / alpha 0.100 | #000000 / alpha 0.200 |
| budgetCardShadow5 | #000000 / alpha 0.035 | #000000 / alpha 0.160 |
| previewShadow | #000000 / alpha 0.040 | #000000 / alpha 0.300 |
| segmentShadow | #000000 / alpha 0.060 | #000000 / alpha 0.300 |
| statusOverlay | #000000 / alpha 0.100 | #000000 / alpha 0.150 |
| insightOverlay | #000000 / alpha 0.100 | #000000 / alpha 0.200 |
| brandShadow | #000000 / alpha 0.050 | #000000 / alpha 0.080 |
| photoStatusContainer | #ECFDF5 | #2A384D |
| onStatusFill | #FFFFFF | #0F172A |
| notificationBadge | #EF4444 | #451A1A |
| onNotificationBadge | #FFFFFF | #FCA5A5 |
| brandText | #FFDE02 | #E5D99B |
| slotMorning | #3B82F6 | #93C5FD |
| slotNoon | #10B981 | #6EE7B7 |
| slotEvening | #F59E0B | #E5D99B |
| slotNight | #6366F1 | #BCBFFF |
| chartStrong | #1E293B | #CBD5E1 |
| statusNeutral | #47667B | #B3BED0 |
| captionText | #64748B / alpha 0.800 | #B3BED0 |
| chartGuide | #64748B / alpha 0.500 | #8A9BB3 |
| chartSelection | #0F172A / alpha 0.350 | #8A9BB3 |
## MotiveColors, typography, spacing

MotiveColors.light giữ nguyên 8 cặp AppColors.motive*. Dark dùng foreground sáng trên container đậm; mọi cặp và trạng thái selected được kiểm thử ≥4,5:1. Không dùng motive.color/backgroundColor của model để vẽ giao diện khi cần theo theme.

AppTextStyles giữ Be Vietnam Pro và các kích thước/độ đậm hiện tại (display 32/28, headline 24/20, title 18/16, body 16/14, label 14/12, caption 11). Dark bodyMedium dùng darkTextBody.

AppDimens không đổi: spacing 2/4/6/8/12/16/20/24/32/40/48, radius 8/12/16/24/999; vùng chạm tối thiểu 48dp.

Trong U1–U4, các cỡ chữ/spacing/bo góc viết trực tiếp ở screens/widgets được đưa về token hiện có. Dùng `AppTextStyles.*.themed(context)` cho màu chữ theo theme; dùng `AppTextStyles.*.withInheritedColor` khi chữ cần kế thừa foreground của nút hoặc ngữ cảnh, rồi `copyWith` nếu cần màu semantic cụ thể. Getter này giữ font, cỡ, weight, height và letterSpacing của token, bỏ màu cố định. Không dùng `onPrimary` cho chữ trên `primaryContainer`; dùng `onPrimaryContainer`.

Chi tiết ma trận render, vị trí lỗi, ngoại lệ hình học và kiểm tra trên máy thật: [ui-audit.md](ui-audit.md).

Các giới hạn tương phản đã tồn tại ở light (hint, success badge, vài motive palette) chưa sửa để bảo toàn light mode; không áp dụng chúng cho dark.
