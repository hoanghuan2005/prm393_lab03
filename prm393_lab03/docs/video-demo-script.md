# Kịch bản quay Video Demo PRM393 Lab 3 (5–10 phút)
**Dự án**: Why I Buy — The Psychology of Money  
**Môn học**: PRM393 — Mobile Programming  
**Nhóm**: PRM393_Lab03  
**Thời lượng chuẩn**: 7–8 phút (Đạt khung 5–10 phút theo yêu cầu Slide 25)

---

## 🎬 TIMELINE CHI TIẾT KỊCH BẢN QUAY VIDEO

### Phút 00:00 – 01:00 | Giới thiệu thành viên, Bài toán & Kiến trúc MVVM
* **Hành động trên màn hình**: 
  - Hiển thị slide tiêu đề: Tên đề tài "Why I Buy", danh sách thành viên nhóm, mã sinh viên.
  - Chuyển sang sơ đồ kiến trúc MVVM: `View` (Flutter Screens) $\rightarrow$ `ViewModel` (ChangeNotifier) $\rightarrow$ `Service` $\rightarrow$ `Firebase SDK`.
* **Lời thoại**:
  > *"Kính chào thầy và các bạn, hôm nay nhóm em xin trình diễn sản phẩm Lab 3 môn PRM393 với đề tài 'Why I Buy - The Psychology of Money'. Ứng dụng giúp người dùng kiểm soát thói quen mua sắm bốc đồng bằng cơ chế thời gian cân nhắc (cooling-off) và phân tích tâm lý chi tiêu. Toàn bộ ứng dụng được xây dựng theo kiến trúc chuẩn MVVM, kết nối với Firebase Backend trên nền tảng gói Spark miễn phí."*

---

### Phút 01:00 – 02:30 | Luồng 1: Xác thực (Firebase Auth) & Quản lý Wishlist
* **Hành động trên màn hình**:
  - Mở app ở màn hình `LoginScreen`.
  - Nhấp nút "Đăng nhập với Google", chọn tài khoản Google test. Ứng dụng điều hướng vào `HomeScreen`.
  - Nhấn nút (+) Thêm món mới (`AddItemScreen`).
  - Nhập tên món "Áo hoodie Shopee", nhập giá "350.000 đ", chọn động cơ "Cảm xúc" (Emotion). Nhấn "Lưu vào Wishlist".
  - Món xuất hiện trong danh sách kèm đồng hồ đếm ngược thời gian cân nhắc (Cooling-off timer).
  - Thử nghiệm ô tìm kiếm: gõ "Áo hoodie" $\rightarrow$ lọc ra món; gõ "xyz999" $\rightarrow$ hiển thị `EmptyView`.
* **Lời thoại**:
  > *"Đầu tiên là dịch vụ Firebase Authentication. Người dùng đăng nhập qua tài khoản Google. Phiên đăng nhập được quản lý bằng authStateChanges. Tiếp theo là luồng thêm món vào danh sách mong muốn. Món đồ được gắn động cơ tâm lý và kích hoạt bộ đếm ngược thời gian cân nhắc. Hệ thống hỗ trợ tìm kiếm mượt mà với các trạng thái EmptyView và LoadingView chuẩn chỉnh."*

---

### Phút 02:30 – 04:00 | Luồng 2: Ra quyết định (Decision Flow) & Ghi nhận chi tiêu
* **Hành động trên màn hình**:
  - Nhấp vào chi tiết món "Áo hoodie" (`ItemDetailScreen`).
  - Bấm nút [Bỏ qua] (Skip) $\rightarrow$ SnackBar hiển thị: "Đã chuyển món sang Bỏ qua" kèm nút [Hoàn tác].
  - Mở tab Chi tiêu $\rightarrow$ Bấm nút "Ghi khoản chi" (`RecordPurchaseScreen`).
  - Nhập "Tai nghe", số tiền "100.000 đ", chọn nhóm "Công nghệ", động cơ "Muốn" $\rightarrow$ Lưu.
  - Mở Firebase Console $\rightarrow$ Cloud Firestore trên trình duyệt song song để người xem thấy document mới xuất hiện ngay lập tức tại `users/{uid}/purchases`.
* **Lời thoại**:
  > *"Sau khi hết thời gian cân nhắc, người dùng có thể đưa ra quyết định: Mua, Chờ hoặc Bỏ qua. Dữ liệu quyết định được lưu trữ trên Firestore. Khi người dùng ghi nhận khoản chi tiêu thực tế, dữ liệu được đồng bộ hóa tức thì lên Firestore collection `users/{uid}/purchases`."*

---

### Phút 04:00 – 05:30 | Luồng 3: Xuất báo cáo PDF, Cloud Storage & Trung tâm thông báo FCM
* **Hành động trên màn hình**:
  - Vào tab Cá nhân $\rightarrow$ Mở "Xem chiêm nghiệm tháng" (`MonthlyReflectionScreen`).
  - Nhấn "Xuất và tải lên Cloud Storage". Hiển thị thanh tiến độ `LinearProgressIndicator` chạy từ 0% đến 100% $\rightarrow$ Thông báo thành công và cung cấp URL tải về.
  - Chuyển sang màn hình `ProfileScreen`, phần **Trung tâm thông báo (FCM Notification Center)**:
    - Bật quyền thông báo trên Android 13+.
    - Từ Firebase Console gửi 1 tin nhắn test FCM.
    - App nhận thông báo ở cả chế độ Foreground và Background; tin nhắn được lưu vào danh sách hộp thư thông báo.
* **Lời thoại**:
  > *"Tại dịch vụ Cloud Storage, ứng dụng hỗ trợ tạo báo cáo PDF phân tích chi tiêu hàng tháng và tải lên bucket lưu trữ với quy tắc bảo mật storage.rules phân quyền theo UID. Tiếp theo là Firebase Cloud Messaging: Ứng dụng yêu cầu quyền runtime trên Android 13+, tiếp nhận thông báo ở cả 3 trạng thái và lưu vào Hộp thư thông báo nội bộ."*

---

### Phút 05:30 – 07:00 | Trình diễn Firebase Crashlytics & Remote Config (Thay đổi Live)
* **Hành động trên màn hình**:
  - Tại màn hình `ProfileScreen`:
    - Bấm nút "Kiểm thử Handled Error" $\rightarrow$ App ghi nhận 1 lỗi non-fatal mà không bị văng.
    - Bấm nút "Kích hoạt Crash thật" $\rightarrow$ App cố ý văng để tạo báo cáo crash.
    - Mở Firebase Console $\rightarrow$ Crashlytics: Cho xem lỗi crash vừa phát sinh kèm User ID và Custom Key `screen = /profile`.
  - Mở Firebase Console $\rightarrow$ Remote Config:
    - Tham số `cooling_off_days` đang là 3 ngày. Sửa thành 5 ngày và nhấn "Publish changes".
    - Mở lại app trên điện thoại: Thời gian cân nhắc lập tức cập nhật thành 5 ngày **mà không cần cài lại hay build lại ứng dụng**.
  - Mở Firebase Console $\rightarrow$ Analytics $\rightarrow$ DebugView:
    - Chỉ cho thầy thấy chuỗi các sự kiện `login`, `add_to_wishlist`, `make_decision`, `export_report` đã được ghi nhận đầy đủ, không lộ PII.
* **Lời thoại**:
  > *"Đây là khu vực thử nghiệm Crashlytics và Remote Config. Nhóm đã cấu hình bắt lỗi non-fatal và có nút kích hoạt crash có kiểm soát. Mọi sự cố đều được gắn User ID và màn hình phát sinh lỗi. Với Remote Config, chúng em thay đổi số ngày cân nhắc từ 3 lên 5 ngày trên Console, app ngay lập tức áp dụng giá trị mới theo thời gian thực."*

---

### Phút 07:00 – 08:30 | Kết quả E2E Testing với ARTEMIS & AI Code Review
* **Hành động trên màn hình**:
  - Mở terminal/IDE, quay màn hình chạy bộ test: `python e2e_test/run_artemis_suite.py`.
  - Chỉ cho thấy kết quả 10/10 test case E2E đạt 100% (30/30 lượt chạy thành công).
  - Mở file `docs/code-review.md`: Trình bày 5 phát hiện rà soát bằng AI (về kiến trúc MVVM, bảo mật token, hiệu năng Firestore streams) và chỉ ra 3 commit khắc phục tương ứng trên GitHub.
* **Lời thoại**:
  > *"Về quy trình kiểm thử tự động, nhóm đã xây dựng 10 ca kiểm thử đầu cuối bằng Google ARTEMIS. Mỗi ca chạy kiểm chứng 3 lần liên tiếp, đạt tỷ lệ thành công tuyệt đối 100%. Cuối cùng, trong quá trình phát triển, nhóm đã ứng dụng AI Code Review để phát hiện 5 vấn đề kỹ thuật và thực hiện refactor mã nguồn qua 3 commit rõ ràng. Video demo của nhóm đến đây là kết thúc, cảm ơn thầy đã theo dõi!"*
