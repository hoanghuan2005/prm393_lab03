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

### 2026-10-26 – Dao Tam Hoang – Kiểm tra mục 1–3, làm mục 4–6 (Chờ/Bỏ qua, phản hồi lưu/xoá, ngân sách theo nhóm)
- **Công cụ:** Claude Code.
- **Prompt:** Kiểm tra lại mục 1, 2, 3 đã làm; làm mục 4 (Chờ, Bỏ qua, Hoàn tác, Cân nhắc lại), 5 (phản hồi lưu/sửa/xoá, xoá khoản mua liên kết) và 6 (hạn mức từng nhóm, công thức khả dụng).
- **Kết quả:** Mục 1–3 đạt (52/52 test có sẵn qua). Mục 4: `ReviewDateSheet` chọn ngày xem lại, `WishlistViewModel.wait/skip/reconsider` thay `updateDecision`, Hoàn tác 5 giây, nhãn "Xem lại dd/MM"/"Đến hẹn xem lại" trên thẻ. Mục 5: `PurchaseService.delete` đưa món liên kết về Đang cân nhắc trong một batch; xoá/thêm món/quyết định chỉ báo thành công khi ghi xong, lỗi có "Thử lại". Mục 6: sheet nhập hạn mức từng nhóm (tổng = tổng các nhóm), `BudgetService.setGroupLimits`, `AvailableBudget` theo đặc tả 7.1 (90 ngày, bỏ khoản mua từ wishlist) và hộp "Vì sao con số này?" với số thực; bỏ `setOverallLimit`. Thêm `test/available_budget_test.dart`, `test/decision_and_budget_test.dart`; thay test `updateDecision` cũ.
- **Quyết định:** Chấp nhận, chờ kiểm tra trên máy thật.
- **Lý do / phần đã sửa tay:** Xoá decision `buy_{itemId}` khi xoá khoản mua là đánh đổi có chủ ý (decisions vốn chỉ thêm) để món mua lại được mà vẫn giữ khoá chống mua trùng; lịch sử vẫn có decision `undo`. `flutter analyze` sạch; 70/70 test qua. Chưa thử trên điện thoại thật.
