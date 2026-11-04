# Why I Buy - Cổng Quản Trị Hệ Thống (Flutter Web Admin)

Dự án Cổng Quản Trị (Admin Portal) xây dựng bằng **100% Flutter Web** dành riêng cho đồ án môn **PRM393 - Lập trình Di động**.

---

## 🌟 Tính Năng Quản Trị Đã Triển Khai

1. **Dashboard & Chỉ số Thời Gian Thực**:
   - **Hôm nay có bao nhiêu user mới** (`+48 users`).
   - **Active users mở app hôm nay (DAU)** (`382 users`).
   - **Tải app nhưng chưa dùng (Dormant Users)** (`176 users` - đã tải app nhưng 0 purchase, 0 wishlist).
   - **Tổng chi tiêu đã theo dõi** và tỷ lệ phân bổ động cơ mua sắm (*Cảm xúc, Nhu cầu, Khuyến mãi, Thói quen, Đầu tư*).
   - **Banner cảnh báo đỏ** lập tức xuất hiện khi có tính năng bị crash.

2. **Quản Lý Người Dùng (Users Screen)**:
   - Thanh tìm kiếm tức thì theo tên, email, thiết bị, UID.
   - Thẻ lọc: *Tất cả*, *Mới hôm nay*, *Active hôm nay (DAU)*, *Tải chưa dùng (Dormant)*.
   - Bảng Data Table chuẩn web hiển thị chi tiêu, số món cân nhắc, thiết bị, ngày hoạt động cuối.
   - Nút **"Gửi Push"** chuyển sang giao diện gửi thông báo riêng cho từng tài khoản.

3. **Gửi Thông Điệp Push Broadcast (Push Screen)**:
   - Gửi thông báo đến từng nhóm người dùng, đặc biệt là nhóm **"Tải app nhưng chưa dùng"** để kích hoạt họ quay lại.
   - 3 mẫu thông điệp 1-Click thông minh: *Kích hoạt user chưa dùng*, *Cân nhắc đêm khuya*, *Tổng kết cuối tuần*.
   - Khung mô phỏng xem trước thông báo trên màn hình khóa điện thoại (Phone Mockup).
   - Lưu trữ lịch sử thông báo đã phát vào collection `admin_broadcasts` trên Firestore.

4. **Trợ Lý AI Gợi Ý Câu Hỏi Tự Vấn (AI Assistant Screen)**:
   - Tích hợp Gemini Behavioral Finance Engine: gợi ý các câu hỏi tự vấn trước khi mua hàng, câu hỏi chi tiêu đêm khuya, câu hỏi chiêm nghiệm cuối tháng.
   - **Custom AI Prompt**: Nhập bất kỳ món hàng nào (ví dụ: "Giày hiệu", "Trà sữa mỗi ngày"), AI sẽ tự động sinh câu hỏi tự vấn và thông điệp tương ứng.
   - 1-Click chuyển gợi ý AI thành thông báo Push.

5. **Cảnh Báo Sự Cố & Giám Sát Crash (Crash Monitor Screen)**:
   - Liệt kê cụ thể **chức năng nào bị crash** (*ShareIntentService*, *PatternsScreen*, *FirebaseAiService*).
   - Phân loại mức độ: *Fatal*, *Mức cao (High)*, *Cảnh báo (Warning)*.
   - Thống kê số người dùng bị ảnh hưởng và số lần xuất hiện.
   - Xem chi tiết **Crash Stack Trace** (file, dòng lỗi).
   - Nút **"Đánh dấu Đã Sửa"** cập nhật trạng thái lỗi ngay lập tức.

6. **Cơ Chế Dual-Mode (Firebase Live & Demo Mode)**:
   - Nút bấm trên thanh Header cho phép chuyển đổi tức thì giữa:
     - **Dữ liệu Demo**: Đầy đủ số liệu sinh động, đẹp mắt, phục vụ demo / chấm điểm ngay cả khi offline.
     - **Firebase Live**: Kết nối trực tiếp vào Cloud Firestore của dự án `prm393-34056`.

---

## 🚀 Cách Chạy Dự Án

Mở Terminal và gõ các lệnh sau:

```bash
cd d:\Ky_8_FA26\PRM393\PRM393_LAB3\prm393_flutter_admin
flutter run -d chrome
```

Trình duyệt Google Chrome sẽ tự động mở lên với giao diện quản trị Flutter Web!
