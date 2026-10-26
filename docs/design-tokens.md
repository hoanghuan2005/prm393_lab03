# Design tokens – Why I Buy? (PRM393 Lab 3)

Nguồn: `lib/theme/` (`app_colors.dart`, `motive_colors.dart`, `app_text_styles.dart`, `app_dimens.dart`, `app_theme.dart`). Tài liệu này mô tả lại đúng giá trị trong code; khi đổi token thì sửa code trước, rồi cập nhật bảng.

## 1. Quy tắc

- **Chỉ dùng token.** Trong `lib/screens/` và `lib/widgets/` không viết `Color(0x...)`, không tự đặt cỡ chữ/khoảng cách lẻ khi đã có token. Kiểm tra: `grep -rn "Color(0x" lib/screens lib/widgets` phải ra 0 dòng.
- Màu lấy từ `AppColors.x` hoặc `Theme.of(context).colorScheme.x`; màu động cơ lấy từ `MotiveColors.of(context).paletteOf(motive)` (hoặc `motive.color` / `motive.backgroundColor`, cùng một nguồn).
- Token đặt tên theo **vai trò** (`textSecondary`, `border`, `navInactive`…), không theo màu (`grey500`).
- **Không dùng chữ/icon màu vàng (`primary`) trên nền trắng hoặc xám nhạt.** Vàng chỉ làm nền (nút, chip được chọn, thanh tiến trình), chữ trên vàng luôn là `onPrimary`.
- **Vượt ngân sách không dùng đỏ/`error`.** Dùng `surfaceVariant` (nền) + `accentNeutral` (chữ, thanh) và câu chữ "Đã vượt …".
- Cần màu mới: thêm token vào `app_colors.dart` (người phụ trách base), cập nhật bảng dưới, không viết hex tại chỗ.

## 2. Màu

### 2.1 Thương hiệu, nền, chữ

| Token | Hex | Dùng cho |
|:---|:---|:---|
| `primary` | `#FFDE02` | Nền nút chính, FAB, chip/tháng được chọn, thanh tiến trình ngân sách |
| `onPrimary` | `#070E20` | Chữ/icon trên nền vàng; viền và nền tối của mục được chọn; con trỏ, vòng tải |
| `primaryContainer` | `#FFFCE6` | Nền vàng nhạt (thẻ gợi ý, mục được chọn nhẹ) |
| `background` | `#F8F9FA` | Nền Scaffold |
| `surface` | `#FFFFFF` | Nền thẻ, AppBar, ô nhập |
| `surfaceVariant` | `#F3F4F6` | Nền xám nhạt: chip chưa chọn, rãnh thanh tiến trình, nhãn "Đã vượt mốc" |
| `divider` | `#E5E7EB` | Đường kẻ ngăn cách |
| `border` | `#E5E7EB` | Viền mảnh của thẻ, chip, ô |
| `outline` | `#D1D5DB` | Viền đậm hơn (nút viền, ô nhập mặc định, thẻ ngân sách khi đã vượt) |
| `textPrimary` | `#070E20` | Chữ chính, tiêu đề |
| `textBody` | `#374151` | Đoạn văn dài (nhận xét Góc nhìn) |
| `textSecondary` | `#6D6E73` | Chữ phụ, mô tả, nhãn |
| `textHint` | `#9CA3AF` | Gợi ý trong ô nhập, chữ mờ |
| `textOnDark` | `#FFFFFF` | Chữ trên nền tối/màu đậm |
| `accentNeutral` | `#47667B` | Nhấn trung tính: số liệu, nhãn ngân sách, trạng thái vượt mốc |
| `navInactive` | `#9CA3AF` | Icon/nhãn tab chưa chọn ở thanh điều hướng dưới |

### 2.2 Trạng thái, AI, biểu đồ

| Token | Hex | Dùng cho |
|:---|:---|:---|
| `success` | `#10B981` | SnackBar lưu thành công |
| `successContainer` / `onSuccessContainer` | `#ECFDF5` / `#059669` | Nhãn "Trong hạn mức" |
| `warning` | `#F59E0B` | Cảnh báo |
| `error` | `#EF4444` | Lỗi, nút/biểu tượng xoá, chấm thông báo — **không** dùng cho ngân sách |
| `errorContainer` / `onErrorContainer` | `#FEE2E2` / `#DC2626` | Nhãn "Bắt buộc", nền thông báo lỗi |
| `info` | `#3B82F6` | Thông tin |
| `aiContainer` | `#FEF3C7` | Nền khối/chip nhận xét do AI viết |
| `aiAccent` | `#B45309` | Icon ✨ của khối AI |
| `onAiContainer` | `#92400E` | Chữ trên chip "AI" |
| `slotMorning` / `slotNoon` / `slotEvening` / `slotNight` | `#3B82F6` / `#10B981` / `#F59E0B` / `#6366F1` | Icon khung giờ ở màn Thói quen |
| `chartStrong` | `#1F2937` | Đoạn đậm trong thanh phân bổ động cơ (Trang chủ) |

### 2.3 Tám màu động cơ (`MotiveColors`)

`ThemeExtension<MotiveColors>` đăng ký trong `AppTheme.lightTheme`; giá trị gốc nằm ở `AppColors.motive*`.

| Key | Nhãn | Chữ/icon | Nền |
|:---|:---|:---|:---|
| `need` | Nhu cầu | `#4F46E5` | `#EEF2FF` |
| `want` | Mong muốn | `#EC4899` | `#FCE7F3` |
| `sale` | Khuyến mãi | `#D97706` | `#FEF3C7` |
| `emotion` | Cảm xúc | `#7C3AED` | `#EDE9FE` |
| `social` | Ảnh hưởng MXH | `#0284C7` | `#E0F2FE` |
| `convenience` | Tiện lợi | `#0D9488` | `#CCFBF1` |
| `ads` | Quảng cáo | `#2563EB` | `#DBEAFE` |
| `other` | Khác | `#64748B` | `#F1F5F9` |

### 2.4 ColorScheme (Material 3)

`primary`=`primary`, `onPrimary`=`onPrimary`, `primaryContainer`=`primaryContainer`, `secondary`=`onPrimary`, `secondaryContainer`=`primaryContainer`, `tertiary`=`accentNeutral`, `error`/`errorContainer`/`onErrorContainer`, `surface`, `onSurface`=`textPrimary`, `onSurfaceVariant`=`textSecondary`, `surfaceContainerHighest`=`surfaceVariant`, `outline`=`outline`, `outlineVariant`=`divider`, `inverseSurface`=`onPrimary`.

Theme thành phần để widget mặc định không ra chữ vàng trên trắng: `TextButton` chữ `onPrimary`; `ProgressIndicator` màu `onPrimary`, rãnh `surfaceVariant`; con trỏ/tay chọn chữ `onPrimary`; FAB nền `primary` chữ `onPrimary`.

## 3. Typography

Font **Be Vietnam Pro** (`google_fonts`), khai báo ở `AppTextStyles`.

| Style | Cỡ | Độ đậm | Line height | Màu |
|:---|:-:|:-:|:-:|:---|
| `displayLarge` | 32 | 700 | 1.25 | textPrimary |
| `displayMedium` | 28 | 700 | 1.3 | textPrimary |
| `headlineLarge` | 24 | 700 | 1.3 | textPrimary |
| `headlineMedium` | 20 | 600 | 1.35 | textPrimary |
| `titleLarge` | 18 | 600 | 1.35 | textPrimary |
| `titleMedium` | 16 | 600 | 1.4 | textPrimary |
| `bodyLarge` | 16 | 400 | 1.45 | textPrimary |
| `bodyMedium` | 14 | 400 | 1.45 | textSecondary |
| `labelLarge` | 14 | 600 | 1.4 | textPrimary |
| `labelMedium` | 12 | 500 | 1.35 | textSecondary |
| `caption` | 11 | 500 | — (letterSpacing 0.5) | textSecondary |

## 4. Spacing, radius, elevation (`AppDimens`)

- **Spacing:** `space2` 2 · `space4` 4 · `space6` 6 · `space8` 8 · `space12` 12 · `space16` 16 · `space20` 20 · `space24` 24 · `space32` 32 · `space40` 40 · `space48` 48.
- **Radius:** `radiusSmall` 8 · `radiusMedium` 12 · `radiusLarge` 16 · `radiusXLarge` 24 · `radiusPill` 999 (kèm `borderSmall`…`borderPill`).
- **Elevation:** `elevationNone` 0 · `elevationLow` 1 · `elevationMedium` 3 · `elevationHigh` 6.
- **Vùng chạm tối thiểu:** `minTouchTarget` 48.

## 5. Tương phản (WCAG 2.1 AA, chữ thường ≥ 4,5:1)

| Cặp | Tỉ lệ | Kết quả |
|:---|:-:|:---|
| `onPrimary` #070E20 trên `primary` #FFDE02 | 14,37 | Đạt |
| `textPrimary` trên trắng | 19,22 | Đạt |
| `textBody` trên trắng | 10,31 | Đạt |
| `textSecondary` trên trắng / trên `background` | 5,09 / 4,83 | Đạt |
| `accentNeutral` trên trắng / trên `surfaceVariant` | 6,08 / 5,52 | Đạt |
| `onAiContainer` trên `aiContainer` | 6,37 | Đạt |
| `primary` (vàng) trên trắng | 1,34 | **Không đạt** → không dùng làm màu chữ/icon |
| `textHint` / `navInactive` trên trắng | 2,54 | Không đạt cho chữ thường (xem mục 6) |
| `onSuccessContainer` trên `successContainer` | 3,58 | Không đạt cho chữ thường |
| `onErrorContainer` trên `errorContainer` | 3,95 | Không đạt cho chữ thường |
| Chữ trắng trên `success` (SnackBar) | 2,54 | Không đạt |
| Màu động cơ trên nền của nó: need 5,62 · emotion 4,80 đạt; ads 4,24 · other 4,34 · social 3,57 · convenience 3,32 · want 3,00 · sale 2,86 | — | 6/8 cặp không đạt |

## 6. Ghi chú sai khác (deviation)

- **Màu chủ đạo vàng, khác Figma Lab 2 (indigo).** Nhóm quyết định giữ bảng màu vàng `#FFDE02` / `#070E20` hiện tại; Figma Lab 2 dùng indigo. Không đổi lại.
- **Gộp màu gần giống (B4):** `#F9F9FB` và `#F9FAFB` → `background` (`#F8F9FA`); `#4B5563` (chữ chip "Câu mẫu") → `textBody` (`#374151`). Khác biệt mắt thường gần như không thấy.
- **Vượt ngân sách (B4):** trước dùng đỏ (`#FEE2E2` / `#DC2626` / `#EF4444` / viền `#FCA5A5`), nay dùng `surfaceVariant` + `accentNeutral` (viền `outline`).
- **Còn tồn tại, chưa sửa vì sẽ đổi màu hiển thị:** các cặp "Không đạt" ở mục 5 (chữ gợi ý/tab chưa chọn, nhãn trạng thái, chữ màu động cơ trên nền nhạt, SnackBar xanh). Cần nhóm quyết định trước khi đậm hoá các màu này.
