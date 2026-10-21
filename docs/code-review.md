# AI-Assisted Code Review Record (Biên bản đánh giá mã nguồn bằng AI)
**Dự án**: Why I Buy – The Psychology of Money  
**Môn học**: PRM393 – Mobile Programming (Lab 3)  
**Công cụ rà soát sử dụng**: GitHub Copilot / Antigravity AI Code Review / CodeRabbit  

---

## 1. Công cụ AI sử dụng (AI Tools Disclosure)

| Tên công cụ | Mục đích sử dụng | Mức độ can thiệp |
|:---|:---|:---|
| **Antigravity AI Assistant** | Hỗ trợ phân tích đặc tả Lab 2, thiết kế kiến trúc MVVM và khởi tạo code khung | Đồng lập trình (Pair Programming) |
| **CodeRabbit / Copilot Review** | Rà soát bảo mật, phát hiện vi phạm phân tầng MVVM và cải thiện hiệu năng | Rà soát tự động qua Pull Request |

---

## 2. Bảng ghi nhận các phát hiện đánh giá mã nguồn (Review Findings Record)

| ID | Công cụ | Vị trí (File:Line) | Loại lỗi (Kind) | Tóm tắt phát hiện (Finding Summary) | Quyết định (Decision) | Lý do kỹ thuật (Reason) | Commit khắc phục |
|:---:|:---|:---|:---|:---|:---:|:---|:---:|
| **CR-01** | CodeRabbit | `lib/screens/add_item_screen.dart:45` | Architecture | Widget gọi trực tiếp `FirebaseFirestore.instance` để lưu dữ liệu | **Accepted** | Vi phạm nghiêm trọng quy tắc phân tầng MVVM mục 5. Cần chuyển việc lưu vào `WishlistService` và gọi qua `WishlistViewModel`. | `Planned` |
| **CR-02** | Copilot | `lib/services/report_service.dart:32` | Maintainability | Hàm `generateAndUploadPdf` quá dài (130 dòng), ôm đồm cả tạo layout PDF và upload Storage | **Modified** | Tách thành 2 hàm độc lập: `buildPdfDocument()` (chỉ render) và `uploadPdfToStorage()` trong `StorageService` để dễ test. | `Planned` |
| **CR-03** | CodeRabbit | `lib/models/wishlist_item.dart:18` | Security / Data | Trường `userId` được truyền thủ công từ client thay vì lấy từ token xác thực | **Accepted** | Nguy cơ bảo mật cho phép client giả mạo uid của user khác. Phải bắt buộc lấy uid từ `FirebaseAuth.currentUser.uid`. | `Planned` |
| **CR-04** | Copilot | `lib/viewmodels/wishlist_vm.dart:55` | Performance | Tải lại toàn bộ danh sách mỗi khi một thuộc tính nhỏ của item thay đổi | **Accepted** | Gây lãng phí số lượt đọc Firestore (read quota) và gây giật lag UI. Đổi sang dùng `Firestore snapshots stream` có cập nhật cục bộ. | `Planned` |
| **CR-05** | Copilot | `lib/widgets/motive_chip.dart:28` | Accessibility | Nút chọn động cơ có kích thước vùng bấm nhỏ hơn 48dp | **Accepted** | Vi phạm danh mục kiểm tra Accessibility Lab 2 (Mục 6: touch targets tối thiểu 48dp). Cần bọc thêm padding/constrained box. | `Planned` |
