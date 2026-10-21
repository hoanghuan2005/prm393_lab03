# Design Traceability Matrix (Ma trận truy vết thiết kế)
**Dự án**: Why I Buy – The Psychology of Money  
**Môn học**: PRM393 – Mobile Programming (Lab 3)  
**Tác giả**: Nhóm phát triển Why I Buy  
**Figma Spec**: [Why I Buy ver2](https://www.figma.com/design/VaPYFxfpx14tnQmOMSgdjP/Why-I-Buy-ver2?node-id=0-1)

---

## 1. Giới thiệu tổng quan (Project Overview)
Ứng dụng **Why I Buy** được xây dựng dựa trên triết lý từ cuốn sách *The Psychology of Money* (Morgan Housel), giải quyết vấn đề mua sắm bốc đồng (*Impulse Buying*) ở người trẻ thông qua:
1. **8 động cơ mua hàng cốt lõi**: Nhu cầu (*Need*), Mong muốn (*Want*), Khuyến mãi (*Discount*), Cảm xúc (*Emotion*), Ảnh hưởng MXH (*Social/FOMO*), Tiện lợi (*Convenience*), Quảng cáo (*Ads*), Khác (*Other*).
2. **Khoảng dừng tâm lý (Psychological Cooldown)**: Hoãn mua 3 ngày đối với các món đồ mua vì cảm xúc/FOMO, hoặc chờ đợt sale định kỳ của sàn TMĐT (ngày đôi, 15 giữa tháng, 25 lương về).
3. **Quy trình cân nhắc rõ ràng**: Đang cân nhắc (*Wishlist*) ➔ Quyết định (*Mua · Chờ · Bỏ qua*).
4. **Hệ thống dữ liệu đám mây (Cloud-Enabled Firebase)**: Xác thực Google Sign-In, lưu trữ Firestore, lưu trữ báo cáo PDF trên Cloud Storage, thông báo FCM, cấu hình động Remote Config và theo dõi sự cố Crashlytics.

---

## 2. Bảng ánh xạ Màn hình (Screen Traceability Matrix)

Hệ thống triển khai đầy đủ các màn hình được quy định từ Page `03 Final UI` trên Figma:

| STT | Tên màn hình Figma | Mã màn hình Figma | Flutter Route | Flutter Widget | Nguồn dữ liệu (Data Source) | Trạng thái |
|:---:|:---|:---:|:---|:---|:---|:---:|
| 1 | Onboarding & Chào mừng | `F7-01` | `/onboarding` | `OnboardingScreen` | Local Cache / SharedPreferences | Planned |
| 2 | Đăng nhập tài khoản | `F7-02` | `/login` | `LoginScreen` | `AuthService` (Google Sign-In) | Planned |
| 3 | Trang chủ tổng hợp (Hub) | `00 Trang chủ (Hub)` | `/home` | `HomeScreen` | `WishlistService` (Firestore) | Planned |
| 4 | Danh sách Smart Wishlist | `01 Smart Wishlist` | `/wishlist` | `WishlistScreen` | `WishlistService` (Firestore) | Planned |
| 5 | Chi tiết món & Thẻ quyết định | `03 Chi tiết món` | `/item-detail` | `ItemDetailScreen` | `WishlistService` (Firestore) | Planned |
| 6 | Thêm món mới (Form / Quét link) | `04 Thêm món` | `/add-item` | `AddItemScreen` | User Input / Firestore | Planned |
| 7 | Góc nhìn & Nhận định AI | `08 Góc nhìn (có AI)` | `/ai-insights` | `AiInsightsScreen` | `AiService` (Gemini API) | Planned |
| 8 | Chiêm nghiệm tháng & Xuất PDF | `09 Chiêm nghiệm` | `/reflection` | `MonthlyReflectionScreen` | `ReportService` / `StorageService` | Planned |
| 9 | Cá nhân & Firebase Demo Area | `Flow 7 Cá nhân` | `/profile` | `ProfileScreen` | `AuthService`, Remote Config, FCM, Crashlytics | Planned |

---

## 3. Bảng ánh xạ Luồng người dùng (User Flows & Recovery Paths)

### Flow 1: Lưu món & Kích hoạt khoảng hoãn tâm lý (Save Item & Cooldown)
* **Mục tiêu**: Người dùng thấy một món đồ muốn mua, lưu vào hệ thống và chọn động cơ mua sắm để nhận khuyến nghị làm nguội tâm lý.
* **Luồng chính (Happy Path)**:
  1. Người dùng mở màn hình Thêm món (`AddItemScreen`) hoặc dán link Shopee/Lazada.
  2. Nhập tên sản phẩm, giá dự kiến và chọn 1 trong 8 chip động cơ (ví dụ: *Cảm xúc* hoặc *Sale*).
  3. Bấm **[Lưu vào danh sách]**.
  4. Hệ thống phân tích: Nếu là *Cảm xúc*, kích hoạt đếm lùi 3 ngày cooldown. Nếu là *Sale*, kiểm tra lịch sale sàn (15 hoặc 25) và lên lịch nhắc nhở.
  5. Món xuất hiện trong tab *Đang cân nhắc* với badge trạng thái tương ứng.
* **Luồng rẽ nhánh (Alternative Path)**: Người dùng nhập giá thủ công hoặc không nhập giá (giá là tùy chọn).
* **Luồng lỗi & Phục hồi (Error & Recovery Path)**:
  * *Lỗi*: Không có kết nối mạng khi lưu.
  * *Phục hồi*: Hệ thống hiển thị SnackBar thông báo lỗi, lưu tạm vào cache offline và tự động retry khi có mạng trở lại.

---

### Flow 2: Đưa ra quyết định (Decision Making: Mua · Chờ · Bỏ qua)
* **Mục tiêu**: Sau thời gian cân nhắc, người dùng mở thẻ quyết định để chốt hành động mua sắm tỉnh táo.
* **Luồng chính (Happy Path)**:
  1. Người dùng mở `ItemDetailScreen` từ danh sách Wishlist.
  2. Xem lại phân tích lý do mua và thời gian đã hoãn.
  3. Chọn 1 trong 3 hành động:
     * **Mua ngay**: Đánh dấu đã mua, ghi nhận lý do thành công.
     * **Tiếp tục chờ**: Gia hạn thêm thời gian chờ sale.
     * **Bỏ qua (Tiết kiệm thành công)**: Đánh dấu không mua, ghi nhận số tiền tiết kiệm được vào bảng thành tích.
  4. Hệ thống đồng bộ trạng thái mới lên Cloud Firestore thời gian thực (`real-time stream`).
* **Luồng lỗi & Phục hồi (Error & Recovery Path)**:
  * *Lỗi*: Phiên đăng nhập hết hạn hoặc lỗi quyền truy cập Firestore.
  * *Phục hồi*: Hiển thị hộp thoại yêu cầu đăng nhập lại, bảo lưu dữ liệu đang thao tác tại local.

---

### Flow 3: Phân tích mô hình chi tiêu & Xuất báo cáo Cloud Storage (AI Reflection & PDF Upload)
* **Mục tiêu**: Người dùng xem phân tích xu hướng mua sắm theo động cơ trong tháng, xuất file PDF tổng hợp và upload lên Cloud Storage.
* **Luồng chính (Happy Path)**:
  1. Người dùng vào tab Chiêm nghiệm (`MonthlyReflectionScreen`).
  2. Xem biểu đồ tỉ lệ 8 động cơ mua hàng và tổng số tiền đã tránh lãng phí.
  3. Bấm **[Xuất báo cáo PDF]**.
  4. Hệ thống tạo tài liệu PDF tóm tắt chi tiêu trong bộ nhớ (`memory/file`).
  5. Upload file lên Firebase Cloud Storage theo đường dẫn bảo mật `reports/{userId}/summary_{yyyy_MM}.pdf`.
  6. Hiển thị thanh tiến trình tải lên (Progress indicator) và nút mở file/sao chép link tải về.
* **Luồng lỗi & Phục hồi (Error & Recovery Path)**:
  * *Lỗi*: Người dùng từ chối cấp quyền ghi file hoặc mất kết nối khi đang upload lên Storage.
  * *Phục hồi*: Hiển thị `ErrorView` với nút **[Thử lại] (Retry)**, giữ lại file PDF cục bộ để user không phải render lại.

---

## 4. Bảng ánh xạ Reusable Components (Design System to Code)

Tất cả các component từ Figma Page `05 Components` được đóng gói thành các Reusable Widget tại `lib/widgets/`:

| Tên Component Figma | Flutter Widget | Vị trí file | Biến thể & Trạng thái hỗ trợ |
|:---|:---|:---|:---|
| **App Button** | `AppButton` | `lib/widgets/app_button.dart` | Primary (Vàng), Secondary (Outline), Danger, Disabled, Loading state |
| **Motive Chip** | `MotiveChip` | `lib/widgets/motive_chip.dart` | 8 màu tương ứng 8 động cơ, Selected, Unselected, Compact |
| **Wishlist Card** | `WishlistCard` | `lib/widgets/wishlist_card.dart` | Hiển thị tên món, giá, badge động cơ, badge đếm ngược (Cooldown) |
| **Decision Card** | `DecisionCard` | `lib/widgets/decision_card.dart` | Thẻ phân tích tâm lý, 3 nút hành động (Mua, Chờ, Bỏ qua) |
| **Custom Text Field** | `AppTextField` | `lib/widgets/app_text_field.dart` | Normal, Focused, Error, Disabled, kèm Icon prefix/suffix |
| **Loading View** | `LoadingView` | `lib/widgets/states/loading_view.dart` | Hiển thị Spinner tải dữ liệu chuẩn Brand Color |
| **Empty View** | `EmptyView` | `lib/widgets/states/empty_view.dart` | Icon minh họa, thông điệp trống, nút Call-to-action |
| **Error View** | `ErrorView` | `lib/widgets/states/error_view.dart` | Thông báo lỗi thân thiện, nút Thử lại (Retry) |

---

## 5. Danh mục sai lệch thiết kế có ghi nhận (Design Deviations Log)

Tuân thủ quy định tại Mục 3 của Lab 3: Mọi sai lệch giữa Figma và code đều phải ghi rõ nguyên nhân:

| ID | Màn hình / Component | Thay đổi so với Figma | Lý do kỹ thuật / Nền tảng |
|:---:|:---|:---|:---|
| **DEV-01** | `LoginScreen` & `ProfileScreen` | Bổ sung màn hình Sign-In với Google và màn Profile chứa Firebase Demo Area | Figma ban đầu tập trung vào Flow mua sắm; theo yêu cầu mục 6 của Lab 3, cần có Sign-In phân luồng và Firebase Demo Area (FCM, Crashlytics, Remote Config). |
| **DEV-02** | `ItemDetailScreen` | Đổi cách hiển thị thời gian Cooldown từ text tĩnh sang bộ đếm thời gian động `StreamBuilder` | Để người dùng quan sát được thời gian chờ giảm dần chính xác theo thời gian thực. |
| **DEV-03** | `MonthlyReflectionScreen` | Bổ sung nút Xuất PDF và hiển thị tiến trình Upload lên Firebase Cloud Storage | Đáp ứng yêu cầu Lab 3: tạo ít nhất 1 file và upload lên Cloud Storage theo đường dẫn per-user (`reports/{uid}/...`). |
