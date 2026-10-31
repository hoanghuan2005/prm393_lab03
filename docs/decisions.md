# Quyết định của nhóm (D1–D14)

Các quyết định đã chốt cho Lab 3. Muốn đổi một quyết định thì cả nhóm thống nhất trước, cập nhật bảng này rồi mới sửa code.

## 1. Bảng quyết định

<!-- TODO(B14): dán bảng D1–D14 từ mục 0 của kế hoạch base vào đây (chưa nhận được nội dung). -->

| Mã | Quyết định | Ghi chú |
|:---|:---|:---|
| D1–D14 | *Chưa điền – chờ bảng từ mục 0 của kế hoạch base.* | |

## 2. Sai khác so với thiết kế Lab 2 (deviation)

### Màu chủ đạo
App giữ màu vàng `#FFDE02` (chữ trên vàng `#070E20`) thay cho indigo `#2E4A9E` trong Figma Lab 2. Lý do: quyết định của nhóm, giữ nhận diện thương hiệu đã dựng. Token màu và kiểm tra tương phản: [`design-tokens.md`](design-tokens.md).

### Cloud Storage (D7)
Nhóm không dùng Cloud Storage for Firebase vì từ 30/10/2024 dịch vụ này yêu cầu gói Blaze, còn project `prm393-34056` dùng gói Spark. Báo cáo PDF được tạo ngay trên máy (package `pdf`) và chia sẻ bằng package `printing` (`ReportShareService`). App vẫn dùng 8 dịch vụ Firebase: Authentication, Cloud Firestore, Remote Config, Crashlytics, Cloud Messaging, Analytics, Firebase AI Logic và App Check.

### AI
Dùng Firebase AI Logic (`firebase_ai`) với Gemini Developer API (bậc miễn phí, chạy được trên gói Spark), được bảo vệ bằng App Check. Tên model lấy từ Remote Config `ai_insight_model`. Số liệu do code tính (`MonthlySpendingStats`); AI chỉ viết câu nhận định. Câu AI có số lạ hoặc từ ngữ bị cấm sẽ được thay bằng câu mẫu (`AiInsightService`). Mọi lời gọi `firebase_ai` nằm trong `AiService` (`lib/services/ai_service.dart`).

Gợi ý khi thêm món (tính năng AI 3 và 4) dùng cùng nguyên tắc: code trả lời trước (bảng từ khoá cho nhóm ngân sách, so từ trong tên cho món trùng), chỉ hỏi AI khi code không chắc, và AI chỉ được **chọn** trong danh sách code đưa ra (schema enum) nên không thể bịa nhóm, bịa món hay viết câu phán xét. Gợi ý không bao giờ tự áp dụng; người dùng phải chạm. Ăn uống không tính là trùng (đồ dùng hết). Bật/tắt bằng Remote Config `enable_ai_suggestions` và cùng công tắc "Dùng AI" ở Góc nhìn.

### Kiểm thử
Lab 3 chưa có unit test / widget test viết mới và không có CI. Trước khi push, mỗi người tự chạy `dart format lib`, `flutter analyze` và chạy thử trên máy theo checklist trong [`CONTRIBUTING.md`](../CONTRIBUTING.md). Thư mục `test/` chỉ còn các test có sẵn từ trước, không mở rộng thêm.

### Đăng nhập và dữ liệu
- Đăng nhập bằng Google hoặc chế độ Khách (Firebase Anonymous Auth).
- Bỏ các trường thuộc giai đoạn sau: `productKey`, `priceType`, `revision`. Cấu trúc dữ liệu hiện tại: [`data-model.md`](data-model.md).
