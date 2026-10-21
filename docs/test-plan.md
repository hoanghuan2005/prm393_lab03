# Automated E2E Test Plan (Kịch bản kiểm thử E2E với Google ARTEMIS)
**Dự án**: Why I Buy – The Psychology of Money  
**Môn học**: PRM393 – Mobile Programming (Lab 3)  
**Công cụ kiểm thử**: Google ARTEMIS (Android Agent) + Pytest

---

## 1. Danh sách luồng quan trọng & Màn hình liên kết
1. **Auth Flow**: `LoginScreen` ➔ `HomeScreen`
2. **Wishlist Flow**: `HomeScreen` ➔ `WishlistScreen` ➔ `AddItemScreen` ➔ `ItemDetailScreen`
3. **Decision & Cooldown Flow**: `ItemDetailScreen` ➔ Cập nhật trạng thái Mua/Chờ/Bỏ qua ➔ `HomeScreen`
4. **Monthly Reflection & Export Flow**: `MonthlyReflectionScreen` ➔ Render PDF ➔ Upload Storage
5. **Firebase Demo & Remote Config Flow**: `ProfileScreen` ➔ Đổi tham số Remote Config ➔ Xem Crashlytics / FCM

---

## 2. Danh mục 10 Test Cases chi tiết (E2E Test Matrix)

| ID | Flow | Điều kiện đầu (Precondition) | Các bước thực hiện (Steps) | Kết quả kỳ vọng (Expected Result) | Loại test | Kết quả chạy |
|:---:|:---|:---|:---|:---|:---:|:---:|
| **TC-01** | Sign-in | App vừa cài đặt, trạng thái chưa đăng nhập | Mở app ➔ Chạm nút "Đăng nhập với Google" ➔ Chọn tài khoản test trên hộp thoại hệ thống | Đăng nhập thành công, chuyển vào Trang chủ (Hub), thanh Navigation Bar hiển thị đầy đủ | Native Interaction | Planned (3/3) |
| **TC-02** | Add Item | Đã đăng nhập, ở Trang chủ | Nhấn nút (+) Thêm món ➔ Nhập tên "Áo hoodie Shopee", giá "350000", chọn động cơ "Cảm xúc" ➔ Nhấn [Lưu vào Wishlist] | Món xuất hiện trong tab Đang cân nhắc với nhãn Cooldown 3 ngày | Happy path | Planned (3/3) |
| **TC-03** | Error Input | Đã đăng nhập, ở màn hình Thêm món | Để trống ô Tên sản phẩm ➔ Nhấn [Lưu vào Wishlist] | Hệ thống không gửi dữ liệu, hiển thị thông báo lỗi "Vui lòng nhập tên sản phẩm" | Error path | Planned (3/3) |
| **TC-04** | Search & Filter | Đã đăng nhập, danh sách có nhiều món | Vào tab Wishlist ➔ Gõ từ khóa "Áo hoodie" vào ô tìm kiếm | Danh sách chỉ lọc ra các món có tên chứa "Áo hoodie", đếm số kết quả > 0 | Happy path | Planned (3/3) |
| **TC-05** | Empty Search | Đã đăng nhập, ở tab Wishlist | Gõ từ khóa ngẫu nhiên không tồn tại "xyz999abc" | Màn hình hiển thị `EmptyView` với thông điệp "Không tìm thấy món nào phù hợp" | Error path | Planned (3/3) |
| **TC-06** | Make Decision | Đã đăng nhập, có món trong danh sách | Mở chi tiết món ➔ Nhấn nút [Bỏ qua - Tiết kiệm] trong Thẻ quyết định ➔ Xác nhận | Món được chuyển trạng thái "Đã bỏ qua", số tiền tiết kiệm trên Hub tăng lên tương ứng | Happy path | Planned (3/3) |
| **TC-07** | Export PDF | Đã đăng nhập, có dữ liệu chi tiêu | Mở tab Chiêm nghiệm ➔ Nhấn nút [Xuất báo cáo PDF] | App tạo file PDF, thanh tiến trình upload hiển thị và xuất hiện thông báo thành công kèm URL | Happy path | Planned (3/3) |
| **TC-08** | Remote Config | Đã đăng nhập, mở màn hình Profile/Settings | Kiểm tra số ngày hoãn hiển thị trên màn hình (mặc định 3 ngày) | Giá trị số ngày hoãn khớp với cấu hình Remote Config tải về từ Firebase Console | Happy path | Planned (3/3) |
| **TC-09** | Permission & Notification | Đã đăng nhập trên Android 13+ | Vào phần Cài đặt thông báo ➔ Bật nhận thông báo đợt Sale | Hộp thoại Native xin quyền thông báo của Android hiện ra ➔ Bấm Allow | Native Interaction | Planned (3/3) |
| **TC-10** | Sign-out | Đang ở tài khoản đăng nhập | Vào màn hình Cá nhân ➔ Nhấn nút [Đăng xuất] ➔ Xác nhận | Xóa dữ liệu phiên làm việc, app tự động điều hướng quay trở lại màn hình Đăng nhập | Happy path | Planned (3/3) |

---

## 3. Kế hoạch phiên kiểm thử thăm dò (Exploratory Testing Session)
* **Thời lượng**: 20 phút chạy tự do với Google ARTEMIS (Profile Pro).
* **Mục tiêu**: Thử nghiệm các thao tác vuốt nhanh, xoay màn hình, mất kết nối mạng đột ngột khi đang tải dữ liệu để tìm kiếm lỗi giao diện (*Overflow pixels*) và lỗi rò rỉ trạng thái (*State leaks*).
