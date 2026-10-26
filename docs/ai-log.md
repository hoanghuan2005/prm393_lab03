# Nhật ký sử dụng AI

Mẫu ghi và quy ước: xem mục 5 trong [`CONTRIBUTING.md`](../CONTRIBUTING.md). Mục mới thêm vào cuối file.

---

### 2026-10-26 – Codex – Hoàn thiện điều hướng Wishlist và ghi khoản mua
- **Công cụ:** Codex.
- **Prompt:** Hoàn thiện mục 1, 2, 3 của danh sách công việc; đồng bộ web và Android.
- **Kết quả:** Sửa lối vào Wishlist, hoàn thiện form tạo/sửa khoản mua và nhóm ngân sách, nối xác nhận mua từ Wishlist với một batch Firestore; thêm kiểm thử lỗi, thử lại, chống ghi trùng và giao diện nhiều kích thước.
- **Quyết định:** Triển khai theo yêu cầu, chờ người dùng kiểm tra; chưa commit hoặc push.
- **Kiểm tra:** `flutter analyze` sạch; 52/52 test toàn dự án và 33/33 test trên Chrome qua; build APK Android và web thành công.
- **Môi trường:** Test dùng Firestore trong bộ nhớ. Chrome nhận CanvasKit từ SDK cục bộ qua công cụ kiểm thử để tránh lỗi đường dẫn tài nguyên của Flutter trên Windows; không sửa SDK. Chưa thử trên điện thoại thật vì chưa có thiết bị kết nối.

### 2026-10-26 – Claude Code – Kiểm tra mục 1–3, làm mục 4–6 (Chờ/Bỏ qua, phản hồi lưu/xoá, ngân sách theo nhóm)
- **Công cụ:** Claude Code.
- **Prompt:** Kiểm tra lại mục 1, 2, 3 đã làm; làm mục 4 (Chờ, Bỏ qua, Hoàn tác, Cân nhắc lại), 5 (phản hồi lưu/sửa/xoá, xoá khoản mua liên kết) và 6 (hạn mức từng nhóm, công thức khả dụng).
- **Kết quả:** Mục 1–3 đạt (52/52 test có sẵn qua). Mục 4: `ReviewDateSheet` chọn ngày xem lại, `WishlistViewModel.wait/skip/reconsider` thay `updateDecision`, Hoàn tác 5 giây, nhãn "Xem lại dd/MM"/"Đến hẹn xem lại" trên thẻ. Mục 5: `PurchaseService.delete` đưa món liên kết về Đang cân nhắc trong một batch; xoá/thêm món/quyết định chỉ báo thành công khi ghi xong, lỗi có "Thử lại". Mục 6: sheet nhập hạn mức từng nhóm (tổng = tổng các nhóm), `BudgetService.setGroupLimits`, `AvailableBudget` theo đặc tả 7.1 (90 ngày, bỏ khoản mua từ wishlist) và hộp "Vì sao con số này?" với số thực; bỏ `setOverallLimit`. Thêm `test/available_budget_test.dart`, `test/decision_and_budget_test.dart`; thay test `updateDecision` cũ.
- **Quyết định:** Chấp nhận, chờ kiểm tra trên máy thật.
- **Lý do / phần đã sửa tay:** Xoá decision `buy_{itemId}` khi xoá khoản mua là đánh đổi có chủ ý (decisions vốn chỉ thêm) để món mua lại được mà vẫn giữ khoá chống mua trùng; lịch sử vẫn có decision `undo`. `flutter analyze` sạch; 70/70 test qua. Chưa thử trên điện thoại thật.

### 2026-10-26 – Dao Tam Hoang – Mục 7–9 (thống kê đúng kỳ, quản lý món Wishlist, nhắc xem lại)
- **Công cụ:** Claude Code.
- **Prompt:** Làm mục 7 (thống kê cùng một kỳ, nút Tuần/Tháng, nhãn Trang chủ), 8 (sửa món, cập nhật giá, xoá có xác nhận, ngày ghi giá, món không có giá), 9 (thông báo cục bộ khi Chờ, xin quyền đúng lúc, mục "Cần xem lại").
- **Kết quả:** Mục 7: `PeriodStats` trong `purchase_viewmodel.dart` (tổng, số khoản, động cơ, khung giờ từ cùng một danh sách); màn Mô hình đổi dữ liệu thật theo Tuần/Tháng (trước đó phần động cơ cộng mọi khoản từ trước tới nay); Trang chủ đổi nhãn "TỔNG QUAN THÁNG", "Tuần này" chỉ hiện ở tháng hiện tại. Mục 8: `AddItemScreen(existing:)` để sửa (thêm nhóm ngân sách, không sửa giá ở đây), `PriceUpdateSheet`, xoá có `ConfirmDialog`, hiện "Giá ghi ngày…", báo giá cũ sau 7 ngày; `WishlistViewModel.updateDetails/updatePrice/deleteItem`. Mục 9: `ReviewReminderService` (flutter_local_notifications, hẹn không chính xác 09:00), đồng bộ thông báo theo danh sách món, xin quyền ngay sau khi Chờ, bộ lọc "Cần xem lại" + đếm ở Trang chủ, bấm thông báo mở danh sách đó; cấu hình desugaring và receiver trong Android. Thêm `test/stats_items_reminders_test.dart` (16 test).
- **Quyết định:** Sửa – plugin bản mới nhất (22.3.3) làm hỏng build Windows vì cần Visual Studio ATL; theo lựa chọn của nhóm, ghim `flutter_local_notifications: 18.0.1` (bản cuối chưa có plugin Windows) và `timezone: 0.10.1`.
- **Lý do / phần đã sửa tay:** Thông báo chỉ bật trên Android/iOS (web không hẹn giờ được). `flutter analyze` sạch; 86/86 test qua; build Windows (debug) và web thành công, app khởi động trên Windows. Chưa build/thử Android vì máy không có Android SDK – cần kiểm tra thông báo trên điện thoại thật.

### 2026-10-26 – Dao Tam Hoang – Mục 10–11 (trạng thái màn hình, AI/chiêm nghiệm/PDF) và kiểm tra lại 1–11
- **Công cụ:** Claude Code.
- **Prompt:** Làm mục 10 (phân biệt đang tải/trống/lỗi, mất mạng, đổi tài khoản) và 11 (AI lỗi vẫn có câu mẫu, chiêm nghiệm lưu đúng tháng, PDF tiếng Việt và danh sách dài); kiểm tra lại toàn bộ 1–11 và đồng bộ web/Windows/Android.
- **Kết quả:** `stateView` cho Trang chủ, Lịch sử, Mô hình, Góc nhìn, Ngân sách; bật bộ nhớ đệm Firestore, `awaitWrite` + `PendingWrites` + dải "Đang chờ mạng"; đọc an toàn khi mất mạng trong `PurchaseService`; xác nhận đăng xuất (cảnh báo tài khoản khách, thay đổi chưa đồng bộ); `PendingWrites.reset()` khi đổi tài khoản. PDF nhúng font Be Vietnam Pro (OFL), `MultiPage`, bảng có số trang. Kiểm tra lại 1–11 tìm và sửa: snack bar có nút không tự tắt (`persist: false`), xin quyền thông báo lúc mở app (chuyển sang nút "Bật thông báo"), tổng ngân sách so cả nhóm chưa đặt hạn mức (`limitedSpent`), thử lại ngân sách không xoá lỗi, ô tìm kiếm Wishlist trống mà vẫn lọc, `0 ₫` cho món bỏ qua chưa có giá, Back trên Android ở tab khác thoát app (`PopScope`), Wishlist trống thiếu nút "Thêm món đầu tiên", Trang chủ tháng trống thiếu lời nhắn, Ngân sách hiện "chưa đặt" khi chưa tải xong. Web: `GoogleSignIn` khởi tạo lười (lỗi assert khi mở), thêm `web/firebase-messaging-sw.js`. Thêm `test/state_offline_report_test.dart` và test `limitedSpent`.
- **Quyết định:** Chấp nhận.
- **Lý do / phần đã sửa tay:** `flutter analyze` sạch; 97/97 test qua; build web và Windows (debug) thành công. Không build được APK trên máy này vì thiếu Android SDK – cần kiểm tra trên Android thật: mất mạng rồi ghi khoản mua, nút Back, thông báo nhắc xem lại, PDF.
