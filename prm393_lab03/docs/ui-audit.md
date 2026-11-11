# Rà giao diện U1–U4 — Why I Buy?

Cập nhật 10/11/2026. Mã gốc trước sửa UI: bde58fa. Chỉ thay đổi giao diện, token, câu chữ và test. Không đổi service, ViewModel, dữ liệu, điều hướng hoặc dependency.

## 1. Lỗi hiển thị tự động

Lượt gốc: **190/544 ca có lỗi**. Lượt gần nhất: **0/640 ca có lỗi**. Một ca là một màn/trạng thái × kích thước × cỡ chữ × theme. Bộ mở rộng có 40 loại màn/form/dialog, tổng 640 ca. Không dùng skip. Mặc định mọi FlutterError đều làm test thất bại; chế độ UI_AUDIT_RECORD_ONLY chỉ dùng để thu baseline trước sửa. Baseline có ít biến thể hơn bộ cuối, nên không coi hai mẫu là cùng một mẫu đo.

Dữ liệu đầy: tên món 60 ký tự, tên shop dài, giá 999.999.999 ₫, 20 khoản mua/20 món mong muốn; dữ liệu rỗng chạy riêng. Cuộn đầu/giữa/cuối danh sách. Camera dùng MobileScannerPlatform giả cho preview và lỗi quyền; AI dùng service giả, không gửi ảnh/dữ liệu ra mạng. Các màn chi tiết cần đối tượng đầu vào luôn có đối tượng mẫu; “rỗng” ở đó là danh sách/tài khoản phụ thuộc trống, không phải truyền null trái API của màn. Hai form thêm món/ghi khoản mua thực tế là màn riêng, không tạo bottom sheet giả cho hai form đó.

Bảng dưới ghi **số ca lỗi/tổng ca**, trước → sau. L/D là light/dark; mỗi ô gộp dữ liệu rỗng/đầy. sale_screens gộp ba màn sale. Đủ 29 file màn hình, kể cả hai file dev.

| File trong lib/screens | 360 · 1.0 L | 360 · 1.0 D | 360 · 1.3 L | 360 · 1.3 D | 412 · 1.0 L | 412 · 1.0 D | 412 · 1.3 L | 412 · 1.3 D |
|---|---|---|---|---|---|---|---|---|
| add_item_screen.dart | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 |
| budget_screen.dart | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 |
| compare_items_screen.dart | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 |
| dev/price_chart_gallery.dart | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 |
| dev/widget_gallery_screen.dart | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 |
| email_verification_screen.dart | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 |
| extension_qr_scan_screen.dart | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 |
| feedback_screen.dart | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 |
| history_screen.dart | 0/2 → 0/2 | 0/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 |
| home_screen.dart | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 1/2 → 0/2 | 1/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 |
| info_text_screen.dart | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 |
| insights_screen.dart | 0/2 → 0/2 | 0/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 |
| item_detail_screen.dart | 1/2 → 0/2 | 1/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 1/2 → 0/2 | 1/2 → 0/2 | 1/2 → 0/2 | 1/2 → 0/2 |
| login_screen.dart | 0/2 → 0/2 | 0/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 |
| main_navigation_screen.dart | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 1/2 → 0/2 | 1/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 |
| monthly_reflection_screen.dart | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 |
| onboarding_screen.dart | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 |
| patterns_screen.dart | 1/2 → 0/2 | 1/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 1/2 → 0/2 | 1/2 → 0/2 |
| photo_search_screen.dart | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 |
| pre_purchase_result_screen.dart | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 |
| pre_purchase_screen.dart | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 |
| price_history_screen.dart | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 |
| profile_screen.dart | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 |
| purchase_detail_screen.dart | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 |
| record_purchase_screen.dart | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 |
| reminder_permission_screen.dart | 0/2 → 0/2 | 0/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 |
| sale_screens.dart | 0/6 → 0/6 | 0/6 → 0/6 | 0/6 → 0/6 | 0/6 → 0/6 | 0/6 → 0/6 | 0/6 → 0/6 | 0/6 → 0/6 | 0/6 → 0/6 |
| shopping_profile_screen.dart | 0/2 → 0/2 | 0/2 → 0/2 | 2/2 → 0/2 | 2/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 |
| wishlist_screen.dart | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 | 0/2 → 0/2 |

Các ca bổ sung: đăng ký/quên mật khẩu, ghi khoản mua bước 2, thêm món/ghi khoản mua khi bàn phím chiếm 300px, bottom sheet ngân sách/chọn tháng/thông báo và dialog xác nhận xoá. Dữ liệu đầy còn có 20 đồ đang dùng, thẻ hồ sơ mua sắm dài, một món định mua từ tiện ích trình duyệt, 20 thông báo và kết quả nhận diện ảnh với preview PNG cùng 20 nơi bán tên dài. Đây là dữ liệu giả để kiểm tra layout, không xác nhận dịch vụ AI/FCM hoạt động.

### P1 và vị trí gốc trước sửa

| Vị trí bde58fa | Lỗi phát hiện | Trạng thái |
|---|---|---|
| lib/screens/onboarding_screen.dart:140:36 | A RenderFlex overflowed by 68 pixels on the right. | Đã sửa, bộ mở rộng đạt |
| lib/screens/onboarding_screen.dart:160:19 | A RenderFlex overflowed by 24 pixels on the right. | Đã sửa, bộ mở rộng đạt |
| lib/screens/login_screen.dart:412:12 | A RenderFlex overflowed by 13 pixels on the right. | Đã sửa, bộ mở rộng đạt |
| lib/screens/home_screen.dart:51:16 | A RenderFlex overflowed by 8.0 pixels on the right. | Đã sửa, bộ mở rộng đạt |
| lib/screens/home_screen.dart:745:19 | A RenderFlex overflowed by 58 pixels on the right. | Đã sửa, bộ mở rộng đạt |
| lib/screens/home_screen.dart:123:26 | A RenderFlex overflowed by 18 pixels on the right. | Đã sửa, bộ mở rộng đạt |
| lib/screens/history_screen.dart:57:16 | A RenderFlex overflowed by 20 pixels on the right. | Đã sửa, bộ mở rộng đạt |
| lib/screens/patterns_screen.dart:567:9 | A RenderFlex overflowed by 38 pixels on the right. | Đã sửa, bộ mở rộng đạt |
| lib/screens/patterns_screen.dart:108:16 | A RenderFlex overflowed by 20 pixels on the right. | Đã sửa, bộ mở rộng đạt |
| lib/screens/patterns_screen.dart:267:26 | A RenderFlex overflowed by 56 pixels on the right. | Đã sửa, bộ mở rộng đạt |
| lib/screens/patterns_screen.dart:389:41 | A RenderFlex overflowed by 17 pixels on the right. | Đã sửa, bộ mở rộng đạt |
| lib/screens/budget_screen.dart:96:16 | A RenderFlex overflowed by 102 pixels on the right. | Đã sửa, bộ mở rộng đạt |
| lib/screens/budget_screen.dart:449:11 | A RenderFlex overflowed by 61 pixels on the right. | Đã sửa, bộ mở rộng đạt |
| lib/screens/budget_screen.dart:224:38 | A RenderFlex overflowed by 63 pixels on the right. | Đã sửa, bộ mở rộng đạt |
| lib/screens/budget_screen.dart:259:14 | A RenderFlex overflowed by 14 pixels on the right. | Đã sửa, bộ mở rộng đạt |
| lib/screens/budget_screen.dart:413:11 | A RenderFlex overflowed by 38 pixels on the right. | Đã sửa, bộ mở rộng đạt |
| lib/screens/budget_screen.dart:584:11 | A RenderFlex overflowed by 50 pixels on the right. | Đã sửa, bộ mở rộng đạt |
| lib/screens/add_item_screen.dart:280:16 | A RenderFlex overflowed by 18 pixels on the right. | Đã sửa, bộ mở rộng đạt |
| lib/screens/item_detail_screen.dart:1022:25 | A RenderFlex overflowed by 108 pixels on the right. | Đã sửa, bộ mở rộng đạt |
| lib/screens/item_detail_screen.dart:592:23 | A RenderFlex overflowed by 48 pixels on the right. | Đã sửa, bộ mở rộng đạt |
| lib/widgets/decision_card_panel.dart:86:11 | A RenderFlex overflowed by 8.7 pixels on the right. | Đã sửa, bộ mở rộng đạt |
| lib/widgets/voucher_suggestion_card.dart:123:24 | A RenderFlex overflowed by 54 pixels on the right. | Đã sửa, bộ mở rộng đạt |
| lib/screens/item_detail_screen.dart:1008:22 | A RenderFlex overflowed by 41 pixels on the right. | Đã sửa, bộ mở rộng đạt |
| lib/screens/purchase_detail_screen.dart:114:16 | A RenderFlex overflowed by 84 pixels on the right. | Đã sửa, bộ mở rộng đạt |
| lib/screens/purchase_detail_screen.dart:550:24 | A RenderFlex overflowed by 24 pixels on the right. | Đã sửa, bộ mở rộng đạt |
| lib/screens/shopping_profile_screen.dart:74:16 | A RenderFlex overflowed by 16 pixels on the right. | Đã sửa, bộ mở rộng đạt |
| lib/screens/insights_screen.dart:50:16 | A RenderFlex overflowed by 43 pixels on the right. | Đã sửa, bộ mở rộng đạt |
| lib/screens/monthly_reflection_screen.dart:374:15 | A RenderFlex overflowed by 25 pixels on the right. | Đã sửa, bộ mở rộng đạt |
| lib/screens/monthly_reflection_screen.dart:58:16 | A RenderFlex overflowed by 36 pixels on the right. | Đã sửa, bộ mở rộng đạt |
| lib/screens/compare_items_screen.dart:48:16 | A RenderFlex overflowed by 90 pixels on the right. | Đã sửa, bộ mở rộng đạt |
| lib/screens/reminder_permission_screen.dart:68:18 | A RenderFlex overflowed by 119 pixels on the bottom. | Đã sửa, bộ mở rộng đạt |
| lib/screens/extension_qr_scan_screen.dart:99:16 | A RenderFlex overflowed by 54 pixels on the right. | Đã sửa, bộ mở rộng đạt |
| lib/widgets/states/empty_view.dart:30:18 | A RenderFlex overflowed by 2.0 pixels on the bottom. | Đã sửa, bộ mở rộng đạt |
| lib/widgets/states/error_view.dart:27:18 | A RenderFlex overflowed by 80 pixels on the bottom. | Đã sửa, bộ mở rộng đạt |

Các P1 phát hiện sau khi mở rộng fixture: thông báo dài tràn dọc (`lib/widgets/app_header_actions.dart`, đổi sang cuộn); hàng giá AI tràn ngang (`lib/screens/photo_search_screen.dart`, giá dưới tên shop); nhãn độ tin cậy cạnh ảnh thiếu chỗ (`photo_search_screen.dart`, Flexible cho nội dung). Các ca này chạy cùng ma trận cuối.


## 2. Quét mã

Quét chỉ đọc bằng `node tool/ui_audit.mjs`. Đây là ứng viên cần đọc ngữ cảnh, không cộng số match regex thành số lỗi thật. Vị trí trong bảng này là dòng của mã gốc bde58fa để đối chiếu diff. Không phải mọi Text dài đều cần cắt: ghi chú/chính sách cho phép xuống dòng; tên trong danh sách dùng ellipsis; số tiền giữ đầy đủ.

| Loại | Match gốc | Match còn lại | Cách xử lý/ngoại lệ đã rà |
|---|---:|---:|---|
| spacing | 330 | 2 | Dùng AppDimens; offset mũi tên 52px và inset hệ thống là hình học, không phải khoảng cách nội dung. |
| typography | 343 | 9 | 167 TextStyle có cỡ số chuyển sang AppTextStyles. Các override chỉ weight/color và cỡ do đo biểu đồ kế thừa typography, không tự đặt cỡ lẻ. withInheritedColor giữ foreground của nút/ngữ cảnh. |
| radius | 105 | 0 | Chuyển BorderRadius.circular sang borderSmall/Medium/Large/XLarge/Pill. |
| color | 12 | 1 | Không còn hex hoặc Colors màu cứng trong screens/widgets. isDark còn lại chọn icon sáng/tối, không phân nhánh màu. |
| touch | 84 | 83 | Back/avatar, nút xem tất cả, chọn tháng/kỳ, chip lịch sử, sửa ngân sách và nút mã giảm giá được tăng lên >=48dp. Card/image có hitbox lớn; hình trang trí không phải control. Đánh giá thao tác thật ở U5 vẫn cần máy. |
| longText | 34 | 34 | Expanded/Wrap ở tiêu đề và hàng thông tin; tên shop/món ở list giới hạn dòng, nội dung chi tiết vẫn đọc đầy đủ. |
| copy | 30 | 9 | Bỏ câu Hãy/lời khen/dấu cảm thán và Wishlist/debug ngoài dev. Match còn lại là dấu ! toán tử null assertion trong nội suy Dart, không phải chữ hiển thị. |

### Danh sách file:dòng của ứng viên gốc

| File | Loại | Dòng gốc |
|---|---|---|
| lib/screens/add_item_screen.dart | spacing | 283, 384, 413 |
| lib/screens/add_item_screen.dart | typography | 286, 287, 395, 396 |
| lib/screens/add_item_screen.dart | radius | 360, 391 |
| lib/screens/add_item_screen.dart | touch | 273, 537 |
| lib/screens/add_item_screen.dart | copy | 641 |
| lib/screens/budget_screen.dart | spacing | 37, 99, 128, 135, 139, 155, 166, 178, 193, 208, 228, 253, 282, 290, 299, 324, 345, 354, 364, 397, 425, 448, 470, 485, 574, 575, 599, 620, 635, 673, 674, 695, 708 |
| lib/screens/budget_screen.dart | typography | 46, 47, 58, 102, 103, 158, 159, 171, 172, 200, 201, 231, 232, 293, 294, 348, 349, 358, 359, 380, 418, 419, 437, 438, 454, 455, 462, 463, 490, 491, 534, 535, 546, 603, 604, 612, 613, 641, 642, 702, 703, 711, 712, 721, 722 |
| lib/screens/budget_screen.dart | radius | 33, 220, 256, 280, 327, 374, 400, 433, 473, 529, 578, 591, 623, 677, 687 |
| lib/screens/budget_screen.dart | color | 404 |
| lib/screens/budget_screen.dart | touch | 89, 111, 262, 270, 308 |
| lib/screens/compare_items_screen.dart | spacing | 51 |
| lib/screens/compare_items_screen.dart | typography | 54, 55 |
| lib/screens/compare_items_screen.dart | touch | 41 |
| lib/screens/compare_items_screen.dart | longText | 108 |
| lib/screens/email_verification_screen.dart | copy | 116 |
| lib/screens/extension_qr_scan_screen.dart | spacing | 102, 122, 135, 148 |
| lib/screens/extension_qr_scan_screen.dart | typography | 105, 106 |
| lib/screens/extension_qr_scan_screen.dart | touch | 92 |
| lib/screens/extension_qr_scan_screen.dart | copy | 125, 126, 138, 140 |
| lib/screens/feedback_screen.dart | spacing | 76 |
| lib/screens/feedback_screen.dart | typography | 79, 80 |
| lib/screens/feedback_screen.dart | touch | 66 |
| lib/screens/feedback_screen.dart | copy | 43 |
| lib/screens/history_screen.dart | spacing | 60, 81, 112, 124, 133, 163, 174, 186, 191, 207, 212, 217, 222, 231, 243, 271, 291, 337, 393, 426, 438, 441, 466, 474, 486, 502, 519, 535, 550, 592, 602, 629, 663, 672 |
| lib/screens/history_screen.dart | typography | 63, 64, 127, 128, 237, 238, 248, 249, 282, 283, 294, 295, 430, 431, 453, 454, 489, 490, 511, 512, 523, 524, 557, 558, 606, 607, 652, 653, 666, 667, 675, 676, 688, 689 |
| lib/screens/history_screen.dart | radius | 110, 309, 372, 396, 449, 472, 539, 590, 595, 642 |
| lib/screens/history_screen.dart | touch | 50, 91, 99, 143, 468, 587 |
| lib/screens/history_screen.dart | longText | 650 |
| lib/screens/history_screen.dart | copy | 179 |
| lib/screens/home_screen.dart | spacing | 54, 68, 82, 87, 92, 97, 106, 127, 157, 176, 206, 231, 250, 263, 276, 289, 314, 340, 357, 368, 376, 401, 423, 451, 464, 477, 514, 523, 531, 544, 568, 613, 615, 659, 670, 710, 727, 744, 749, 765, 777 |
| lib/screens/home_screen.dart | typography | 57, 58, 75, 76, 130, 209, 210, 244, 245, 268, 269, 282, 283, 295, 296, 305, 324, 325, 331, 332, 381, 382, 390, 413, 414, 471, 472, 481, 482, 508, 509, 518, 519, 526, 527, 545, 548, 569, 572, 606, 607, 622, 623, 642, 643, 673, 674, 736, 737, 768, 769, 781, 782, 795, 796 |
| lib/screens/home_screen.dart | radius | 117, 179, 229, 237, 344, 366, 409, 449, 454, 618, 665, 719, 755 |
| lib/screens/home_screen.dart | color | 115, 543, 567 |
| lib/screens/home_screen.dart | touch | 218, 362, 445, 701 |
| lib/screens/home_screen.dart | longText | 734 |
| lib/screens/info_text_screen.dart | spacing | 39 |
| lib/screens/info_text_screen.dart | typography | 44, 45 |
| lib/screens/info_text_screen.dart | touch | 29 |
| lib/screens/info_text_screen.dart | longText | 41 |
| lib/screens/insights_screen.dart | spacing | 53, 74, 77, 79, 82, 92, 121, 150, 162, 208, 226, 247, 253, 275, 326, 349, 360, 364 |
| lib/screens/insights_screen.dart | typography | 56, 57, 167, 168, 230, 231, 257, 258, 278, 279, 353, 354, 367, 368 |
| lib/screens/insights_screen.dart | radius | 104, 124, 148, 211, 329, 345 |
| lib/screens/insights_screen.dart | touch | 43, 130, 139, 179 |
| lib/screens/insights_screen.dart | longText | 351 |
| lib/screens/item_detail_screen.dart | spacing | 347, 485, 511, 524, 555, 574, 600, 904, 1039, 1041, 1063, 1065 |
| lib/screens/item_detail_screen.dart | typography | 351, 352, 907, 909, 1053, 1054, 1076, 1077 |
| lib/screens/item_detail_screen.dart | radius | 500, 561, 880, 998, 1049, 1072, 1125 |
| lib/screens/item_detail_screen.dart | touch | 337, 363, 374, 506, 886 |
| lib/screens/item_detail_screen.dart | longText | 415, 576, 905 |
| lib/screens/item_detail_screen.dart | copy | 268, 450, 794, 1137 |
| lib/screens/login_screen.dart | spacing | 69, 76, 78, 85, 95, 98, 115, 134, 164, 192, 214, 226, 228, 239, 251, 262, 275, 326, 381, 396, 432, 445, 457 |
| lib/screens/login_screen.dart | typography | 435, 461, 463 |
| lib/screens/login_screen.dart | touch | 141, 171 |
| lib/screens/login_screen.dart | copy | 112, 125, 154, 507 |
| lib/screens/main_navigation_screen.dart | spacing | 236 |
| lib/screens/main_navigation_screen.dart | typography | 239, 240 |
| lib/screens/main_navigation_screen.dart | touch | 225 |
| lib/screens/monthly_reflection_screen.dart | spacing | 61 |
| lib/screens/monthly_reflection_screen.dart | typography | 64, 65 |
| lib/screens/monthly_reflection_screen.dart | touch | 51 |
| lib/screens/onboarding_screen.dart | spacing | 64, 74, 90, 123, 150, 157, 168, 193, 196, 291, 295, 311, 325, 337, 344, 351, 372, 402, 415, 438, 441, 447, 465, 476, 487, 500, 513, 535, 547, 560, 564, 580, 594, 617, 620, 626, 654, 666, 687, 699, 703, 715, 734, 738, 754, 768, 793, 804 |
| lib/screens/onboarding_screen.dart | typography | 77, 78, 97, 98, 145, 146, 171, 172, 302, 303, 316, 317, 330, 331, 409, 410, 418, 419, 494, 495, 503, 504, 523, 524, 571, 572, 585, 586, 599, 600, 657, 658, 676, 677, 719, 720, 745, 746, 759, 760, 773, 774, 807, 808 |
| lib/screens/onboarding_screen.dart | radius | 136, 211, 298, 375, 450, 471, 479, 519, 567, 629, 672, 690, 706, 741, 798 |
| lib/screens/onboarding_screen.dart | longText | 407 |
| lib/screens/onboarding_screen.dart | copy | 598 |
| lib/screens/patterns_screen.dart | spacing | 111, 129, 135, 160, 164, 201, 213, 229, 257, 261, 282, 291, 319, 331, 344, 362, 383, 414, 446, 468, 479, 482, 523, 570, 589 |
| lib/screens/patterns_screen.dart | typography | 114, 115, 222, 223, 277, 278, 285, 286, 294, 295, 324, 325, 347, 348, 395, 396, 404, 405, 421, 422, 431, 432, 473, 474, 542, 543, 573, 574, 582, 583 |
| lib/screens/patterns_screen.dart | radius | 138, 170, 199, 264, 337, 375, 449, 485, 521, 528, 591 |
| lib/screens/patterns_screen.dart | touch | 101, 176, 187, 240, 519 |
| lib/screens/patterns_screen.dart | longText | 571 |
| lib/screens/photo_search_screen.dart | spacing | 194, 953 |
| lib/screens/photo_search_screen.dart | typography | 197, 198 |
| lib/screens/photo_search_screen.dart | radius | 694, 1187 |
| lib/screens/photo_search_screen.dart | touch | 184, 569, 786, 989, 1124 |
| lib/screens/photo_search_screen.dart | longText | 533, 995, 1138 |
| lib/screens/pre_purchase_result_screen.dart | spacing | 140 |
| lib/screens/pre_purchase_result_screen.dart | typography | 147, 148 |
| lib/screens/pre_purchase_result_screen.dart | touch | 130 |
| lib/screens/pre_purchase_result_screen.dart | longText | 291 |
| lib/screens/pre_purchase_result_screen.dart | copy | 189 |
| lib/screens/pre_purchase_screen.dart | spacing | 158 |
| lib/screens/pre_purchase_screen.dart | typography | 163, 164 |
| lib/screens/pre_purchase_screen.dart | touch | 148, 632 |
| lib/screens/pre_purchase_screen.dart | longText | 538 |
| lib/screens/pre_purchase_screen.dart | copy | 74, 353 |
| lib/screens/price_history_screen.dart | longText | 221 |
| lib/screens/profile_screen.dart | spacing | 63, 281, 304, 962, 1083, 1101, 1105, 1122, 1130, 1150, 1168, 1191 |
| lib/screens/profile_screen.dart | typography | 66, 67, 276, 277, 965, 971, 1094, 1113, 1154, 1155, 1195, 1196 |
| lib/screens/profile_screen.dart | color | 122, 981 |
| lib/screens/profile_screen.dart | touch | 53, 75, 1124 |
| lib/screens/profile_screen.dart | longText | 515, 789, 1340, 1352 |
| lib/screens/profile_screen.dart | copy | 371, 400, 1008, 1235 |
| lib/screens/purchase_detail_screen.dart | spacing | 117, 144, 151, 156, 161, 182, 231, 243, 257, 277, 297, 322, 355, 368, 377, 392, 416, 429, 432, 474, 488, 501, 521, 554, 579, 595 |
| lib/screens/purchase_detail_screen.dart | typography | 120, 121, 204, 205, 236, 237, 248, 249, 270, 271, 300, 301, 362, 363, 371, 372, 380, 381, 423, 424, 444, 445, 495, 496, 504, 505, 557, 593, 605, 606 |
| lib/screens/purchase_detail_screen.dart | radius | 185, 285, 325, 347, 408, 435, 477, 540, 582 |
| lib/screens/purchase_detail_screen.dart | color | 189, 329 |
| lib/screens/purchase_detail_screen.dart | touch | 107, 129 |
| lib/screens/purchase_detail_screen.dart | longText | 234 |
| lib/screens/purchase_detail_screen.dart | copy | 442 |
| lib/screens/record_purchase_screen.dart | spacing | 331 |
| lib/screens/record_purchase_screen.dart | typography | 338, 339 |
| lib/screens/record_purchase_screen.dart | touch | 321, 349 |
| lib/screens/sale_screens.dart | spacing | 81, 175, 311 |
| lib/screens/sale_screens.dart | typography | 84, 85, 180, 181, 316, 317 |
| lib/screens/sale_screens.dart | touch | 71, 165, 301 |
| lib/screens/sale_screens.dart | longText | 123, 400 |
| lib/screens/shopping_profile_screen.dart | spacing | 77 |
| lib/screens/shopping_profile_screen.dart | typography | 80, 81 |
| lib/screens/shopping_profile_screen.dart | touch | 67, 107, 145 |
| lib/screens/wishlist_screen.dart | spacing | 118, 452, 470, 478, 489, 505, 507, 526, 538, 543 |
| lib/screens/wishlist_screen.dart | typography | 123, 124, 499, 501, 517, 519, 529, 532 |
| lib/screens/wishlist_screen.dart | radius | 463, 466, 513 |
| lib/screens/wishlist_screen.dart | color | 462, 500, 518, 547 |
| lib/screens/wishlist_screen.dart | touch | 108, 133, 159, 181, 465, 539 |
| lib/widgets/amount_field.dart | touch | 91 |
| lib/widgets/app_bottom_sheet.dart | longText | 53 |
| lib/widgets/app_button.dart | longText | 104 |
| lib/widgets/app_dropdown_field.dart | spacing | 54 |
| lib/widgets/app_dropdown_field.dart | touch | 73 |
| lib/widgets/app_header_actions.dart | spacing | 35, 92, 118, 127, 130, 223 |
| lib/widgets/app_header_actions.dart | typography | 99, 101, 125, 149, 230, 232 |
| lib/widgets/app_header_actions.dart | radius | 41 |
| lib/widgets/app_header_actions.dart | touch | 39, 75, 212 |
| lib/widgets/app_header_actions.dart | longText | 147 |
| lib/widgets/confirm_dialog.dart | longText | 33 |
| lib/widgets/demo_data_badge.dart | spacing | 19, 33 |
| lib/widgets/demo_data_badge.dart | radius | 22 |
| lib/widgets/insight_source_chip.dart | spacing | 21, 36 |
| lib/widgets/insight_source_chip.dart | typography | 39, 40 |
| lib/widgets/insight_source_chip.dart | radius | 26 |
| lib/widgets/month_picker_sheet.dart | spacing | 67, 89, 115, 119, 165 |
| lib/widgets/month_picker_sheet.dart | typography | 97, 98, 140, 141, 217, 218 |
| lib/widgets/month_picker_sheet.dart | radius | 86, 122, 200, 207 |
| lib/widgets/month_picker_sheet.dart | touch | 103, 127, 146, 193 |
| lib/widgets/motive_chip.dart | touch | 46 |
| lib/widgets/price_history_chart.dart | spacing | 894, 1290 |
| lib/widgets/price_history_chart.dart | typography | 1378 |
| lib/widgets/price_history_chart.dart | touch | 735, 1223 |
| lib/widgets/price_history_demo_section.dart | longText | 94 |
| lib/widgets/price_history_entry_card.dart | touch | 76 |
| lib/widgets/price_history_panel.dart | copy | 214 |
| lib/widgets/same_product_card.dart | touch | 151 |
| lib/widgets/same_product_card.dart | longText | 164 |
| lib/widgets/satisfaction_dialog.dart | touch | 80 |
| lib/widgets/satisfaction_dialog.dart | longText | 70 |
| lib/widgets/satisfaction_dialog.dart | copy | 40 |
| lib/widgets/section_card.dart | longText | 51 |
| lib/widgets/states/empty_view.dart | longText | 48 |
| lib/widgets/voucher_suggestion_card.dart | spacing | 110, 138, 140, 270, 302, 314, 326, 345, 358 |
| lib/widgets/voucher_suggestion_card.dart | typography | 283, 284, 335, 361, 362 |
| lib/widgets/voucher_suggestion_card.dart | radius | 113, 147, 276, 328, 348 |
| lib/widgets/voucher_suggestion_card.dart | touch | 163, 327 |
| lib/widgets/voucher_suggestion_card.dart | longText | 303 |
| lib/widgets/voucher_suggestion_card.dart | copy | 202, 334 |
| lib/widgets/wishlist_card.dart | touch | 36 |
| lib/widgets/wishlist_card.dart | longText | 52 |
| lib/widgets/wishlist_card.dart | copy | 160 |

### Ưu tiên và kết quả U3/U4

| Mức | Phạm vi | Xử lý |
|---|---|---|
| P1 | Overflow/không đọc được/không bấm được | Tiêu đề dùng Expanded; hàng thông tin dùng Wrap; giá so sánh chuyển dưới tên shop; footer/trạng thái ngắn có cuộn; navigation tăng chiều cao theo textScaler. |
| P2 · U3 | Login, onboarding, navigation, home, wishlist, thêm/chi tiết món, ghi khoản mua, ngân sách, cá nhân, giá tham khảo | Chuẩn hoá token, title/back, copy và target; cùng bộ 8 cấu hình và hai loại dữ liệu. |
| P2 · U4 | Các màn còn lại và widgets | Cùng token, copy, trạng thái rỗng/lỗi cuộn được; không đổi nghiệp vụ. |
| P3 | Hình học minh hoạ, offset mũi tên, font-weight override kế thừa, brand/AI/QR/CSV/PDF | Giữ theo mục đích, không coi là lỗi chỉ vì có số hoặc tên riêng. |

Luồng async: Home/history/patterns/budget dùng stateView hoặc state tương đương; wishlist/giá tham khảo/hồ sơ mua sắm dùng UiStateBuilder; chiêm nghiệm/AI có trạng thái riêng của ViewModel; form có busy/error khi submit; QR có errorBuilder. Không thêm request hay thay đổi trạng thái nghiệp vụ để phục vụ audit. Gallery kiểm tra cả UiLoading/UiEmpty/UiError trong panel hẹp.

## 3. Rà bằng mắt — U5

**Chưa chạy trên Redmi; chưa build/cài APK trong U1–U4.** Test widget không thay thế kiểm tra font thật, bàn phím thật, camera hay thao tác chạm.

- [ ] So lề và khoảng cách giữa các tab trên Redmi.
- [ ] Bật cỡ chữ hệ thống lớn nhất, thử nội dung tên dài/số tiền lớn ở light và dark.
- [ ] Mở bàn phím ở Thêm món và Ghi khoản mua; cuộn tới ô nhập/nút lưu.
- [ ] Kiểm tra tooltip, target chạm, popup/dropdown và sheet.
- [ ] Xoay ngang nếu máy/app cho phép; chụp lỗi vào mục này.
- [ ] Thử camera QR/nhận diện ảnh thật; audit chỉ dựng preview/service giả.

## Chạy lại

Chạy trong thư mục Flutter `prm393_lab03` có pubspec.yaml:

```powershell
flutter test test/ui
node tool/ui_audit.mjs
flutter analyze
flutter test
```

`node tool/ui_audit.mjs --report` chỉ tái sinh báo cáo khi còn đủ baseline.json/static-baseline.json/results.json tại build/ui-audit trên máy audit. Các JSON là artifact local; báo cáo Markdown lưu bằng chứng đã tổng hợp. Thiếu artifact thì script báo lỗi và giữ nguyên báo cáo, không ghi đè bằng kết quả 0/0.

Chỉ thu baseline trên mã **trước sửa**: `flutter test test/ui --dart-define=UI_AUDIT_RECORD_ONLY=true`. Chế độ này ghi lỗi vào build/ui-audit/baseline.json và không assert, không dùng làm bằng chứng bộ test xanh sau sửa. `flutter test test/ui` bình thường ghi results.json và assert toàn bộ lỗi. Không có skip để giấu lỗi.

### Cách kiểm tra U5 trên điện thoại

1. Kết nối Redmi bằng USB hoặc ADB Wi-Fi; kiểm tra `flutter devices`, chạy `flutter run -d <device_id>`.
2. Đổi cỡ chữ hệ thống lên lớn nhất, thử lần lượt light/dark ở Cá nhân.
3. Qua các tab Trang chủ/Lịch sử/Mô hình/Góc nhìn/Cá nhân; kiểm tra lề, cuộn và nút ở cuối màn.
4. Thử tên món/shop dài, số tiền lớn; mở chọn tháng, ngân sách, danh sách thông báo và xác nhận xoá.
5. Mở form thêm món/ghi khoản mua, bật bàn phím và cuộn tới nút lưu; thử xoay ngang nếu app cho phép.
6. Kiểm tra kết quả tìm ảnh/so sánh giá với dữ liệu thật, ghi lỗi và ảnh chụp vào mục 3. Không dùng kết quả widget test để kết luận camera/AI/network đã hoạt động.

## Tệp thay đổi trong U1–U4

- `lib/screens/add_item_screen.dart`
- `lib/screens/budget_screen.dart`
- `lib/screens/compare_items_screen.dart`
- `lib/screens/email_verification_screen.dart`
- `lib/screens/extension_qr_scan_screen.dart`
- `lib/screens/feedback_screen.dart`
- `lib/screens/history_screen.dart`
- `lib/screens/home_screen.dart`
- `lib/screens/info_text_screen.dart`
- `lib/screens/insights_screen.dart`
- `lib/screens/item_detail_screen.dart`
- `lib/screens/login_screen.dart`
- `lib/screens/main_navigation_screen.dart`
- `lib/screens/monthly_reflection_screen.dart`
- `lib/screens/onboarding_screen.dart`
- `lib/screens/patterns_screen.dart`
- `lib/screens/photo_search_screen.dart`
- `lib/screens/pre_purchase_result_screen.dart`
- `lib/screens/pre_purchase_screen.dart`
- `lib/screens/profile_screen.dart`
- `lib/screens/purchase_detail_screen.dart`
- `lib/screens/record_purchase_screen.dart`
- `lib/screens/reminder_permission_screen.dart`
- `lib/screens/shopping_profile_screen.dart`
- `lib/screens/wishlist_screen.dart`
- `lib/screens/sale_screens.dart`
- `lib/theme/app_text_styles.dart`
- `lib/widgets/app_dropdown_field.dart`
- `lib/widgets/app_header_actions.dart`
- `lib/widgets/buy_intent_section.dart`
- `lib/widgets/decision_card_panel.dart`
- `lib/widgets/demo_data_badge.dart`
- `lib/widgets/insight_source_chip.dart`
- `lib/widgets/month_picker_sheet.dart`
- `lib/widgets/price_history_chart.dart`
- `lib/widgets/price_history_panel.dart`
- `lib/widgets/satisfaction_dialog.dart`
- `lib/widgets/voucher_suggestion_card.dart`
- `lib/widgets/states/empty_view.dart`
- `lib/widgets/states/error_view.dart`
- `lib/widgets/states/loading_view.dart`
- `test/ui/screen_render_test.dart`
- `test/ui/ui_audit_harness.dart`
- `test/ui/ui_tokens_test.dart`
- `test/support/purchase_harness.dart`
- `test/purchase_flow_test.dart`
- `test/notification_and_list_test.dart`
- `test/profile_history_compare_test.dart`
- `test/profile_settings_test.dart`
- `tool/ui_audit.mjs`
- `docs/ui-audit.md`
- `docs/design-tokens.md`
- `docs/ai-log.md`

## Ngoài phạm vi, tôi không sửa

Không đổi logic nghiệp vụ, models/ViewModels/services, Firestore rules/dữ liệu thật, routing, dependencies, backend, giao diện admin hoặc cấu hình Facebook/Firebase. Không commit/push/build/cài APK. Các test cũ chỉ bổ sung fake/provider còn thiếu và đổi finder/assertion cho câu chữ UI mới; không bỏ assertion nghiệp vụ. U5 cần thao tác máy thật.

## Xác nhận cuối ngày 10/11/2026

- `dart format` trên các file Dart thực tế thay đổi: hoàn tất.
- `flutter test`: **1.328/1.328 đạt**, gồm 640 ca render và 3 test typography/foreground/target. Không còn 4 lỗi purchase_flow được ghi ở lần bàn giao Facebook trước: hai lỗi fake Auth/provider được bổ sung trong test, hai lỗi overflow được sửa ở UI.
- `flutter analyze`: không có error/warning; còn 2 info cũ `use_null_aware_elements` ở `lib/viewmodels/own_price_view.dart:71,75` (exit 1 vì info, không sửa ngoài phạm vi).
- `git diff --check` và `node --check tool/ui_audit.mjs`: đạt.
- Quét screens/widgets: 0 hex hoặc named Colors ngoài transparent; test/ui không có skip.
- Các số trên là kết quả lượt xác nhận này, không tự cập nhật chỉ bằng việc tái sinh bảng. U5 và APK trên Redmi chưa được kiểm tra/cập nhật.
