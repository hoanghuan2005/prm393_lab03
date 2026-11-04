# Workspace Rules: Minimal Change Flutter

Dự án áp dụng quy trình **Minimal Change Flutter** cho toàn bộ các thao tác chỉnh sửa, bảo trì và phát triển.

Chi tiết quy trình và hướng dẫn: xem tại [.agents/skills/minimal-change-flutter/SKILL.md](file:///.agents/skills/minimal-change-flutter/SKILL.md).

## Nguyên tắc cốt lõi:
1. **Phân tích phạm vi hẹp:** Chỉ đọc và kiểm tra file trực tiếp liên quan đến yêu cầu hoặc widget cụ thể. Không đọc toàn bộ thư mục `lib/` hay rà soát toàn bộ dự án khi yêu cầu chỉ là chỉnh sửa nhỏ.
2. **Thay đổi tối thiểu:** Sửa đúng các dòng cần thiết. Giữ nguyên kiến trúc, tên biến, tên class, format và quy ước hiện tại. Tuyệt đối không tự ý refactor hàng loạt.
3. **Bảo vệ mã nguồn hiện có:** Không can thiệp hay xóa các sửa đổi của người dùng. Không chạy các lệnh Git nguy hiểm (`git reset --hard`, `git checkout --`, `git clean`).
4. **Kiểm tra vừa đủ:** Sau khi sửa, kiểm tra diff và chạy `dart analyze path/to/file.dart` nếu cần.
5. **Báo cáo ngắn gọn:** Chỉ nêu rõ thay đổi chính, danh sách file thực tế sửa, kết quả kiểm tra và xác nhận không thay đổi ngoài phạm vi.

