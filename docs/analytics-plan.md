# Analytics Event Plan (Kế hoạch sự kiện Analytics)
**Dự án**: Why I Buy – The Psychology of Money
**Môn học**: PRM393 – Mobile Programming (Lab 3)
**Tác giả**: Nhóm phát triển Why I Buy

---

## 1. Nguyên tắc

1. **Một nguồn tên duy nhất.** Tên event và tên tham số là hằng trong `lib/services/analytics_events.dart` (`AnalyticsEvents`, `AnalyticsParams`). `AppAnalyticsService` chỉ gửi các hằng này; không viết chuỗi tên event ở nơi khác.
2. **Chỉ ViewModel gọi analytics.** Screen và widget không gọi `AppAnalyticsService` hay `CrashlyticsService` trực tiếp.
3. **Không gửi thông tin định danh (No PII).** Không gửi email, tên hiển thị, tên món, nội dung tìm kiếm, ghi chú, link sản phẩm. User ID của Analytics và Crashlytics là Firebase `uid`; xoá khi đăng xuất.
4. **Không gửi số tiền chính xác.** Tiền được gửi dưới dạng `amount_bucket`: `lt_100k` (< 100.000 ₫) · `100k_500k` (100.000–500.000 ₫) · `gt_500k` (> 500.000 ₫). Món chưa có giá: `has_price = 0`, không có `amount_bucket`.
5. **Mỗi event trả lời một câu hỏi sản phẩm.** Câu hỏi được viết trung tính (không coi "Bỏ qua" là thành công, không nói "tiết kiệm").
6. Màn hình (`screen_view`) được ghi tự động bởi `FirebaseAnalyticsObserver` theo tên route trong `AppRoutes`.

---

## 2. Bảng event

| # | Event | Tham số (kiểu) | ViewModel gọi (khi nào) | Câu hỏi sản phẩm |
|:-:|:---|:---|:---|:---|
| 1 | `login` | `method` (string: `google` · `guest`) | `AuthViewModel.signInWithGoogle` / `signInAnonymously` – đăng nhập thành công | Người dùng chọn cách đăng nhập nào, bao nhiêu người quay lại mỗi tuần? |
| 2 | `logout` | `session_duration_sec` (int, tuỳ chọn – hiện chưa gửi) | `AuthViewModel.signOut` | Người dùng có chủ động đăng xuất không, và sau bao lâu? |
| 3 | `search` | `query_length` (int), `result_count` (int) | `WishlistViewModel.setSearchQuery` – mỗi lần ô tìm kiếm khác rỗng | Người dùng có dùng tìm kiếm trong danh sách mong muốn không, và có hay gặp kết quả rỗng không? |
| 4 | `add_to_wishlist` | `motive` (string, key động cơ), `has_price` (0/1), `amount_bucket` (string, khi có giá) | `WishlistViewModel.addItem` – lưu món thành công | Món được lưu thường gắn với động cơ nào, ở khoảng giá nào, và bao nhiêu món được lưu khi chưa biết giá? |
| 5 | `view_item_detail` | `motive` (string), `days_in_cooldown` (int, số ngày từ lúc lưu) | `WishlistViewModel.onItemViewed` – mở Chi tiết món | Người dùng mở lại món sau bao nhiêu ngày, với động cơ nào? |
| 6 | `make_decision` | `decision` (string: `buy` · `wait` · `skip`), `motive` (string), `has_price` (0/1), `amount_bucket` (string, khi có giá) | `WishlistViewModel.wait` / `skip` (decision `wait` / `skip`) và `PurchaseViewModel` khi lưu khoản mua từ Wishlist (decision `buy`) – sau khi ghi thành công | Mua · Chờ · Bỏ qua phân bố thế nào theo động cơ và khoảng giá? |
| 7 | `purchase_recorded` | `motive` (string), `amount_bucket` (string), `budget_group` (string, id nhóm) | `PurchaseViewModel.addPurchase` – ghi khoản mua thành công | Khoản mua được ghi thuộc động cơ và nhóm ngân sách nào, ở khoảng tiền nào? |
| 8 | `budget_set` | `budget_group` (string, id nhóm), `amount_bucket` (string), `month` (string `yyyy-MM`) | `BudgetViewModel.setGroupLimits` – lưu thành công, mỗi nhóm có hạn mức > 0 một sự kiện | Người dùng đặt hạn mức cho nhóm nào, ở mức nào? |
| 9 | `export_report` | `file_format` (string: `pdf`), `item_count` (int: khoản mua + món đã quyết định trong tháng) | `ReportViewModel.generateAndShare` – chia sẻ PDF thành công | Có bao nhiêu người xuất và chia sẻ báo cáo tháng, báo cáo thường có bao nhiêu mục? |
| 10 | `click_sale_reminder` | `sale_type` (string: `double_day` · `mid_month` · `payday`) | `openFromNotification` (`lib/app/app.dart`) – chạm thông báo FCM có custom data `type` = `sale` khi Remote Config `sale_reminder_enabled` bật, rồi mở "Danh sách cho đợt sale"; `sale_type` lạ được ghi là `other` | Nhắc nhở đợt sale nào được mở nhiều nhất? |

---

## 3. Crashlytics

| Mục | Quy ước |
|:---|:---|
| User identifier | Firebase `uid` khi đăng nhập (`AuthViewModel`), chuỗi rỗng khi đăng xuất. Không dùng email. |
| Custom key `screen` | Tên route hiện tại (`AppRoutes`), cập nhật bởi `CrashlyticsService.screenObserver` trong `MaterialApp.navigatorObservers`. Dialog / bottom sheet không đổi key. Các tab trong màn chính không phải route nên không đổi key. |
| Lỗi đã xử lý | Service đổi lỗi Firebase thành `AppException` (`mapFirebaseError`). ViewModel: `AppException` → hiện `messageVi` (UiError có "Thử lại" với stream); lỗi khác → `CrashlyticsService.recordHandledError` + câu chung "Đã có lỗi, vui lòng thử lại." (mixin `ErrorReporting`). Screen không gọi `mapFirebaseError`. |

---

## 4. Thay đổi so với bản trước (B9)

- `record_purchase` → `purchase_recorded`; `set_budget` → `budget_set` (theo tên trong đặc tả).
- Bỏ `search_term` (có thể chứa tên món) → `query_length`.
- Bỏ số tiền chính xác (`item_price`, `budget_amount`, `saved_amount`) → `amount_bucket`.
- Bỏ `item_id` khỏi `view_item_detail` và `purchase_recorded`; bỏ `has_sale_date` (trùng với `motive = sale`); bỏ `file_size_kb`.
- `make_decision.action` (`drop`) → `decision` (`skip`).
- `export_report` không còn liên quan Cloud Storage (D7): PDF tạo trên máy và chia sẻ bằng `printing`.
