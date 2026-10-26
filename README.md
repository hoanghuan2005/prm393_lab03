# Why I Buy – The Psychology of Money (PRM393 - Lab 3)

Ứng dụng di động hỗ trợ quản lý chi tiêu và kiểm soát mua sắm bốc đồng (*Impulse Buying*) dựa trên triết lý cuốn sách *The Psychology of Money* của Morgan Housel. Dự án áp dụng kiến trúc **MVVM**, tích hợp toàn diện **Firebase Cloud Services**, kiểm thử tự động **Google ARTEMIS (E2E)** và thực hiện **AI Code Review**.

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
| **Architecture Spec** | [`docs/architecture.md`](docs/architecture.md) | Phân tầng MVVM, sơ đồ tuần tự, ma trận ViewModels & Services |
| **Analytics Plan** | [`docs/analytics-plan.md`](docs/analytics-plan.md) | Kế hoạch 7+ sự kiện Firebase Analytics (No PII) |
| **Test Plan** | [`docs/test-plan.md`](docs/test-plan.md) | Kế hoạch 10+ E2E test cases bằng Google ARTEMIS |
| **Code Review** | [`docs/code-review.md`](docs/code-review.md) | Biên bản đánh giá mã nguồn bằng AI và cam kết sửa lỗi |
| **Storage Rules** | [`firebase/storage.rules`](firebase/storage.rules) | Luật phân quyền Cloud Storage theo từng người dùng |
| **Remote Config** | [`firebase/remote-config-defaults.json`](firebase/remote-config-defaults.json) | Giá trị cấu hình mặc định (cooling-off days, AI feature flag) |
| **E2E Tests** | [`e2e_test/`](e2e_test/) | Bộ kiểm thử tự động với Pytest & Google ARTEMIS |
| **Báo cáo & Slide** | [`report/`](report/), [`slides/`](slides/) | Báo cáo chi tiết và slide thuyết trình |

---

## 2. Phiên bản công nghệ cố định (Pinned Versions)

* **Flutter**: 3.24.x (Channel stable)
* **Dart**: 3.5.x
* **Python**: 3.11+ / 3.12+ (cho bộ kiểm thử Google ARTEMIS)
* **Firebase Core**: 3.6.0
* **Google ARTEMIS**: Pin commit theo hướng dẫn Lab 3

---

## 3. Công cụ AI sử dụng (Disclosed AI Tools)

1. **Antigravity AI Assistant**: Đồng lập trình, thiết kế kiến trúc, hỗ trợ viết tài liệu quy hoạch và scaffold code.
2. **CodeRabbit / GitHub Copilot**: Rà soát vi phạm kiến trúc, bảo mật và hiệu năng qua PR.
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
