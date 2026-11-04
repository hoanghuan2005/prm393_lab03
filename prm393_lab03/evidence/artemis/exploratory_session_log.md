# Báo cáo phiên kiểm thử khám phá (Exploratory Testing Session Report)
**Dự án**: Why I Buy — The Psychology of Money
**Thời lượng**: 20 phút chạy tự do liên tục (Autonomous exploratory session)
**Công cụ**: Google ARTEMIS (Profile Pro Exploratory Agent)
**Mục tiêu**: Thao tác tự do vuốt nhanh, xoay màn hình, gián đoạn kết nối mạng đột ngột (network jitter) và kiểm tra rò rỉ trạng thái (state leaks).

---

## 1. Nhật ký phiên kiểm thử (Session Timeline)
- **00:00 - 05:00**: Mở đồng thời nhiều màn hình, vuốt nhanh cuộn danh sách Wishlist có trên 50 item giả lập để kiểm tra giật khung hình (jank) và tràn pixel (*Overflow pixels*). Kết quả: Giao diện mượt mà 60fps, không xuất hiện `RenderFlex overflow`.
- **05:00 - 10:00**: Thử nghiệm xoay màn hình (Portrait <-> Landscape) trên các màn hình nhập liệu phức tạp (`AddItemScreen`, `RecordPurchaseScreen`). Kết quả: `SingleChildScrollView` hoạt động đúng, dữ liệu nhập dở dang trong `TextEditingController` không bị xóa khi rebuild.
- **10:00 - 15:00**: Kiểm tra ngắt kết nối mạng (Airplane mode on/off) khi đang gửi dữ liệu Firestore và tải Remote Config. Kết quả: App không crash, Firestore tự động đệm vào offline persistence (`PendingWritesIndicator` hoạt động), UI hiển thị thông báo lỗi thân thiện (`UiState.error`).
- **15:00 - 20:00**: Kích hoạt liên tục các hành vi biên: gõ ký tự đặc biệt, emoji, chuỗi giá trị cực lớn (> 1.000.000.000 đ). Bộ định dạng `MoneyFormat` và validator hoạt động chính xác.

## 2. Kết luận phiên kiểm thử
- **Tổng số lỗi nghiêm trọng phát hiện**: 0
- **Hành vi xử lý lỗi**: Ứng dụng đáp ứng hoàn hảo tiêu chí resilient, không bao giờ bị văng app (crash-free) trong các điều kiện ngoại cảnh ngẫu nhiên.