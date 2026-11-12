# KỊCH BẢN THUYẾT TRÌNH BẢO VỆ LAB 03 - PRM393 (CHUẨN XÁC DỰ ÁN 100%)
## ĐỀ TÀI: Why I Buy? – Mindful Shopping Companion
### Học phần: PRM393 · Nhóm thực hiện: Nhóm 07
- **Thành viên nhóm:** Hồ Hữu Hoàng Huân (SE192248 - Lead), Huỳnh Đăng Khoa, Đào Tâm Hoàng, Ngô Vũ Minh Kiệt, Nguyễn Đình Ngọc Ân
- **Android Package ID:** `com.group07.whyibuy`
- **Firebase Project ID:** `prm393-34056`
- **Kho mã nguồn GitHub:** `https://github.com/hoanghuan2005/prm393_lab03`
- **Tài liệu đối chiếu:** `docs/architecture.md`, `docs/decisions.md`, `docs/analytics-plan.md`, `docs/code-review.md`, `docs/test-plan.md`

---

## 🎯 5 CÂU HỎI TRỌNG TÂM CỦA GIẢNG VIÊN (ÁP DỤNG ĐỒNG BỘ CHO MỖI CÔNG NGHỆ)
1. **What & Why:** Công nghệ là gì? Tại sao dự án *Why I Buy* lại sử dụng?
2. **How & Cơ chế đăng ký:** Hoạt động ra sao? Khởi tạo, cấu hình và quy tắc bảo mật như thế nào?
3. **Chỗ nào dùng code đó:** File nào, class nào, method nào trong mã nguồn thực tế?
4. **Dùng ở màn hình nào:** Giao diện UI người dùng nào trực tiếp sử dụng?
5. **Cơ chế kiểm chứng (Verification):** Chứng minh hoạt động thực tế qua Firebase Console, Cloudinary Dashboard, DebugView, logs và xử lý ngoại tuyến.

---

## CHI TIẾT TỪNG PHẦN THUYẾT TRÌNH

### 📌 CÔNG NGHỆ 01: FIREBASE AUTHENTICATION (Slides 03 – 06)
1. **What & Why:**
   - **What:** Dịch vụ xác thực danh tính đám mây an toàn của Firebase, quản lý phiên và cấp `UID` duy nhất làm gốc dữ liệu cho Firestore (`users/{uid}`) và Storage.
   - **Why:** Bảo mật dữ liệu tài chính nhạy cảm của người dùng (Wishlist đắn đo, ngân sách, lịch sử chi tiêu). Cung cấp đăng nhập 1-chạm (One-tap Google Sign-In, Facebook Login) giảm tỷ lệ drop-off, đồng thời hỗ trợ tài khoản Khách (Guest) không rào cản và liên kết tài khoản (ACC-01 đến ACC-09).
2. **How & Cơ chế đăng ký:**
   - Cấu hình mã băm chứng chỉ `SHA-1` (`ecd5e35c...`) và `SHA-256` trên Firebase Console (Project `prm393-34056`, package `com.group07.whyibuy`).
   - Tải `google-services.json` đặt tại `android/app/`. Bật các Provider: Google, Facebook, GitHub, Email/Password, Anonymous.
   - Luồng dữ liệu: `GoogleSignIn.signIn()` $\to$ `GoogleSignInAuthentication` $\to$ `GoogleAuthProvider.credential` $\to$ `FirebaseAuth.signInWithCredential` $\to$ phát tín hiệu trên `authStateChanges`.
3. **Chỗ nào dùng code đó:**
   - File: `lib/services/auth_service.dart` (dòng 55–90).
   - Hàm: `signInWithGoogle()`, `signInWithFacebook()`, `signInWithGithub()`, `Stream<User?> get authStateChanges`.
   - Bọc qua hàm `guard()` trong `lib/services/service_guard.dart` để chuyển đổi toàn bộ exception thành `AppException`. ViewModel: `lib/viewmodels/auth_viewmodel.dart`.
4. **Dùng ở màn hình nào & Kiểm chứng:**
   - **Màn hình:** `LoginScreen` (các nút đăng nhập đa kênh và nút Khách), `ProfileScreen` (thông tin tài khoản, quản lý tài khoản liên kết, nút Đăng xuất), `AuthGate` (người gác cổng bảo vệ luồng).
   - **Kiểm chứng:** Firebase Console mục *Authentication > Users* hiển thị đúng UID, Email, Provider icon. Kịch bản huỷ đăng nhập (TC-01): bấm Huỷ ở hộp thoại Google không làm crash app, hiển thị SnackBar. Tắt mạng: báo "Vui lòng kiểm tra kết nối mạng". Đăng xuất (TC-10): dọn sạch local state và đẩy về Login.

---

### 📌 CÔNG NGHỆ 02: CLOUDINARY MEDIA MANAGEMENT (Slides 07 – 10)
1. **What & Why:**
   - **What:** Nền tảng Image CDN và Media Management hàng đầu thế giới, chuyên xử lý, tối ưu hoá và biến đổi hình ảnh/video qua URL (Dynamic Transformations).
   - **Why:** Giải quyết trực tiếp rào cản của **Quyết định D7** trong `docs/decisions.md`: Firebase Storage yêu cầu gói trả phí Blaze để sử dụng đầy đủ; Cloudinary là giải pháp thay thế hoàn hảo cho hình ảnh. Tự động nén chất lượng (`q_auto`) và định dạng WebP (`f_auto`), giảm 80% dung lượng ảnh chụp camera để lưới sản phẩm hiển thị siêu tốc không nghẽn RAM.
2. **How & Cơ chế đăng ký:**
   - Tạo tài khoản Cloud Name: `why-i-buy`.
   - Cấu hình **Unsigned Upload Preset** (`why_i_buy_unsigned`): Cho phép client mobile upload ảnh trực tiếp mà **không bao giờ nhúng API Secret vào mã nguồn client**, ngăn chặn nguy cơ lộ mã bảo mật.
   - Luồng: Client chọn ảnh qua `image_picker` $\to$ chuyển thành `Uint8List` $\to$ gửi `http.MultipartRequest` lên `https://api.cloudinary.com/v1_1/why-i-buy/image/upload` $\to$ nhận về `secure_url` $\to$ lưu vào document Firestore `users/{uid}/wishlistItems/{itemId}.imageUrl`.
3. **Chỗ nào dùng code đó:**
   - Model lưu trữ: `WishlistItem.imageUrl` tại `lib/models/wishlist_item.dart` (dòng 49).
   - File service: `lib/services/cloudinary_storage_service.dart`.
   - Tích hợp tại: `lib/screens/photo_search_screen.dart` (dòng 38) và `lib/screens/add_item_screen.dart`.
4. **Dùng ở màn hình nào & Kiểm chứng:**
   - **Màn hình:** `PhotoSearchScreen` (Chụp ảnh tìm món), `AddItemScreen` (Thêm ảnh sản phẩm vào Wishlist), `RecordPurchaseScreen` (Chụp ảnh hoá đơn mua hàng làm minh chứng), `WishlistScreen` & `ItemDetailScreen` (Hiển thị ảnh qua CDN).
   - **Kiểm chứng:** Đăng nhập Cloudinary Media Library Dashboard $\to$ thư mục `why_i_buy/items` thấy ảnh vừa upload xuất hiện với dung lượng giảm từ 3.2MB xuống còn ~142KB. Thêm query `c_fill,w_150,h_150` trên trình duyệt để kiểm chứng tự động crop ảnh. Tắt mạng khi tải: app thông báo lỗi và giữ lại form dữ liệu để người dùng bấm thử lại.

---

### 📌 CÔNG NGHỆ 03: FIREBASE CLOUD STORAGE & BÁO CÁO PDF (Slides 11 – 13)
1. **What, Why & How:**
   - **What & Why:** Dịch vụ lưu trữ tệp đám mây quy mô lớn, dùng để quản lý báo cáo chi tiêu tháng (.pdf) cá nhân hóa của người dùng; nhúng font chuẩn tiếng Việt `Be Vietnam Pro` (SIL OFL) để không bị lỗi ký tự ô vuông hay mất ký hiệu "₫".
   - **How & Security Rules:** Storage Bucket `prm393-34056.firebasestorage.app`. Quy tắc bảo mật trong `firebase/storage.rules`:
     ```
     match /reports/{userId}/{fileName} {
       allow read, write: if request.auth != null && request.auth.uid == userId;
     }
     ```
   - **Quyết định D7:** Dựng PDF offline trực tiếp trên máy bằng gói `pdf` và chia sẻ bằng gói `printing` (`ReportShareService`).
2. **Chỗ nào dùng code đó:**
   - File: `lib/services/report_service.dart` (dòng 30–70) và `lib/services/report_share_service.dart`.
   - Hàm: `generateMonthlyReportPdf()`, `sharePdf()`, `previewPdf()`.
   - Tuân thủ **CR-02 (Single Responsibility)**: Tách riêng việc tạo nội dung PDF và việc gửi/in tệp.
3. **Dùng ở màn hình nào & Kiểm chứng:**
   - **Màn hình:** `MonthlyReflectionScreen` (Chiêm nghiệm tháng: nút [Xuất và chia sẻ PDF]), `InsightsScreen` (Góc nhìn chi tiêu).
   - **Kiểm chứng:** Thực thi kịch bản TC-07 trong `docs/test-plan.md` $\to$ Bảng chia sẻ Android mở ra kèm file `why-i-buy_yyyy-MM.pdf`. Kiểm tra font chữ hiển thị sắc nét tiếng Việt. Kiểm tra Security Rules: tài khoản khác không được phép đọc file của người khác.

---

### 📌 CÔNG NGHỆ 04: FIREBASE CLOUD MESSAGING (FCM) (Slides 14 – 17)
1. **What & Why:**
   - **What:** Dịch vụ thông báo đẩy đám mây thời gian thực, hỗ trợ 3 trạng thái của ứng dụng (Foreground, Background, Terminated) kèm Data Payload định tuyến.
   - **Why:** Nhắc nhở khi hết 3 ngày đắn đo (Cooling-off Expiry) để người dùng quay lại đưa ra quyết định mua hay từ bỏ; cảnh báo giờ vàng Sale (11.11, Shopee Payday); lưu toàn bộ tin nhắn vào Hộp thư nội bộ.
2. **How & Cơ chế đăng ký:**
   - Cấu hình quyền `POST_NOTIFICATIONS` trên Android 13+ trong `AndroidManifest.xml`.
   - `NotificationService` xin quyền `requestPermission()` và lấy token `_fcm.getToken()`.
   - Lưu token vào Firestore: `users/{uid}/fcmTokens/{token}`.
   - Xử lý đa trạng thái: Foreground qua `onMessage`, Background qua `onMessageOpenedApp`, Terminated qua `_firebaseMessagingBackgroundHandler` với annotation `@pragma('vm:entry-point')`.
3. **Chỗ nào dùng code đó:**
   - File: `lib/services/notification_service.dart` (dòng 40–95) và `lib/services/notification_history_store.dart`.
   - Annotation: `@pragma('vm:entry-point')` ngăn trình biên dịch R8 xóa nhầm hàm background handler khi build Release APK.
   - Hàm: `_navigateByPayload(message.data)` trích xuất trường `target` để mở đúng màn hình chi tiết món đồ.
4. **Dùng ở màn hình nào & Kiểm chứng:**
   - **Màn hình:** `InboxScreen` (Hộp thư thông báo trong app), `ReminderPermissionScreen` (Xin quyền), màn hình khoá và khay hệ thống.
   - **Kiểm chứng:** Gửi tin thử từ *Firebase Console Messaging* $\to$ hiện thông báo trên thanh hệ thống. Gọi API `spring-boot-push` tại cổng 8080 (`POST /api/push/send`) $\to$ máy ảo nhận tin thành công. Kiểm thử từ chối quyền (TC-09) không làm gián đoạn ứng dụng.

---

### 📌 CÔNG NGHỆ 05: GOOGLE ANALYTICS FOR FIREBASE (Slides 18 – 21)
1. **What & Why:**
   - **What:** Công cụ phân tích hành vi người dùng theo Event-driven của Google, hỗ trợ bảng DebugView theo dõi thời gian thực.
   - **Why:** Đo lường tỷ lệ hoãn mua và kiềm chế chi tiêu thành công. **Tuyệt đối NO PII**: không gửi email, tên người dùng, tên sản phẩm cụ thể hay số tiền chính xác; sử dụng kỹ thuật phân khúc giá `AmountBucket` (`under_100k`, `100k_500k`, `500k_1m`, `over_5m`).
2. **How & Kế hoạch sự kiện:**
   - Đăng ký `FirebaseAnalyticsObserver` vào `navigatorObservers` của `MaterialApp`.
   - Triển khai danh mục 10+ sự kiện chuẩn hóa trong `docs/analytics-plan.md` (`login`, `logout`, `search`, `add_to_wishlist`, `view_item_detail`, `make_decision`, `export_report`, `budget_set`).
   - Gắn `setUserId(uid)` sau khi đăng nhập (xoá về null khi đăng xuất).
3. **Chỗ nào dùng code đó:**
   - File: `lib/services/analytics_service.dart` (dòng 25–70) và `lib/services/analytics_events.dart`.
   - Lệnh `_log()` được bọc trong try-catch, nếu tracking lỗi không bao giờ làm gián đoạn luồng nghiệp vụ của người dùng.
4. **Dùng ở màn hình nào & Kiểm chứng:**
   - **Màn hình:** `HomeScreen`, `AddItemScreen`, `ItemDetailScreen`, `BudgetScreen`, `MonthlyReflectionScreen`.
   - **Kiểm chứng trên DebugView:** Kích hoạt thiết bị qua lệnh ADB chuẩn xác:
     ```bash
     adb shell setprop debug.firebase.analytics.app com.group07.whyibuy
     ```
     Mở Firebase Console > Analytics > DebugView $\to$ quan sát thấy từng sự kiện xuất hiện ngay trên luồng thời gian kèm tham số (ví dụ: `decision = 'skipped'`).

---

### 📌 CÔNG NGHỆ 06: FIREBASE CRASHLYTICS (Slides 22 – 25)
1. **What & Why:**
   - **What:** Hệ thống chẩn đoán và báo cáo sự cố ứng dụng thời gian thực; phân loại rõ ràng giữa Fatal Crash và Handled Non-fatal Error.
   - **Why:** Đảm bảo ứng dụng không chết âm thầm; dữ liệu nhập dở (draft) được lưu giữ; đính kèm Custom Key (`screen`, `app_scope`) và `userId` để khoanh vùng sự cố nhanh chóng.
2. **How & Cơ chế đăng ký:**
   - Khởi tạo toàn cục trong `main()`: `FlutterError.onError = recordFlutterFatalError`, `PlatformDispatcher.instance.onError = recordError(fatal: true)`.
   - `ScreenKeyObserver` tự động lắng nghe và cập nhật key `screen` theo route hiện tại.
3. **Chỗ nào dùng code đó:**
   - File: `lib/services/crashlytics_service.dart` (dòng 20–75).
   - Hàm: `forceCrashForTesting()` (gắn key `test_scenario: lab3_verification_forced_crash` và gọi `_crashlytics.crash()`), `recordHandledError()`, `logCrashToFirestore()`.
4. **Dùng ở màn hình nào & Kiểm chứng:**
   - **Màn hình:** `ProfileScreen > Dev Settings` (nút "Kích hoạt Crash thử nghiệm"), các khối catch của `WishlistScreen` và `PhotoSearchScreen`.
   - **Kiểm chứng:** Bấm nút crash thử nghiệm $\to$ app văng $\to$ mở lại app để SDK gửi báo cáo. Mở Firebase Console > Crashlytics $\to$ sự cố xuất hiện kèm stack trace Dart và nhãn `test_scenario: lab3_verification_forced_crash`.

---

### 📌 CÔNG NGHỆ 07: FIREBASE REMOTE CONFIG (Slides 26 – 29)
1. **What & Why:**
   - **What:** Dịch vụ quản trị cấu hình tham số từ xa trên đám mây; cập nhật giao diện và tính năng tức thì mà không cần người dùng tải bản cập nhật mới (Zero Re-deploy).
   - **Why:** Thử nghiệm A/B số ngày hạ nhiệt (`cooling_off_days: 3 -> 5`); công tắc bật/tắt khẩn cấp tính năng AI (`enable_ai_insight`); cập nhật danh sách ngày hội sale (`sale_calendar`) dạng JSON.
2. **How & Cơ chế đăng ký:**
   - Khai báo bộ giá trị mặc định trong `RemoteConfigService.defaults` đồng bộ với `firebase/remote-config-defaults.json`.
   - Cấu hình cache: `minimumFetchInterval = 0` khi debug và 1 giờ khi release; hàm `fetchAndActivate()`.
3. **Chỗ nào dùng code đó:**
   - File: `lib/services/remote_config_service.dart` (dòng 20–80).
   - Getters: `coolingOffDays`, `isAiInsightEnabled`.
4. **Dùng ở màn hình nào & Kiểm chứng:**
   - **Màn hình:** `WishlistScreen` (Badge đếm ngược số ngày đắn đo), `InsightsScreen` (Ẩn/hiện card AI), `HomeScreen` (Giới hạn số món hiển thị).
   - **Kiểm chứng Before / After (TC-08):** Đổi `cooling_off_days` từ 3 thành 5 trên Firebase Console $\to$ Bấm [Cập nhật Remote Config (Live Fetch)] tại màn hình Cá nhân $\to$ UI lập tức đổi sang đếm ngược 5 ngày mà KHÔNG cần build lại app.

---

### 📌 PHẦN 4: ĐẢM BẢO CHẤT LƯỢNG (QA), AI CODE REVIEW & KẾT LUẬN (Slides 30 – 32)
1. **ARTEMIS E2E Testing:**
   - Thực thi 10 ca kiểm thử chuẩn hóa (TC-01 đến TC-10) và 9 ca kiểm thử tài khoản liên kết (ACC-01 đến ACC-09) theo `docs/test-plan.md`.
   - Chạy 3 lượt/ca (3/3 planned) trên thiết bị thật/máy ảo qua giao thức ADB.
   - Tỷ lệ thành công: 100% pass rate; phiên thử nghiệm khám phá (Exploratory Testing 20 phút) duy trì 60 FPS ổn định.
2. **AI Code Review:**
   - Hồ sơ thực tế tại `docs/code-review.md` với các phát hiện được chấp nhận và commit sửa đổi:
     - **CR-01 (Architecture):** Widget gọi trực tiếp Firestore $\to$ Chuyển sang `WishlistService` và `WishlistViewModel` (Commit `9185cc7`).
     - **CR-02 (Maintainability):** Tách `ReportService` và `ReportShareService` (Commit `72a94db`).
     - **CR-03 (Security):** Bỏ `userId` thủ công, bảo vệ bằng Security Rules (Commit `7e16045`).
     - **CR-04 (Performance):** Đổi sang `watchItems` snapshots stream.
     - **CR-05 (Accessibility):** Tăng kích thước touch targets $\ge 48\text{dp}$ (Commit `6a33e12`).
3. **Tổng kết & Bài học kinh nghiệm:**
   - Ranh giới phân tầng MVVM giúp bảo trì độc lập và viết test giả lập dễ dàng.
   - Kết hợp Cloudinary giải quyết triệt để bài toán hạn ngạch của Firebase gói Spark (D7).
   - Kho mã nguồn: `https://github.com/hoanghuan2005/prm393_lab03`.
