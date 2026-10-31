# Automated E2E Test Plan (Kịch bản kiểm thử E2E với Google ARTEMIS)
**Dự án**: Why I Buy – The Psychology of Money  
**Môn học**: PRM393 – Mobile Programming (Lab 3)  
**Công cụ kiểm thử**: Google ARTEMIS (Android Agent) + Pytest, chạy tay trên máy (nhóm không có CI và chưa viết unit/widget test – xem [`decisions.md`](decisions.md))

---

## 1. Danh sách luồng quan trọng & Màn hình liên kết
1. **Auth Flow**: `LoginScreen` ➔ `HomeScreen`
2. **Wishlist Flow**: `HomeScreen` ➔ `WishlistScreen` ➔ `AddItemScreen` ➔ `ItemDetailScreen`
3. **Decision & Cooldown Flow**: `ItemDetailScreen` ➔ Cập nhật trạng thái Mua/Chờ/Bỏ qua ➔ `HomeScreen`
4. **Monthly Reflection & Export Flow**: `MonthlyReflectionScreen` ➔ Tạo PDF trên máy ➔ Chia sẻ qua bảng chia sẻ hệ thống
5. **Firebase Demo & Remote Config Flow**: `ProfileScreen` ➔ Đổi tham số Remote Config ➔ Xem Crashlytics / FCM

---

## 2. Danh mục 10 Test Cases chi tiết (E2E Test Matrix)

| ID | Flow | Điều kiện đầu (Precondition) | Các bước thực hiện (Steps) | Kết quả kỳ vọng (Expected Result) | Loại test | Kết quả chạy |
|:---:|:---|:---|:---|:---|:---:|:---:|
| **TC-01** | Sign-in | App vừa cài đặt, trạng thái chưa đăng nhập | Mở app ➔ Chạm nút "Đăng nhập với Google" ➔ Chọn tài khoản test trên hộp thoại hệ thống | Đăng nhập thành công, chuyển vào Trang chủ (Hub), thanh Navigation Bar hiển thị đầy đủ | Native Interaction | Planned (3/3) |
| **TC-02** | Add Item | Đã đăng nhập, ở Trang chủ | Nhấn nút (+) Thêm món ➔ Nhập tên "Áo hoodie Shopee", giá "350000", chọn động cơ "Cảm xúc" ➔ Nhấn [Lưu vào Wishlist] | Món xuất hiện trong danh sách với trạng thái "Đang cân nhắc" và đếm ngược thời gian cân nhắc (số ngày theo cài đặt / Remote Config) | Happy path | Planned (3/3) |
| **TC-03** | Error Input | Đã đăng nhập, ở màn hình Thêm món | Để trống ô Tên sản phẩm ➔ Nhấn [Lưu vào Wishlist] | Hệ thống không gửi dữ liệu, hiển thị thông báo lỗi "Vui lòng nhập tên món" | Error path | Planned (3/3) |
| **TC-04** | Search & Filter | Đã đăng nhập, danh sách có nhiều món | Vào tab Wishlist ➔ Gõ từ khóa "Áo hoodie" vào ô tìm kiếm | Danh sách chỉ lọc ra các món có tên chứa "Áo hoodie", đếm số kết quả > 0 | Happy path | Planned (3/3) |
| **TC-05** | Empty Search | Đã đăng nhập, ở tab Wishlist | Gõ từ khóa ngẫu nhiên không tồn tại "xyz999abc" | Màn hình hiển thị `EmptyView` với thông điệp "Không tìm thấy món nào phù hợp với bộ lọc hiện tại" | Error path | Planned (3/3) |
| **TC-06** | Make Decision | Đã đăng nhập, có món "Đang cân nhắc" | Mở chi tiết món ➔ Nhấn nút [Bỏ qua] | Quay về danh sách, món ở trạng thái "Bỏ qua"; SnackBar `Đã bỏ qua "<tên món>".` có nút "Hoàn tác" và tự tắt sau 5 giây; Firestore có thêm decision `skip` | Happy path | Planned (3/3) |
| **TC-07** | Export PDF | Đã đăng nhập, có dữ liệu chi tiêu | Mở Góc nhìn ➔ [Xem chiêm nghiệm tháng] ➔ Nhấn [Xuất và chia sẻ PDF] | App tạo PDF trên máy, bảng chia sẻ của Android mở ra với file `why-i-buy_yyyy-MM.pdf`; sau khi chia sẻ hiện "Đã tạo why-i-buy_yyyy-MM.pdf." | Happy path | Planned (3/3) |
| **TC-08** | Remote Config | Đã đăng nhập, Wishlist có ít nhất 3 món | Firebase Console ➔ Remote Config: đặt `max_wishlist_items_shown` = 2 ➔ Publish ➔ Trong app vào Cá nhân, nhấn [Cập nhật Remote Config (Live Fetch)] ➔ Mở Wishlist | Danh sách chỉ hiện 2 món, cuối danh sách có "Đang hiện 2/N món." và nút "Xem thêm …"; đặt lại 20 rồi cập nhật thì hiện đủ món. Khi mất mạng, app dùng giá trị mặc định 20 | Happy path | Planned (3/3) |
| **TC-09** | Permission & Notification | App mới cài trên Android 13+, đã đăng nhập, `sale_reminder_enabled` = true | Cá nhân ➔ Nhấn [Bật thông báo] ➔ Hộp thoại quyền của Android ➔ Allow ➔ Đưa app xuống nền ➔ Firebase Console gửi thông báo thử, Custom data `type` = `sale`, `sale_type` = `payday` ➔ Chạm thông báo | App mở "Danh sách cho đợt sale" của đợt kế tiếp (hoặc đợt trong `sale_id`); DebugView có `click_sale_reminder` với `sale_type` = `payday`; thông báo nằm trong danh sách thông báo ở Cá nhân. Từ chối quyền thì app vẫn chạy, nút [Bật thông báo] vẫn còn | Native Interaction | Planned (3/3) |
| **TC-10** | Sign-out | Đang ở tài khoản đăng nhập | Vào màn hình Cá nhân ➔ Nhấn nút [Đăng xuất tài khoản] | Xóa dữ liệu phiên làm việc, app tự động điều hướng quay trở lại màn hình Đăng nhập | Happy path | Planned (3/3) |

---

## 3. Kế hoạch phiên kiểm thử thăm dò (Exploratory Testing Session)
* **Thời lượng**: 20 phút chạy tự do với Google ARTEMIS (Profile Pro).
* **Mục tiêu**: Thử nghiệm các thao tác vuốt nhanh, xoay màn hình, mất kết nối mạng đột ngột khi đang tải dữ liệu để tìm kiếm lỗi giao diện (*Overflow pixels*) và lỗi rò rỉ trạng thái (*State leaks*).
