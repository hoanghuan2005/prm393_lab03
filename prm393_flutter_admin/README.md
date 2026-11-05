# Why I Buy · Web admin (Flutter Web)

Trang quản trị của hệ thống Why I Buy, dành cho role **admin** (`users/{uid}.role == "admin"`). Không có server riêng: web đọc/ghi thẳng Firestore, quyền do `firestore.rules` quyết định.

| Màn hình | Làm gì | Firestore |
|---|---|---|
| Đăng nhập | Google Sign-In (popup); tài khoản không phải admin bị đăng xuất kèm thông báo | `users/{uid}.role` |
| Tổng quan | 7 truy vấn tổng hợp `count()` / `sum()` + biểu đồ trạng thái món | `users`, `saleSuggestions`, `/{path=**}/wishlistItems` |
| Sự kiện sale (quản lý) | Danh sách, tìm kiếm (không dấu cũng được), thêm, sửa, lưu trữ / khôi phục; chặn hai sự kiện cùng ngày | `saleEvents` (app đọc) |
| Duyệt đề xuất | Duyệt (batch: tạo sự kiện + đổi trạng thái + hộp thư) hoặc từ chối kèm lý do; app cập nhật ngay | `saleSuggestions`, `saleEvents`, `users/{uid}/inbox` |
| Thông báo | Form đăng thông báo, hiện ngay trong hộp thư của app; lưu trữ / đăng lại | `announcements` |

Kiến trúc MVVM + Provider: `screens/` → `viewmodels/` → `services/` (và service dùng chung trong `../packages/core`) → Firebase SDK. Màn hình không gọi SDK. Token và component Lab 2 (`AppColors`, `AppTextStyles`, `AppDimens`, `AppButton`, `AppTextField`, `SectionCard`, `UiStateBuilder`…) lấy từ `packages/core`.

## Chạy

```bash
cd prm393_flutter_admin
flutter pub get
flutter run -d chrome
```

Thử trên Firebase Emulator (không đụng dữ liệu thật; cổng Firestore 8085 để không trùng server push 8080):

```bash
firebase emulators:start --only auth,firestore
cd prm393_flutter_admin && flutter run -d chrome --dart-define=USE_EMULATORS=true
```

(Lệnh `firebase` chạy ở thư mục gốc repo, nơi có `firebase.json`.)

Kiểm thử: `flutter test` (ViewModel với service giả, và mọi trang được dựng ở 1366 / 800 / 400 px để bắt lỗi tràn layout).

## Deploy (Firebase Hosting)

URL: **https://prm393-34056.web.app**

```bash
cd prm393_flutter_admin && flutter build web --release && cd ..
firebase deploy --only firestore:rules,firestore:indexes,hosting
```

`firebase.json` ở thư mục gốc repo trỏ tới `prm393_lab03/firestore.rules`, `prm393_lab03/firestore.indexes.json` và `prm393_flutter_admin/build/web` (Firebase CLI không cho thư mục `public` nằm ngoài thư mục chứa `firebase.json`). Trên Windows, nếu PowerShell chặn `firebase.ps1` thì dùng `firebase.cmd`.

## Admin đầu tiên

1. Mở web, đăng nhập Google một lần (sẽ bị từ chối, nhưng tài khoản được tạo trong Authentication).
2. Firebase Console → Authentication → Users: sao chép UID.
3. Firestore → `users` → document có ID là UID đó (tạo nếu chưa có) → thêm trường `role` (string) = `admin`.
4. Đăng nhập lại. Từ đây admin có thể nâng người khác lên admin; không ai tự đổi role của mình.

## Thông báo đẩy (tuỳ chọn)

Thông báo đã tới app qua Firestore, không cần server. Nếu muốn gửi kèm FCM push qua `spring-boot-push` đang chạy trên máy: `flutter run -d chrome --dart-define=PUSH_API_BASE_URL=http://localhost:8080`. Server chỉ nhận yêu cầu của tài khoản có `role == "admin"`.
