# Why I Buy – The Psychology of Money (PRM393 - Lab 3)

Ứng dụng di động giúp người trẻ ghi lại vì sao mình mua, cân nhắc trước khi mua và nhìn lại thói quen chi tiêu, dựa trên cuốn *The Psychology of Money* của Morgan Housel. Dự án dùng kiến trúc **MVVM** (Provider), **8 dịch vụ Firebase** trên gói Spark, kịch bản E2E **Google ARTEMIS** và rà soát code có hỗ trợ AI.

---

## 1. Thông tin đồ án & Deliverables Map

* **Môn học**: PRM393 – Mobile Programming
* **Chủ đề**: Why I Buy – Smart Wishlist & Mindful Shopping Advisor
* **Figma Design**: [Why I Buy ver2 (Figma Link)](https://www.figma.com/design/VaPYFxfpx14tnQmOMSgdjP/Why-I-Buy-ver2?node-id=0-1)
* **Demo Video Link**: *(Sẽ cập nhật sau khi ghi hình demo)*

### Bản đồ tài liệu & Deliverables (Deliverables Map)
| Hạng mục | Đường dẫn tập tin / thư mục | Nội dung chính |
|:---|:---|:---|
| **Design Traceability** | [`docs/design-traceability.md`](docs/design-traceability.md) | Ánh xạ toàn bộ màn hình, flows, components từ Figma sang Flutter |
| **Architecture Spec** | [`docs/architecture.md`](docs/architecture.md) | Cây thư mục, sơ đồ phân tầng, ViewModel ↔ Service, luồng phiên đăng nhập |
| **Quyết định nhóm** | [`docs/decisions.md`](docs/decisions.md) | Quyết định D1–D14 và các sai khác so với Lab 2 (màu, Storage, AI, kiểm thử) |
| **Mô hình dữ liệu** | [`docs/data-model.md`](docs/data-model.md) | Collection `users/{uid}/...`, ràng buộc theo `firestore.rules`, index, quy tắc nghiệp vụ |
| **API dùng chung** | [`docs/base-api.md`](docs/base-api.md) | Service, ViewModel, widget và hàm core dùng chung |
| **Thêm tính năng** | [`docs/how-to-add-feature.md`](docs/how-to-add-feature.md) | Các bước thêm một màn mới, kèm ví dụ code |
| **Design Tokens** | [`docs/design-tokens.md`](docs/design-tokens.md) | Màu, chữ, khoảng cách, tương phản |
| **Analytics Plan** | [`docs/analytics-plan.md`](docs/analytics-plan.md) | 10 sự kiện Firebase Analytics (không PII), ViewModel gọi, quy ước Crashlytics |
| **Test Plan** | [`docs/test-plan.md`](docs/test-plan.md) | 10 kịch bản E2E bằng Google ARTEMIS (chạy tay; không có CI, chưa có unit/widget test) |
| **Code Review** | [`docs/code-review.md`](docs/code-review.md) | Biên bản đánh giá mã nguồn bằng AI và trạng thái xử lý |
| **Remote Config** | [`firebase/remote-config-defaults.json`](firebase/remote-config-defaults.json) | Giá trị cấu hình mặc định (cooling-off days, AI feature flag) |
| **E2E Tests** | [`e2e_test/`](e2e_test/) | Bộ kiểm thử tự động với Pytest & Google ARTEMIS |

---

## 2. Phiên bản công nghệ cố định (Pinned Versions)

* **Flutter**: 3.47.3 (channel stable, revision e8113bf456)
* **Dart**: 3.13.3
* **DevTools**: 2.60.0
* **Python**: 3.11+ / 3.12+ (cho bộ kiểm thử Google ARTEMIS)
* **Firebase Core**: 5.1.0 (theo `pubspec.lock`)
* **Google ARTEMIS**: Pin commit theo hướng dẫn Lab 3

### Dịch vụ Firebase đang dùng (project `prm393-34056`, gói Spark)

| # | Dịch vụ | Package | Dùng cho |
|:-:|:---|:---|:---|
| 1 | Authentication | `firebase_auth` | Đăng nhập Google |
| 2 | Cloud Firestore | `cloud_firestore` | Dữ liệu người dùng theo `users/{uid}/...` |
| 3 | Analytics | `firebase_analytics` | Sự kiện theo [`docs/analytics-plan.md`](docs/analytics-plan.md) (không PII) |
| 4 | Crashlytics | `firebase_crashlytics` | Ghi nhận lỗi/crash |
| 5 | Remote Config | `firebase_remote_config` | Số ngày chờ, cờ bật/tắt tính năng AI |
| 6 | Cloud Messaging | `firebase_messaging` | Thông báo nhắc |
| 7 | Firebase AI Logic | `firebase_ai` | Viết câu nhận xét ở màn Góc nhìn / Chiêm nghiệm tháng (code tính số, AI chỉ viết câu) |
| 8 | App Check | `firebase_app_check` | Bảo vệ lời gọi Firebase AI Logic — cài debug token theo mục 4.1.1 |

Nhóm **không** dùng Cloud Storage (cần gói Blaze – xem D7 trong [`docs/decisions.md`](docs/decisions.md)) và Realtime Database. Báo cáo PDF được tạo trên máy (`pdf`) và chia sẻ bằng package `printing`.

---

## 3. Công cụ AI sử dụng (Disclosed AI Tools)

Nhóm commit thẳng lên `main` (không dùng nhánh, không dùng Pull Request — xem [`CONTRIBUTING.md`](CONTRIBUTING.md)). Mỗi lần dùng AI được ghi lại trong [`docs/ai-log.md`](docs/ai-log.md) (prompt, kết quả, chấp nhận / sửa / từ chối).

1. **Antigravity AI Assistant**: Đồng lập trình, thiết kế kiến trúc, hỗ trợ viết tài liệu quy hoạch và scaffold code.
2. **Claude Code**: Dựng phần base (cấu hình lint, quy ước, dọn repo), refactor và rà soát code ngay trên máy trước khi commit.
3. **Google Gemini Multimodal API**: Mô hình trí tuệ nhân tạo hỗ trợ Google ARTEMIS phân tích màn hình Android và nhận định tâm lý chi tiêu.

---

## 4. Hướng dẫn cài đặt & Chạy ứng dụng

### 4.1. Chạy ứng dụng Flutter
```bash
# Di chuyển vào thư mục dự án
cd prm393_lab03

# Tải các gói phụ thuộc
flutter pub get

# Chạy trên máy ảo Android hoặc thiết bị thật
flutter run
```

### 4.1.1. Bật nhận xét AI (Góc nhìn, Chiêm nghiệm tháng) — làm 1 lần mỗi máy
Firebase AI Logic yêu cầu App Check. Nhóm dùng chung một debug token (hỏi trưởng nhóm, **không đưa lên git**):

1. Tạo file `assets/local/app_check.json`:
   ```json
   { "APP_CHECK_DEBUG_TOKEN": "<token nhóm>" }
   ```
2. Chạy bình thường (`flutter run`, F5, `flutter build apk`). App tự đọc token khi khởi động; log in `AppCheck debug token: found`.

Không có file thì app vẫn chạy, Góc nhìn hiện câu mẫu thay cho lời nhận xét AI. Không phát hành công khai bản build có chứa token.

### 4.2. Chạy bộ kiểm thử E2E ARTEMIS
```bash
cd prm393_lab03/e2e_test
pytest -v
```
