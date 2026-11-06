# Why I Buy · Web admin (Flutter Web)

Trang quản trị của hệ thống Why I Buy cho vai trò **staff** và **admin** (`users/{uid}.role`). Không có server riêng: web đọc/ghi thẳng Firestore, quyền do `prm393_lab03/firestore.rules` quyết định (test: `prm393_lab03/firebase/tests`).

**URL:** https://prm393-34056.web.app

| Mục | Làm gì | Firestore |
|---|---|---|
| Đăng nhập | Google Sign-In (popup); tài khoản `user` bị đăng xuất kèm thông báo | `users/{uid}.role` |
| Tổng quan | Người mới hôm nay, hoạt động hôm nay, cài app chưa dùng, tổng chi tiêu, đề xuất chờ duyệt, món bỏ qua, giá trị tránh chi; phân bổ động cơ mua sắm; biểu đồ kết quả cân nhắc; thẻ "Cơ hội tăng trưởng". Các số về món và khoản mua chỉ admin thấy | `count()` / `sum()` trên `users`, `saleSuggestions`, collection group `wishlistItems`, `purchases` |
| Người dùng | Tìm (không dấu cũng được), lọc (mới hôm nay, 7 ngày, chưa dùng, nhân viên); số món / khoản mua mỗi người (admin); **nhắn tin riêng** vào hộp thư app; **đổi vai trò** (chỉ admin, không đổi của chính mình) | `users`, `users/{uid}/inbox` |
| Sự kiện sale (quản lý) | Danh sách, tìm, thêm (đăng ngay hoặc nháp), sửa, đăng nháp, lưu trữ (không khôi phục); chặn hai sự kiện cùng ngày | `saleEvents` (app đọc) |
| Duyệt đề xuất | Duyệt (batch: tạo sự kiện + đổi trạng thái + hộp thư) hoặc từ chối kèm lý do chọn nhanh; app cập nhật ngay | `saleSuggestions`, `saleEvents`, `users/{uid}/inbox` |
| Thông báo | Mẫu 1 chạm, xem trước trên app, đăng, lưu trữ | `announcements` |
| Trợ lý AI | Gemini (Firebase AI Logic + App Check, model từ Remote Config `ai_insight_model`) soạn câu hỏi tự vấn và lời nhắn từ số liệu tổng hợp; ghi nhãn AI / câu mẫu; chỉ điền vào form Thông báo | — |

Chế độ sáng / tối ở thanh trên cùng. Kiến trúc MVVM + Provider: `screens/` → `viewmodels/` → `services/` (và service dùng chung trong `../packages/core`) → Firebase SDK; màn hình không gọi SDK. Token và component Lab 2 (`AppColors`, `AppTokens`, `AppTextStyles`, `AppDimens`, `AppButton`, `AppTextField`, `SectionCard`, `UiStateBuilder`…) lấy từ `packages/core`.

## Chạy

```bash
cd prm393_flutter_admin
flutter pub get
flutter run -d chrome
```

Thử trên Firebase Emulator (không đụng dữ liệu thật; cổng Firestore 8085 để không trùng server push 8080), từ thư mục gốc repo:

```bash
firebase emulators:start --only auth,firestore
```

```bash
cd prm393_flutter_admin && flutter run -d chrome --dart-define=USE_EMULATORS=true
```

Kiểm thử: `flutter test` (ViewModel với service giả, trợ lý AI, và mọi trang được dựng ở 1366 / 800 / 400 px, sáng và tối, để bắt lỗi tràn layout).

## Deploy (Firebase Hosting)

```bash
cd prm393_flutter_admin && flutter build web --release && cd ..
firebase deploy --only firestore:rules,firestore:indexes,hosting
```

`firebase.json` ở thư mục gốc repo trỏ tới `prm393_lab03/firestore.rules`, `prm393_lab03/firestore.indexes.json` và `prm393_flutter_admin/build/web`. Trên Windows, nếu PowerShell chặn `firebase.ps1` thì dùng `firebase.cmd`.

## Admin đầu tiên

1. Mở web, đăng nhập Google một lần (sẽ bị từ chối, nhưng tài khoản được tạo trong Authentication).
2. Firebase Console → Authentication → Users: sao chép UID.
3. Firestore → `users` → document có ID là UID đó (tạo nếu chưa có) → trường `role` (string) = `admin`.
4. Đăng nhập lại. Từ đây admin cấp vai trò `staff` / `admin` cho người khác ở mục Người dùng.

## Thông báo đẩy (tuỳ chọn)

Thông báo đã tới app qua Firestore, không cần server. Nếu muốn gửi kèm FCM push qua `spring-boot-push` đang chạy trên máy: `flutter run -d chrome --dart-define=PUSH_API_BASE_URL=http://localhost:8080`. Server chỉ nhận yêu cầu của tài khoản có `role == "admin"`.
