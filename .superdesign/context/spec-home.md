# home
files: lib/screens/home_screen.dart, lib/screens/main_navigation_screen.dart (bottom nav shell), lib/widgets/app_header_actions.dart, lib/widgets/why_i_buy_logo.dart, lib/widgets/month_picker_sheet.dart, lib/viewmodels/purchase_viewmodel.dart, lib/viewmodels/wishlist_viewmodel.dart, lib/viewmodels/budget_viewmodel.dart, lib/models/buying_motive.dart, lib/models/purchase_item.dart, lib/theme/motive_colors.dart, lib/core/formatters/money_format.dart, lib/core/formatters/date_format.dart, lib/services/demo_data_service.dart
purpose: Xem nhanh tháng này đã chi bao nhiêu, vì động cơ nào, còn trong ngân sách không, rồi ghi khoản mua mới.
firebase: Cloud Firestore realtime snapshots: purchases (orderBy occurredAt desc), wishlistItems, budgets/{monthKey}, budget groups, Firebase Cloud Messaging: chuông thông báo liệt kê các tin FCM đã nhận (NotificationService + lịch sử lưu trong SharedPreferences), Firebase Auth (uid chọn dữ liệu của người dùng)

## layout
- Nằm trong shell MainNavigationScreen (IndexedStack). Scaffold nền #F8FAFC.
- **AppBar** cao 56, nền #FFFFFF, elevation 0, không có viền dưới:
  - leading (leadingWidth 42): IconButton Icons.chevron_left_rounded 30px #0F172A, tooltip 'Trang chủ'
  - title (titleSpacing 0): **WhyIBuyLogo(26)** [shared] + gap 4 + 'Trang chủ' 18px w800 #0F172A
  - actions = **AppHeaderActions** [shared, dùng chung cho các tab]. Icon màu #0F172A:
    - Chuông: Icons.notifications_none_rounded 24 khi 0 thông báo; Icons.notifications_rounded 24 kèm badge khi có. Tooltip 'Thông báo'.
    - Bookmark: Icons.bookmark_outline_rounded 24, tooltip 'Danh sách mong muốn'. Badge đếm = consideringCount.
    - Badge: hình tròn đỏ #EF4444, padding 4, chữ trắng 10px bold, đặt top 7 / right 7.
    - Avatar: tròn 34px #FFDE02 chứa Icons.person 20 #0F172A, padding phải 12 / trái 2.
- **Body**: SingleChildScrollView, padding trái 16 / trên 16 / phải 16 / dưới 80, cột căn trái:
  1. 'Chào bạn,' 16px w600 #0F172A
  2. khoảng 12
  3. **Thẻ TỔNG QUAN THÁNG**: nền trắng, radius 16, viền 1px #E2E8F0, bóng rgba(0,0,0,.02) blur 8 lệch y 2, padding 16. Nội dung từ trên xuống:
     - Hàng đầu (Wrap spaceBetween): bên trái là Icons.calendar_today_outlined 14 #64748B + gap 6 + 'TỔNG QUAN THÁNG' 11px w700, letter-spacing 0.6, #64748B. Bên phải là pill chọn tháng: nền #F1F5F9, radius 999, padding 10x3, chữ 'Tháng 11/2026' 11.5px w600 #0F172A + gap 2 + Icons.arrow_drop_down_rounded 16 #64748B. Chạm pill mở MonthPickerSheet, tiêu đề 'Chọn kỳ tháng'.
     - khoảng 12
     - Số lớn formatVnd(monthTotal): 32px w800 #47667B, ls -0.5
     - khoảng 4
     - Dòng đếm 13px #64748B. Mẫu: '{monthCount} khoản trong tháng' + (chỉ khi đang xem tháng hiện tại) ' · Tuần này: {weekCount} khoản ({formatVnd(weekTotal)})'
     - khoảng 4
     - Text.rich: 'Nhiều nhất: ' 13px #64748B + '{label} ({count}/{total})' 13px w700 #0F172A
     - khoảng 14
     - Hàng nhãn (Wrap spaceBetween): 'Động cơ chính' 12px #64748B ··· '{percent}% do {label}' 12px w700 #0F172A
     - khoảng 8
     - **Thanh động cơ phân đoạn**: cao 7, radius 4. Mỗi đoạn tô màu foreground của động cơ, flex = tỷ lệ số khoản (round(ratio*1000)), xếp từ lớn đến nhỏ, khe 2px giữa các đoạn. Khi trống là một thanh #F1F5F9.
     - Divider 1px #E2E8F0, padding dọc 10
     - **Hàng ngân sách** (InkWell, chạm thì mở màn Ngân sách): Icons.account_balance_wallet_outlined 15 #47667B, gap 6, 'Ngân sách tháng: ' 12px #64748B + '{limitedSpent} / {totalLimit}' w700 #0F172A (hoặc 'chưa đặt'), tiếp theo là badge phần trăm, gap 4, Icons.chevron_right_rounded 16 #64748B.
       - Badge phần trăm: padding 6x1.5, radius 4, chữ 11px w800. Trong hạn mức: nền #ECFDF5, chữ #059669. Vượt hạn mức: nền #F1F5F9, chữ #47667B.
  4. khoảng 16
  5. **Thẻ Danh sách mong muốn** (InkWell radius 16, chạm thì mở Wishlist): nền trắng, radius 16, viền 1px #E2E8F0, padding 16 ngang / 14 dọc. Row gồm Icons.bookmark_border_rounded 22 #0F172A, gap 14, cột ['Danh sách mong muốn' 15px w700 #0F172A; khoảng 2; '{consideringCount} món đang cân nhắc' + (nếu có) ' · {reviewDueCount} cần xem lại' 12.5px #64748B], Icons.chevron_right_rounded 22 #64748B.
  6. khoảng 24
  7. **Mục Trước khi mua**:
     - 'Trước khi mua' 16px w700 #0F172A
     - khoảng 6
     - 'Dừng lại một chút. Vài câu hỏi nhanh giúp bạn hiểu điều gì đang thu hút mình.' 13px #64748B
     - khoảng 2
     - 'Hiểu trước khi thay đổi.' 13px #64748B
     - khoảng 10
     - Wrap 2 ActionChip (cao khoảng 32, StadiumBorder, nền #FFFCE6, không viền, chữ 14px w600 #0F172A, icon avatar 18 #0F172A, cách nhau 8):
       - Icons.lightbulb_outline 'Trước khi mua', mở màn Trước khi mua
       - Icons.photo_camera_outlined 'Chụp để tìm', mở màn Chụp để tìm
  8. khoảng 24
  9. **Mục Khoản mua gần đây**:
     - Hàng tiêu đề: 'Khoản mua gần đây' 16px w700 #0F172A (Expanded), gap 8, badge số lượng (nền #F1F5F9, radius 999, padding 8x2, 12px w700 #64748B), TextButton 'Xem tất cả' 13px w600 #47667B + Icons.chevron_right_rounded 18 #47667B (chuyển sang tab Lịch sử).
     - khoảng 12
     - Thẻ danh sách: nền trắng, radius 16, viền 1px #E2E8F0. Tối đa 3 hàng, giữa các hàng là Divider 1px #E2E8F0.
     - Mỗi hàng (padding 16 ngang / 14 dọc, Row):
       - Ô vuông 40x40 radius 10, nền background của động cơ, icon động cơ 20px màu foreground
       - gap 12
       - Cột: tên món 15px w700 #0F172A (1 dòng, cắt ...); khoảng 4; Row gồm tag động cơ (padding 6x2, radius 6, nền background, icon 11 + gap 3 + nhãn 11px w700 màu foreground), gap 8, thời gian formatRelativeDateTime 12px #64748B ở 70%
       - Số tiền bên phải formatVnd 15px w700 #47667B
     - Trạng thái trống: padding 16, chữ 13px #64748B 'Chưa có khoản mua nào trong tháng này. Bấm "Ghi khoản mua" để bắt đầu.'
- **FAB** (centerFloat, nổi trên body): padding ngang 16, nút ElevatedButton full width, cao 52, radius 999, nền #FFDE02, chữ #0F172A, elevation 4, bóng đen 15%. Gồm Icons.add_circle_outline_rounded 20 + gap 8 + 'Ghi khoản mua' 16px w700. Chạm thì mở màn Ghi khoản mua.
- **Thanh điều hướng dưới** [shared shell]: nền #FFFFFF, viền trên 1px #E2E8F0, cao 60 (+ safe area), 5 mục chia đều. Mỗi mục: icon 24, gap 3, nhãn 11px. Mục đang chọn #0F172A w700; mục khác #94A3B8 w500. Không có pill chỉ thị. Các mục:
  - 'Trang chủ' (Icons.home_rounded khi chọn / home_outlined)
  - 'Lịch sử' (Icons.format_list_bulleted_rounded)
  - 'Mô hình' (Icons.bar_chart_rounded)
  - 'Góc nhìn' (Icons.lightbulb_outline_rounded / lightbulb_rounded)
  - 'Cá nhân' (Icons.person_outline_rounded / person_rounded)

## sample_data
Nguồn: FirestoreDemoDataService.seed(), giả sử chạy ngày 06/11/2026 (Thứ Sáu), đang xem 'Tháng 11/2026'.

Khoản mua tháng này (tên, số tiền, động cơ, nhóm, thời điểm). Có 10 mẫu cộng 1 khoản sinh từ Wishlist:
- 'Cơm tấm', 40.000 ₫, Tiện lợi, food, 01/11 12:15
- 'Tai nghe Bluetooth', 389.000 ₫, Khuyến mãi, tech, 01/11 23:40
- 'Trà sữa nướng', 45.000 ₫, Cảm xúc, food, 02/11 22:30
- 'Sách Tâm lý học về tiền', 143.000 ₫, Mong muốn, study, 02/11 09:20
- 'Áo khoác gió', 200.000 ₫, Khuyến mãi, fashion, 03/11 19:45
- 'Kem chống nắng', 265.000 ₫, Quảng cáo, beauty, 03/11 21:10
- 'Vé xem phim cùng bạn', 120.000 ₫, Ảnh hưởng MXH, other, 04/11 18:05
- 'Cà phê sáng', 35.000 ₫, Nhu cầu, food, 04/11 07:50
- 'Ốp lưng điện thoại', 99.000 ₫, Khác, tech, 05/11 14:25
- 'Bút và sổ tay', 68.000 ₫, Nhu cầu, study, 06/11 10:40
- 'Bình giữ nhiệt 500ml', 185.000 ₫, Nhu cầu, other, 03/11 (mua từ Wishlist)

Giá trị hiển thị trên màn:
- Số lớn: '1.589.000 ₫'
- Dòng đếm: '11 khoản trong tháng · Tuần này: 9 khoản (1.160.000 ₫)'
- 'Nhiều nhất: Nhu cầu (3/11)'
- Bên phải hàng nhãn: '27% do Nhu cầu'
- Thanh động cơ: Nhu cầu #3B82F6 flex 273 | Khuyến mãi #F59E0B 182 | 6 đoạn flex 91: Khác #64748B, Ảnh hưởng MXH #0EA5E9, Quảng cáo #2563EB, Cảm xúc #A855F7, Mong muốn #EC4899, Tiện lợi #14B8A6
- Ngân sách: hạn mức tech 1.000.000 + fashion 600.000 + food 1.500.000. Hiển thị 'Ngân sách tháng: 808.000 ₫ / 3.100.000 ₫', badge xanh '26%'. (Đã chi: tech 488.000 + fashion 200.000 + food 120.000.)
- Thẻ Wishlist: '4 món đang cân nhắc' (Máy ảnh film mini, Áo khoác len oversize, Bộ son dưỡng 3 màu, Khoá học tiếng Anh online). Badge bookmark trên AppBar hiện '4'. reviewDueCount = 0. Mẫu khi có món cần xem lại: '4 món đang cân nhắc · 1 cần xem lại'.
- Khoản mua gần đây (badge '3'):
  1. 'Bút và sổ tay', tag Nhu cầu (inventory_2_outlined, #3B82F6/#DBEAFE), 'Hôm nay 10:40', '68.000 ₫'
  2. 'Ốp lưng điện thoại', tag Khác (more_horiz, #64748B/#F1F5F9), 'Hôm qua 14:25', '99.000 ₫'
  3. 'Vé xem phim cùng bạn', tag Ảnh hưởng MXH (trending_up, #0EA5E9/#E0F2FE), '04/11 18:05', '120.000 ₫'
- Chuông: 0 thông báo (Icons.notifications_none_rounded, không badge).

## demo_beats
- Thẻ TỔNG QUAN THÁNG hiện pill 'Tháng 11/2026 ▾', số lớn '1.589.000 ₫' (#47667B) và dòng '11 khoản trong tháng · Tuần này: 9 khoản (1.160.000 ₫)'
- Thanh động cơ 7px tô dần từ trái: Nhu cầu #3B82F6 rộng nhất, Khuyến mãi #F59E0B, 6 đoạn mảnh cách 2px; nhãn phải '27% do Nhu cầu'
- Hàng 'Ngân sách tháng: 808.000 ₫ / 3.100.000 ₫' hiện cùng badge xanh '26%'
- Cuộn xuống: hai chip vàng nhạt 'Trước khi mua' và 'Chụp để tìm', rồi 3 hàng 'Khoản mua gần đây' với tag động cơ màu
- Chạm nút nổi vàng 'Ghi khoản mua': mở màn Ghi khoản mua

## talking_points
- Một màn trả lời ba câu: tháng này chi bao nhiêu, vì động cơ gì, còn trong ngân sách không.
- Thanh màu chia theo 8 động cơ mua sắm biến tâm lý tiêu dùng thành hình ảnh trực quan.
- Dữ liệu stream realtime từ Firestore: vừa ghi khoản mua, tổng tháng và danh sách cập nhật ngay.
- Lối tắt 'Trước khi mua' và 'Chụp để tìm' giúp dừng lại trước quyết định bốc đồng.
- Nút 'Ghi khoản mua' luôn nổi ở đáy, ghi lại lý do chỉ trong vài giây.