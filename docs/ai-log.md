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
