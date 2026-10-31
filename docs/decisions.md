# Quyết định của nhóm

Các quyết định đã chốt cho Lab 3. Muốn đổi một quyết định thì cả nhóm thống nhất trước, cập nhật bảng này rồi mới sửa code.

## 1. Bảng quyết định

Bảng D1–D14 gốc trong kế hoạch base chưa được gửi vào repo. Bảng dưới ghi các quyết định **đã thực hiện trong code**; khi có bảng gốc, nhóm đối chiếu và đánh lại mã. Riêng D7 (Cloud Storage) đã có mã từ trước.

| Chủ đề | Quyết định | Xem thêm |
|:---|:---|:---|
| Kiến trúc | MVVM + Provider. Màn hình chỉ gọi ViewModel; mọi lời gọi Firebase nằm trong `lib/services/`. | [`architecture.md`](architecture.md) |
| Nền tảng | Android là sản phẩm chính; web và Windows chạy cùng code. Tính năng không có SDK trên một nền tảng thì dùng giá trị mặc định hoặc cách thay thế. | [`data-model.md`](data-model.md) – Khác biệt giữa các nền tảng |
| Gói Firebase | Gói Spark, không dùng Cloud Storage (D7). | Mục 2 bên dưới |
| Dữ liệu | Mọi dữ liệu nằm dưới `users/{uid}/…`; rules chỉ cho chủ sở hữu đọc/ghi. | [`firestore.rules`](../firestore.rules), [`data-model.md`](data-model.md) |
| Wishlist và chi tiêu | Món mong muốn không phải khoản chi; chỉ khoản mua tính vào "đã chi". Giá chưa biết lưu `null`, không bao giờ hiện 0 ₫. | [`data-model.md`](data-model.md) – quy tắc 1, 5 |
| Quyết định | Mua · Chờ · Bỏ qua ngang hàng; "Chờ" chỉ đặt ngày xem lại, không phải trạng thái riêng. | [`design-traceability.md`](design-traceability.md) – Flow 2 |
| Ngân sách | Hạn mức theo nhóm; tổng tháng bằng tổng các nhóm; phần khả dụng theo đặc tả 7.1. | [`data-model.md`](data-model.md) |
| Mất mạng | Bật bộ nhớ đệm Firestore; ghi quá 5 giây chưa xác nhận thì coi là đã lưu trên máy và hiện "Đang chờ mạng". | [`data-model.md`](data-model.md) – quy tắc 8 |
| Thông báo | Chỉ xin quyền khi người dùng bấm "Bật thông báo" hoặc sau khi chọn "Chờ". Chạm thông báo FCM mở màn theo custom data `type`. | [`test-plan.md`](test-plan.md) – TC-09 |
| AI | Code tính số; AI chỉ viết lời hoặc chọn trong danh sách; lỗi thì dùng câu mẫu. | Mục 2 – AI |
| Decision Card và sale | Nhãn theo Rules Engine v1 (đặc tả 7.4), không có "Nên mua"; lịch sale lấy từ Remote Config `sale_calendar` (đã xác nhận / dự kiến); gói mua chỉ chạy khi người dùng bấm. | [`design-traceability.md`](design-traceability.md) – DEV-09 |

## 2. Sai khác so với thiết kế Lab 2 (deviation)

### Màu chủ đạo
App giữ màu vàng `#FFDE02` (chữ trên vàng `#070E20`) thay cho indigo `#2E4A9E` trong Figma Lab 2. Lý do: quyết định của nhóm, giữ nhận diện thương hiệu đã dựng. Token màu và kiểm tra tương phản: [`design-tokens.md`](design-tokens.md).

### Cloud Storage (D7)
Nhóm không dùng Cloud Storage for Firebase vì từ 30/10/2024 dịch vụ này yêu cầu gói Blaze, còn project `prm393-34056` dùng gói Spark. Báo cáo PDF được tạo ngay trên máy (package `pdf`) và chia sẻ bằng package `printing` (`ReportShareService`). App vẫn dùng 8 dịch vụ Firebase: Authentication, Cloud Firestore, Remote Config, Crashlytics, Cloud Messaging, Analytics, Firebase AI Logic và App Check.

### AI
Dùng Firebase AI Logic (`firebase_ai`) với Gemini Developer API (bậc miễn phí, chạy được trên gói Spark), được bảo vệ bằng App Check. Tên model lấy từ Remote Config `ai_insight_model`. Số liệu do code tính (`MonthlySpendingStats`); AI chỉ viết câu nhận định. Câu AI có số lạ hoặc từ ngữ bị cấm sẽ được thay bằng câu mẫu (`AiInsightService`). Mọi lời gọi `firebase_ai` nằm trong `AiService` (`lib/services/ai_service.dart`).

Gợi ý khi thêm món (tính năng AI 3 và 4) dùng cùng nguyên tắc: code trả lời trước (bảng từ khoá cho nhóm ngân sách, so từ trong tên cho món trùng), chỉ hỏi AI khi code không chắc, và AI chỉ được **chọn** trong danh sách code đưa ra (schema enum) nên không thể bịa nhóm, bịa món hay viết câu phán xét. Gợi ý không bao giờ tự áp dụng; người dùng phải chạm. Ăn uống không tính là trùng (đồ dùng hết). Bật/tắt bằng Remote Config `enable_ai_suggestions` và cùng công tắc "Dùng AI" ở Góc nhìn.

Lý do cho nhãn Decision Card (tính năng AI 2): nhãn và mọi con số do `DecisionRules` tính; AI viết một câu từ dữ liệu tối thiểu (tên món, giá, nhóm, động cơ, số đã tính; không gửi link). Câu có số không nằm trong dữ liệu hoặc có từ cấm bị bỏ và thay bằng câu mẫu theo nhãn. Dùng chung cờ `enable_ai_suggestions` và công tắc "Dùng AI".

### Kiểm thử
Repo có bộ test tự động (`flutter test`, hiện 118 test) dùng Firestore giả lập (`fake_cloud_firestore`) và dịch vụ giả, không gọi Firebase thật. Chưa có CI; trước khi push, mỗi người chạy `dart format lib`, `flutter analyze`, `flutter test` và chạy thử theo checklist trong [`CONTRIBUTING.md`](../CONTRIBUTING.md). Kiểm thử đầu cuối trên Android theo [`test-plan.md`](test-plan.md).

### Đăng nhập và dữ liệu
- Đăng nhập bằng Google hoặc chế độ Khách (Firebase Anonymous Auth).
- Bỏ các trường thuộc giai đoạn sau: `productKey`, `priceType`, `revision`. Cấu trúc dữ liệu hiện tại: [`data-model.md`](data-model.md).
