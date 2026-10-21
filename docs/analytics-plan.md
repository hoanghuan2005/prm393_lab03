# Analytics Event Plan (Kế hoạch sự kiện Analytics)
**Dự án**: Why I Buy – The Psychology of Money  
**Môn học**: PRM393 – Mobile Programming (Lab 3)  
**Tác giả**: Nhóm phát triển Why I Buy  

---

## 1. Nguyên tắc thiết kế sự kiện Analytics
1. **Tuân thủ sự kiện tiêu chuẩn của Firebase**: Sử dụng các sự kiện khuyến nghị (`login`, `search`, `select_content`) và đặt tên dạng `snake_case` cho các sự kiện tùy chỉnh.
2. **Tuyệt đối không gửi thông tin định danh cá nhân (No PII)**: Không truyền email, tên thật, số điện thoại hoặc mật khẩu vào parameters.
3. **Mỗi sự kiện trả lời một câu hỏi sản phẩm (Product Question)**: Đảm bảo số liệu ghi nhận có giá trị phân tích hành vi người dùng và đo lường tỷ lệ chuyển đổi.

---

## 2. Bảng kế hoạch chi tiết (Analytics Events Matrix)

| STT | Event Name | Trigger | Parameters (type) | Question It Answers (Câu hỏi sản phẩm) |
|:---:|:---|:---|:---|:---|
| 1 | `login` | Đăng nhập Google thành công | `method` (string) | Có bao nhiêu người dùng hoạt động và quay trở lại ứng dụng mỗi tuần? |
| 2 | `search` | Người dùng tìm kiếm món trong Wishlist | `search_term` (string), `result_count` (int) | Người dùng tìm kiếm những sản phẩm nào nhiều nhất, và từ khóa nào không ra kết quả? |
| 3 | `add_to_wishlist` | Lưu thành công một món đồ mới | `motive` (string), `item_price` (double), `has_sale_date` (bool) | Động cơ mua hàng nào (Cảm xúc, Nhu cầu, Khuyến mãi) chiếm tỷ lệ cao nhất khi lưu món? |
| 4 | `view_item_detail` | Mở màn hình chi tiết món & Thẻ quyết định | `item_id` (string), `motive` (string), `days_in_cooldown` (int) | Các món đồ thuộc động cơ nào được người dùng mở lại xem nhiều nhất trong thời gian hoãn? |
| 5 | `make_decision` | Người dùng bấm chốt quyết định (Mua / Chờ / Bỏ qua) | `action` (string: "buy", "wait", "drop"), `motive` (string), `saved_amount` (double) | Tỷ lệ người dùng quyết định "Bỏ qua" (tiết kiệm tiền thành công) sau thời gian hoãn 3 ngày là bao nhiêu? |
| 6 | `export_report` | Tạo và upload báo cáo PDF lên Cloud Storage | `file_format` (string), `file_size_kb` (int), `item_count` (int) | Có bao nhiêu người dùng theo dõi và xuất báo cáo chiêm nghiệm tâm lý mua sắm cuối tháng? |
| 7 | `logout` | Người dùng chủ động đăng xuất | `session_duration_sec` (int) | Thời lượng trung bình một phiên hoạt động của người dùng là bao lâu trước khi đăng xuất? |
| 8 | `click_sale_reminder` | Người dùng nhấn vào thông báo đợt Siêu Sale | `sale_type` (string: "double_day", "mid_month", "payday") | Đợt sale định kỳ nào nhận được sự quan tâm và tương tác nhiều nhất từ người dùng? |
