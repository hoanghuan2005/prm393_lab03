# PRM393 Lab 3 — Danh mục bằng chứng kiểm chứng (Evidence Matrix)
**Dự án**: Why I Buy — The Psychology of Money  
**Môn học**: PRM393 — Mobile Programming  
**Nhóm phát triển**: PRM393_Lab03  
**Firebase Project ID**: `prm393-34056`  

Tài liệu này tổng hợp toàn bộ bằng chứng xác minh (verifiable evidence) phục vụ chấm điểm Lab 3 theo thang Rubric 10 điểm của giảng viên:

---

## 1. Firebase Authentication (0.25đ)
- **Bằng chứng**: [`evidence/auth/auth_users_console.png`](auth/auth_users_console.png)
- **Nội dung kiểm chứng**:
  - Xác thực người dùng qua Google Sign-In (`google.com`) và Chế độ khách (`anonymous`).
  - Ghi nhận các tài khoản thực tế (`hoang huan`, `Khoa Huỳnh`, `Tâm Hoàng Đào`, `Kiệt`).
  - Duy trì phiên với `authStateChanges`, tự động bảo vệ màn hình (Auth Guard), xóa sạch user-state khi đăng xuất.

## 2. Firebase Cloud Firestore & Cloud Storage (0.25đ)
- **Bằng chứng Firestore**: [`evidence/firestore/firestore_console.png`](firestore/firestore_console.png)
  - Phân vùng dữ liệu an toàn theo từng người dùng: `users/{uid}/purchases`, `users/{uid}/wishlistItems`, `users/{uid}/budgets`.
- **Bằng chứng Cloud Storage**: [`evidence/storage/storage_console.png`](storage/storage_console.png)
  - File quy tắc bảo mật: [`firebase/storage.rules`](../firebase/storage.rules).
  - Tải file báo cáo PDF lên đường dẫn phân quyền: `reports/{userId}/why-i-buy_yyyy-MM.pdf`.
  - Hiển thị thanh tiến độ tải lên (upload progress indicator) và kiểm soát truy cập (chỉ owner UID được đọc/ghi).

## 3. Firebase Cloud Messaging - FCM (0.5đ)
- **Bằng chứng**: [`evidence/messaging/fcm_console.png`](messaging/fcm_console.png)
- **Nội dung kiểm chứng**:
  - Hộp thoại xin quyền `POST_NOTIFICATIONS` trên Android 13+.
  - Tiếp nhận và xử lý thông báo thành công ở cả 3 trạng thái: Foreground (đang mở), Background (chạy nền) và Terminated (đã đóng).
  - Lưu trữ tin nhắn vào **Hộp thư thông báo trong ứng dụng** (`ProfileScreen`).
  - Nhấp vào thông báo điều hướng chính xác về màn hình liên quan (`WishlistScreen`, `BudgetScreen`).

## 4. Google Analytics for Firebase (0.5đ)
- **Bằng chứng DebugView**: [`evidence/analytics/debugview_console.png`](analytics/debugview_console.png)
- **Kế hoạch sự kiện**: [`docs/analytics-plan.md`](../docs/analytics-plan.md)
- **Nội dung kiểm chứng**:
  - Ghi nhận đầy đủ 10/10 sự kiện trên DebugView: `login`, `logout`, `search`, `add_to_wishlist`, `view_item_detail`, `make_decision`, `purchase_recorded`, `budget_set`, `export_report`, `click_sale_reminder`.
  - Tuân thủ nghiêm ngặt nguyên tắc **Zero PII**: không gửi email/tên thật, gom số tiền vào `amount_bucket`.

## 5. Firebase Crashlytics (0.25đ)
- **Bằng chứng**: [`evidence/crashlytics/crashlytics_console.png`](crashlytics/crashlytics_console.png)
- **Nội dung kiểm chứng**:
  - Ghi nhận lỗi đã xử lý (Non-fatal handled error) từ luồng mạng/timeout.
  - Kích hoạt thành công 1 lỗi Crash thử nghiệm có chủ đích (Fatal test crash) tại khu vực Dev.
  - Gắn kèm Firebase UID (User Identifier) và Custom Key `screen` (cập nhật theo NavigatorObserver).

## 6. Firebase Remote Config (0.25đ)
- **Bằng chứng**: [`evidence/remote_config/remote_config_console.png`](remote_config/remote_config_console.png)
- **Nội dung kiểm chứng**:
  - Cấu hình 5 tham số: `cooling_off_days`, `enable_ai_insight`, `max_wishlist_items_shown`, `sale_reminder_enabled`, `ai_insight_model`.
  - Giá trị mặc định nội bộ: [`firebase/remote-config-defaults.json`](../firebase/remote-config-defaults.json).
  - Thay đổi giá trị trên Console lập tức phản ánh trực tiếp lên UI ứng dụng mà không cần build lại APK.

## 7. ARTEMIS E2E Automated Testing (1.5đ)
- **Bảng ma trận kết quả**: [`evidence/artemis/artemis_test_results.md`](artemis/artemis_test_results.md)
- **Nhật ký thực thi chi tiết**: [`evidence/artemis/artemis_execution_log.txt`](artemis/artemis_execution_log.txt)
- **Báo cáo kiểm thử khám phá 20 phút**: [`evidence/artemis/exploratory_session_log.md`](artemis/exploratory_session_log.md)
- **Tỷ lệ đạt**: **100% (30/30 runs - 10 test cases x 3 lần chạy)**.

## 8. AI Code Review (0.5đ)
- **Biên bản đánh giá mã nguồn**: [`docs/code-review.md`](../docs/code-review.md)
- Đạt chuẩn 5 phát hiện gắn dòng code, phân bổ trên 5 nhóm lỗi (Architecture, Maintainability, Security, Performance, Accessibility). Sửa và gắn mã commit cho 3 lỗi được chấp nhận.
