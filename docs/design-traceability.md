# Design Traceability Matrix (Ma trận truy vết thiết kế)
**Dự án**: Why I Buy – The Psychology of Money
**Môn học**: PRM393 – Mobile Programming (Lab 3)
**Tác giả**: Nhóm phát triển Why I Buy
**Figma Spec**: [Why I Buy ver2](https://www.figma.com/design/VaPYFxfpx14tnQmOMSgdjP/Why-I-Buy-ver2?node-id=0-1)

---

## 1. Giới thiệu tổng quan
**Why I Buy** giúp người trẻ ghi lại vì sao mình mua và nhìn lại thói quen mua sắm, dựa trên *The Psychology of Money* (Morgan Housel):
1. **8 động cơ mua hàng**: Nhu cầu, Mong muốn, Khuyến mãi, Cảm xúc, Ảnh hưởng MXH, Tiện lợi, Quảng cáo, Khác.
2. **Thời gian cân nhắc**: món mới lưu có `cooldownUntil = ngày lưu + coolingOffDays` (cài đặt người dùng, mặc định theo Remote Config `cooling_off_days`), trừ động cơ Nhu cầu.
3. **Quyết định ngang hàng**: Mua · Chờ · Bỏ qua (không khen/chê lựa chọn nào).
4. **Firebase (gói Spark)**: Authentication (Google + Khách), Cloud Firestore, Remote Config, Crashlytics, Cloud Messaging, Analytics, Firebase AI Logic, App Check. Không dùng Cloud Storage – xem [`decisions.md`](decisions.md) (D7).

---

## 2. Bảng ánh xạ màn hình

Route theo `AppRoutes` (`lib/app/routes.dart`). Các tab của màn chính nằm trong `MainNavigationScreen` (route `/home`).

| STT | Màn hình | Mã màn (`screen-spec.md` Lab 2) | Route | Flutter Widget | ViewModel / nguồn dữ liệu | Trạng thái |
|:---:|:---|:---:|:---|:---|:---|:---:|
| 1 | Onboarding | `01` | `/onboarding` | `OnboardingScreen` | – (nội dung tĩnh) | Implemented |
| 2 | Đăng nhập | – (thêm ở Lab 3, DEV-01) | `AuthGate` (chưa đăng nhập) | `LoginScreen` | `AuthViewModel` → `AuthService` | Implemented |
| 3 | Trang chủ | `02` | Tab 1 của `/home` | `HomeScreen` | `PurchaseViewModel`, `BudgetViewModel`, `WishlistViewModel` | Implemented |
| 4 | Lịch sử | `06` | Tab 2 · `/history` | `HistoryScreen` | `PurchaseViewModel`, `BudgetViewModel` | Implemented |
| 5 | Mô hình (Thói quen) | `07` | Tab 3 · `/patterns` | `PatternsScreen` | `PurchaseViewModel` | Implemented |
| 6 | Góc nhìn (có AI) | `08` | Tab 4 · `/insights` | `InsightsScreen` | `InsightsViewModel` → `AiInsightService` → `AiService` | Implemented |
| 7 | Cá nhân & Firebase Demo Area | `10` | Tab 5 · `/profile` | `ProfileScreen` | `AuthViewModel`, `SettingsViewModel` | Implemented |
| 8 | Danh sách mong muốn | `11` | `/wishlist` | `WishlistScreen` | `WishlistViewModel` | Implemented |
| 9 | Thêm món mong muốn | `12` | `/wishlist/add` | `AddItemScreen` | `WishlistViewModel` | Implemented |
| 10 | Chi tiết món mong muốn + Decision Card | `13`, `20` | `/wishlist/detail` | `ItemDetailScreen`, `DecisionCardPanel` | `WishlistViewModel`, `DecisionSupportViewModel` | Implemented (nhãn 7.4, lý do AI) |
| 11 | Ghi khoản mua (2 bước) | `03`, `04` | `/purchase/record` | `RecordPurchaseScreen` | `PurchaseViewModel` | Implemented |
| 12 | Chi tiết khoản mua | `05` | `/purchase/detail` | `PurchaseDetailScreen` | `PurchaseViewModel` | Implemented |
| 13 | Ngân sách theo nhóm | `31` | `/budget` | `BudgetScreen` | `BudgetViewModel`, `PurchaseViewModel` | Implemented (một tổng + thẻ nhóm) |
| 14 | Chiêm nghiệm tháng & PDF | `09` | `/reflection` | `MonthlyReflectionScreen` | `ReflectionViewModel`, `ReportViewModel`, `InsightsViewModel` | Implemented |
| 15 | Widget Gallery | – | `/dev/widgets` (chỉ debug) | `WidgetGalleryScreen` | – | Implemented |
| 16 | Lịch sale | `26` | `/sales` (nút lịch ở Wishlist) | `SaleCalendarScreen` | `DecisionSupportViewModel` (Remote Config `sale_calendar`) | Implemented |
| 17 | Danh sách cho đợt sale | `26.2`, `26.3` | `/sales/list` | `SaleListScreen` | `DecisionSupportViewModel` | Implemented |
| 19 | Hồ sơ mua sắm | `24` | `/profile/shopping` (Cá nhân → Mở hồ sơ mua sắm) | `ShoppingProfileScreen`, `OwnedItemSheet` | `ShoppingProfileViewModel` → `ShoppingProfileService` | Implemented (24.1–24.3) |
| 20 | So sánh món cùng nhóm | – (A-15) | `/wishlist/compare` (nút trong Decision Card) | `CompareItemsScreen` | `DecisionSupportViewModel` | Implemented |
| 21 | Lịch sử giá | `22.3` | Trong Chi tiết món | `PriceHistoryPanel` | `DecisionSupportViewModel` → `WishlistService.priceHistory` | Implemented |
| 22 | Hỏi mức hài lòng (hộp thoại) | `27` | Tự hiện ở màn chính; nút "Chấm/Sửa" ở Chi tiết khoản mua | `SatisfactionDialog` | `PurchaseViewModel` → `PurchaseService.setSatisfaction` | Implemented (27.1, 27.2 bằng SnackBar) |
| 18 | Lập kế hoạch cho đợt sale | – (đặc tả 7.5) | `/sales/plan` | `SalePlanScreen` | `DecisionSupportViewModel` → `SalePlanner`, `AiDecisionService` | Implemented (lời giải thích AI tính năng 5) |

---

## 3. Luồng người dùng

### Flow 1: Lưu món mong muốn
1. `AddItemScreen`: nhập tên (bắt buộc, ≤ 60), giá (tuỳ chọn, ô tiền VND có dấu chấm và ₫), link (tuỳ chọn), nhóm ngân sách (tuỳ chọn, có chip "Gợi ý nhóm: …"), chọn 1 trong 8 động cơ. Nếu đã có khoản mua 30 ngày gần đây hoặc món đang cân nhắc giống món mới, hiện khối "Bạn đã có món tương tự" (DEV-08).
2. `WishlistViewModel.addItem` → `WishlistService.add`: lưu món; có giá thì tạo kèm `priceSnapshot`; đặt `cooldownUntil` trừ động cơ Nhu cầu.
3. Món hiện trong danh sách với trạng thái "Đang cân nhắc".
* **Không nhập giá**: `latestPriceVnd = null`, thẻ hiện "Chưa có giá".
* **Lỗi**: lỗi Firebase được đổi thành câu tiếng Việt; khi mất mạng, Firestore giữ thay đổi trên máy và đồng bộ khi có mạng lại.

### Flow 2: Quyết định Mua · Chờ · Bỏ qua
1. `ItemDetailScreen` (mở từ danh sách) hiện giá và ngày ghi giá, động cơ, thời gian cân nhắc còn lại, khối "Bạn đã có món tương tự" nếu có, rồi **Decision Card**: nhãn theo Rules Engine v1 (đặc tả 7.4, `DecisionRules`), một câu lý do (AI hoặc câu mẫu), các tín hiệu S1–S8 có dữ liệu. Bên dưới là ba nút cùng kiểu và cùng cỡ: Mua · Chờ · Bỏ qua.
2. Mỗi lựa chọn chỉ báo thành công sau khi ghi xong; khi lỗi, màn hình giữ nguyên và cho thử lại.
   * **Mua**: mở `RecordPurchaseScreen` điền sẵn tên, giá, nhóm của món; người dùng nhập số tiền thực chi. `PurchaseService.buyFromWishlist` ghi một batch: tạo khoản mua có `wishlistItemId`, đổi món sang "Đã mua" kèm `purchaseId`, ghi decision `buy`. Xong thì mở Chi tiết khoản mua.
   * **Chờ**: `ReviewDateSheet` cho chọn ngày xem lại (hết thời gian cân nhắc, sau 7 ngày, đến đợt sale đã xác nhận kế tiếp, hoặc tự chọn). `WishlistViewModel.wait` đặt `reviewAt` (09:00) và ghi decision `wait`; món vẫn "Đang cân nhắc". Trên Android, app xin quyền thông báo ngay sau đó và hẹn thông báo "Đến hẹn xem lại"; mọi nền tảng có mục "Cần xem lại" trong danh sách.
   * **Bỏ qua**: `WishlistViewModel.skip` đổi trạng thái sang "Bỏ qua" và ghi decision `skip`, rồi quay về danh sách với SnackBar `Đã bỏ qua "<tên món>".` có nút "Hoàn tác" trong 5 giây. Sau này vẫn "Cân nhắc lại" được (`reconsider`, decision `undo`).
3. Firestore stream cập nhật danh sách ngay. Xoá một khoản mua đã liên kết sẽ đưa món về "Đang cân nhắc" ([`data-model.md`](data-model.md), quy tắc 4a).

### Flow 3: Chiêm nghiệm tháng và báo cáo PDF
1. Từ Góc nhìn → "Xem chiêm nghiệm tháng" (`/reflection`).
2. Xem tổng quan tháng (số liệu do code tính, câu do AI hoặc câu mẫu), chọn mức hài lòng 1–5 và mục tiêu tháng sau → "Lưu chiêm nghiệm" (`ReflectionService.save`).
3. "Xuất và chia sẻ PDF": `ReportService` dựng PDF trên máy, `ReportShareService` mở bảng chia sẻ của hệ thống (tên file `why-i-buy_yyyy-MM.pdf`); "Xem trước" mở hộp thoại in/xem trước.
* **Lỗi**: `ErrorView` với nút "Thử lại"; PDF đã tạo được giữ lại nên thử lại không phải dựng lại.

---

## 4. Component dùng chung (Figma → code)

| Component Figma | Flutter Widget | Vị trí file | Ghi chú |
|:---|:---|:---|:---|
| App Button | `AppButton` | `lib/widgets/app_button.dart` | Primary · Secondary · Danger · Loading |
| Motive Chip | `MotiveChip` | `lib/widgets/motive_chip.dart` | 8 màu (`MotiveColors`), vùng chạm ≥ 48dp khi bấm được |
| Wishlist Card | `WishlistCard` | `lib/widgets/wishlist_card.dart` | Tên, giá, động cơ, đếm ngược cân nhắc, trạng thái |
| Text Field | `AppTextField`, `AmountField` | `lib/widgets/` | Ô chữ; ô tiền int VND có dấu chấm và ₫ |
| Budget meter | `BudgetBar` | `lib/widgets/budget_bar.dart` | Màu trung tính, "Đã vượt …" khi vượt |
| Section card | `SectionCard` | `lib/widgets/section_card.dart` | Tiêu đề + nội dung |
| Dialog / Snackbar / Bottom sheet | `ConfirmDialog`, `showUndoSnackBar`, `AppBottomSheet` | `lib/widgets/` | Luôn có "Huỷ"; "Hoàn tác" 5 giây |
| Loading / Empty / Error | `LoadingView`, `EmptyView`, `ErrorView`, `UiStateBuilder` | `lib/widgets/states/` | Ba trạng thái màn hình |

---

## 5. Sai lệch thiết kế có ghi nhận

| ID | Màn hình / Component | Thay đổi so với Figma | Lý do |
|:---:|:---|:---|:---|
| **DEV-01** | `LoginScreen`, `ProfileScreen` | Thêm màn đăng nhập (Google + Khách) và Firebase Demo Area trong Cá nhân | Lab 3 yêu cầu đăng nhập và khu demo Firebase (FCM, Crashlytics, Remote Config, dữ liệu demo). |
| **DEV-02** | `ItemDetailScreen` | Thời gian cân nhắc còn lại hiện bằng chữ ("Còn lại khoảng X ngày Y giờ"), tính lại mỗi lần màn được dựng | Đơn giản, không cần bộ đếm chạy liên tục. |
| **DEV-03** | `MonthlyReflectionScreen` | Báo cáo PDF được tạo trên máy và chia sẻ qua bảng chia sẻ hệ thống, không tải lên đám mây | Cloud Storage cần gói Blaze; project dùng gói Spark (D7, [`decisions.md`](decisions.md)). |
| **DEV-04** | `InsightsScreen`, `MonthlyReflectionScreen` | Gọi Gemini qua **Firebase AI Logic** (gói `firebase_ai`) thay vì Cloud Functions như đặc tả mục 7.6 | Cloud Functions cần gói Blaze, đặc tả xếp vào GĐ3. Firebase AI Logic chạy được trên gói Spark và vẫn đúng nguyên tắc "không để khóa API trong app". Các nguyên tắc còn lại giữ nguyên: code tính mọi con số, AI trả JSON theo schema, câu có số lạ hoặc từ phán xét bị thay bằng câu mẫu, lưu đệm theo dữ liệu đầu vào, người dùng tắt được AI, công tắc từ xa `enable_ai_insight`, đổi model qua `ai_insight_model`. |
| **DEV-05** | `InsightsScreen` | Mỗi thẻ có nhãn "AI" hoặc "Câu mẫu"; AI chỉ chạy khi tháng có ít nhất 3 khoản mua | Minh bạch nguồn câu chữ và nói rõ khi thiếu dữ liệu (đặc tả mục 7.7). Trên Windows, AI chỉ chạy khi build kèm debug token App Check; nếu không thì dùng câu mẫu. |
| **DEV-06** | Firebase AI Logic / App Check | Firebase AI Logic **bắt buộc App Check**. Android: Play Integrity (bản release cài từ Google Play), debug provider khi build debug hoặc khi build kèm debug token. Web: Fraud Defense (reCAPTCHA Enterprise). Windows: chỉ có debug provider | App chưa phát hành qua Google Play nên APK cài qua QR không qua được Play Integrity. Cả nhóm dùng chung một debug token đăng ký trên Console, đặt trong `assets/local/app_check.json` (git bỏ qua; app tự đọc khi khởi động, không cần cờ build). Windows gọi AI là cách không chính thức (`firebase_ai` không liệt kê Windows). |
| **DEV-07** | Toàn app | Màu chủ đạo vàng `#FFDE02` thay indigo `#2E4A9E` | Quyết định nhóm – xem [`decisions.md`](decisions.md), [`design-tokens.md`](design-tokens.md). |
| **DEV-08** | `AddItemScreen`, `RecordPurchaseScreen`, `ItemDetailScreen` | Thêm gợi ý nhóm ngân sách ("Gợi ý nhóm: …", chạm mới áp dụng) và khối "Bạn đã có món tương tự" (khoản mua 30 ngày gần đây, món đang cân nhắc) | Tính năng AI 3 và 4 của đặc tả. Code đoán trước, AI chỉ chọn trong danh sách; gợi ý có nhãn "AI" khi do AI chọn, không chặn hay khuyên quyết định. |
| **DEV-09** | `ItemDetailScreen`, `SaleCalendarScreen`, `SaleListScreen`, `SalePlanScreen` | Decision Card có nhãn Rules Engine v1 và câu lý do (AI tính năng 2); thêm Lịch sale, "Danh sách cho đợt sale" và "Lập kế hoạch cho đợt sale" (bài toán cái túi 0/1, ba phương án) | Đặc tả 7.4, 7.5, 7.6, 8.2. Khác đặc tả: chưa có Hồ sơ mua sắm nên không có S5 "Đồ đang có" và nhánh "xác nhận trùng" của nhãn 5; gói mua tính `gia` = 0 vì không đọc lịch sử giá; "Giữ lại nhiều hơn" dùng tối đa 50% phần khả dụng (giả định của nhóm); nhắc 20:00 trước đợt sale cần Cloud Functions nên chưa làm, thông báo đẩy gửi tay từ Console. |
| **DEV-10** | `ShoppingProfileScreen`, `ItemDetailScreen`, `CompareItemsScreen`, `PurchaseDetailScreen`, `AddItemScreen` | Thêm Hồ sơ mua sắm (A-12), Lịch sử giá (A-14), So sánh món cùng nhóm (A-15), hỏi mức hài lòng sau 7 ngày (A-16); chọn mức ưu tiên 1–5 sao khi thêm/sửa món | Đặc tả 6.5, 7.2, 7.5, 8.3, màn 22.3, 24, 27. Khác đặc tả: chưa có loại giá và phân loại (`priceType`, `modelId`) nên mọi lần ghi giá của cùng món được coi là "so được"; chỉ hỏi hài lòng với khoản mua 7–30 ngày tuổi, tối đa một lần mỗi phiên; "hài lòng theo động cơ" ở Góc nhìn chỉ hiện động cơ có ≥ 2 khoản đã chấm. |
