# AI-Assisted Code Review Record (Biên bản đánh giá mã nguồn bằng AI)
**Dự án**: Why I Buy – The Psychology of Money
**Môn học**: PRM393 – Lab 3 mục 8 và Appendix C; Final mục 9 (review code mới)

Nguyên tắc: AI tìm lỗi, nhóm quyết định. Mỗi quyết định có lý do dẫn tới đề bài, quy tắc mục 5, một tác động đo được hoặc một ràng buộc thật.

---

## 1. Công cụ AI sử dụng (AI Tools Disclosure)

| Tên công cụ | Mục đích sử dụng | Mức độ can thiệp |
|:---|:---|:---|
| **Claude Code** (Anthropic) | Đợt review 2: lệnh `/code-review`. Ngoài ra hỗ trợ viết code, test, rules, tài liệu, và test UI trên máy thật qua ADB | Đề xuất và sửa trên máy; nhóm đọc diff, chạy test và tự commit |
| **Codex** (OpenAI) | Rà toàn repo theo đề Final (11/2026); từng điểm đã được kiểm tra lại, ghi ở `docs/plan-hoan-thien-final.md` | Chỉ đọc, không sửa code |
| **Antigravity AI Assistant** | Phân tích đặc tả Lab 2, thiết kế MVVM, code khung | Đồng lập trình |
| **CodeRabbit / Copilot Review** | Đợt review 1 (mục 3) | Rà trên máy trước khi commit |
| **Gemini** (Firebase AI Logic) | Tính năng AI trong app và web admin (xem `ai-feature.md`), không dùng để review | Chạy lúc dùng app |

---

## 2. Đợt 2: 11/11/2026 (Claude Code `/code-review`)

- **Kết quả gốc:** [`evidence/code-review/2026-11-11-claude-code-review.md`](../evidence/code-review/2026-11-11-claude-code-review.md). Công cụ trả 10 phát hiện, cộng 4 phát hiện bị cắt do giới hạn 10. Cả 14 phát hiện đều được ghi ở bảng dưới.
- **Phạm vi:** 10 file của các phần sắp sửa (gợi ý nhóm, màn giới thiệu, chiêm nghiệm, voucher, Lịch sale, web admin), ở commit `28fbf4d`.
- **Vì sao không review một pull request:** nhóm commit thẳng lên `main` và không có nhánh mở. Công cụ được chỉ định file cụ thể, nên mọi phát hiện vẫn trỏ tới file:dòng.
- **Commit sửa:** các bản sửa CR-06, CR-07, CR-08 nằm trong commit tổng ngày 11/11, thông điệp ghi đủ ba mã (tra bằng `git log --grep "CR-06"`). Đề Lab 3 mục 8 yêu cầu mỗi bản sửa một commit riêng, nên phần này **chưa đạt** yêu cầu đó.

| ID | Công cụ | File:line (ở `28fbf4d`) | Loại | Phát hiện (tóm tắt) | Quyết định | Lý do | Sửa |
|:--:|:--|:--|:--|:--|:--:|:--|:--|
| **CR-06** | Claude Code | `prm393_lab03/lib/models/item_suggestion.dart:32` | Bug | Từ khoá bị bỏ dấu nên khớp nhầm: "kiểm **tra**" thành Ăn uống (trà), "cây **lau** nhà" thành Ăn uống (lẩu), "**sơn** tường" thành Làm đẹp (son) | **Accepted** | Gợi ý nhóm sai là lỗi thấy được khi test trên máy (plan P-4). Từ khoá giữ nguyên dấu; tên món có dấu thì so có dấu, tên gõ không dấu thì so không dấu như cũ. Có test cho cả hai trường hợp | commit tổng 11/11 |
| **CR-07** | Claude Code | `prm393_lab03/lib/screens/onboarding_screen.dart:24` | Maintainability | `_pageCount = 1` khiến slide 2 và 3 không bao giờ hiện; khoảng 430 dòng code chết. Slide 3 chứa câu bị đặc tả cấm ("Tuần này bạn tiết kiệm được 35%…", số liệu bịa) | **Accepted** | Đặc tả cấm câu "tiết kiệm" và số liệu không có thật (plan P-5). Chỉ cần đổi một hằng số là câu đó lên bản nộp. Đã xoá `PageView`, hai slide và các hàm đi kèm; giao diện slide 1 giữ nguyên, test dark mode của màn này vẫn qua | commit tổng 11/11 |
| **CR-08** | Claude Code | `prm393_lab03/lib/screens/monthly_reflection_screen.dart:39` | Bug | Chọn "Bỏ thay đổi" rồi thoát nhưng mức hài lòng chưa lưu vẫn còn trong `ReflectionViewModel` (sống suốt app); mở lại thì vẫn thấy, và có thể lưu nhầm | **Accepted** | Lưu nhầm một giá trị người dùng đã chọn bỏ là sai dữ liệu. Thêm `ReflectionViewModel.discardChanges()`, gọi khi xác nhận bỏ; có test ở `test/reflection_viewmodel_test.dart` | commit tổng 11/11 |
| **CR-09** | Claude Code | `prm393_flutter_admin/lib/screens/admin_main_layout.dart:19` | Architecture | Bộ admin cũ (`AdminMainLayout`, `AdminService`, màn Push, Promotions, Crash, `MockAdminData`) không được nối vào app, khoảng 3.500 dòng trùng với stack MVVM mới. Có `FirebaseAuth.instance` trong widget, email admin viết cứng, dữ liệu giả | **Modified** | Đúng là vi phạm Lab 3 mục 5 (SDK trong widget) và "no mock data", nhưng nhóm **giữ lại các file làm bản dự phòng** (quyết định nhóm 11/11). Vì `admin_app.dart` chỉ dùng `AdminShell`, các file này không chạy trong bản deploy và không có dữ liệu giả nào hiện ra. Collection `crashes` mà màn Crash đọc không có rule nên Firestore luôn từ chối. Rules khoá ghi `vouchers` (S-1), nên nút "Quét Tự Động" có nối lại cũng không ghi được | — (giữ lại) |
| CR-10 | Claude Code | `prm393_flutter_admin/lib/services/admin_service.dart:313` | Bug | `sendBroadcast` luôn gửi kèm `targetUserId` cũ, nên tin "tất cả" có thể chỉ tới một người | **Accepted** | Chưa sửa: file được giữ cùng CR-09. Không chạy trong bản deploy vì không được nối vào app. Lỗi lọc đối tượng tương tự phía server ghi ở plan A-2 | — |
| CR-11 | Claude Code | `admin_service.dart:461` | Bug | `fetchFirebaseData` không kiểm tra lại chế độ Live sau `await`, nên dữ liệu thật đè lên chế độ Demo | **Accepted** | Chưa sửa: file được giữ cùng CR-09. Không chạy trong bản deploy vì không được nối vào app | — |
| CR-12 | Claude Code | `admin_service.dart:124` | Bug | Nút "Quét Tự Động" ghi thêm 3 voucher giả mỗi lần bấm; lỗi ghi bị nuốt | **Accepted** | Chưa sửa: file được giữ cùng CR-09. Không chạy trong bản deploy vì không được nối vào app; nguồn voucher giả này ghi ở plan mục 4, và rules đã khoá ghi `vouchers` | — |
| CR-13 | Claude Code | `admin_service.dart:105` | Bug | `update()` không `await` trong `try/catch` đồng bộ, nên lỗi không bao giờ bị bắt | **Accepted** | Chưa sửa: file được giữ cùng CR-09. Không chạy trong bản deploy vì không được nối vào app | — |
| CR-14 | Claude Code | `admin_service.dart:480` | Bug | Ở chế độ Live, dữ liệu giả vẫn hiện khi collection rỗng | **Accepted** | Chưa sửa: file được giữ cùng CR-09. Không chạy trong bản deploy vì không được nối vào app | — |
| CR-15 | Claude Code | `admin_service.dart:408` | Performance | Tải toàn bộ `purchases` và `wishlistItems` của mọi người dùng về trình duyệt | **Accepted** | Chưa sửa: file được giữ cùng CR-09. Không chạy trong bản deploy vì không được nối vào app. Dashboard đang chạy dùng aggregation `count()`/`sum()` (`dashboard_service.dart`) | — |
| CR-16 | Claude Code | `prm393_lab03/lib/models/item_suggestion.dart:10` | Performance | `normalizeTitle` tạo một `RegExp` mới cho mỗi ký tự | **Accepted** | Hàm chạy cho mọi món mỗi lần gõ ô tìm kiếm. Hai `RegExp` được đưa ra ngoài hàm | cùng commit với CR-06 |
| CR-17 | Claude Code | `prm393_lab03/lib/widgets/voucher_suggestion_card.dart:149` | Bug | Huy hiệu "Đủ điều kiện" luôn hiện kể cả khi chưa đủ; giá chưa biết bị coi là 0 | **Modified** | Không vá thẻ này: nó dùng mã voucher tự đặt (dữ liệu giả, trái đề). Plan D-3 (c) thay cả thẻ bằng voucher thật của từng món. Đóng khi D-3 xong | chờ D-3 |
| CR-18 | Claude Code | `voucher_suggestion_card.dart:48` | Bug | Không kiểm tra hạn dùng nên mã đã hết hạn vẫn được gợi ý; món không phải Lazada đều bị coi là Shopee | **Modified** | Như CR-17; bản thay thế phải kiểm tra hạn dùng (yêu cầu ghi trong plan V-1) | chờ D-3 |
| CR-19 | Claude Code | `prm393_lab03/lib/screens/monthly_reflection_screen.dart:345` | Maintainability | `_draftGoals` gần như không dùng vì không đổi tháng được khi màn đang mở | **Rejected** | Không có tác động đo được: khoảng 6 dòng, không lỗi, không tốn bộ nhớ đáng kể. Giữ để không phải sửa lại nếu sau này cho đổi tháng ngay trên màn (ràng buộc thời gian) | — |

**Tổng đợt 2:** 14 phát hiện, 5 loại (Bug, Architecture, Performance, Maintainability, và bảo mật trong CR-09 với email admin viết cứng). Đã sửa CR-06, CR-07, CR-08 (và CR-16 cùng file với CR-06).

---

## 3. Đợt 1 (Lab 3, trước 11/2026): bản ghi cũ, giữ nguyên nhưng có ghi chú

Ghi chú khi kiểm tra lại ngày 11/11/2026:
- Không lưu kết quả gốc của công cụ.
- Không commit nào ghi mã CR-0x (`git log --grep "CR-0"` không ra kết quả nào trước đợt 2). Các commit trong cột cuối do nhóm tự đối chiếu sau.
- CR-04 ghi `lib/viewmodels/wishlist_vm.dart`, nhưng file thật là `lib/viewmodels/wishlist_viewmodel.dart`.

Vì vậy đợt 1 không dùng làm bằng chứng cho yêu cầu "≥ 3 commit có mã"; đợt 2 thay thế.

| ID | Công cụ | Vị trí (File:Line) | Loại lỗi (Kind) | Tóm tắt phát hiện (Finding Summary) | Quyết định (Decision) | Lý do kỹ thuật (Reason) | Commit khắc phục |
|:---:|:---|:---|:---|:---|:---:|:---|:---:|
| **CR-01** | CodeRabbit | `lib/screens/add_item_screen.dart:45` | Architecture | Widget gọi trực tiếp `FirebaseFirestore.instance` để lưu dữ liệu | **Accepted** | Vi phạm nghiêm trọng quy tắc phân tầng MVVM mục 5. Cần chuyển việc lưu vào `WishlistService` và gọi qua `WishlistViewModel`. | Đã xử lý: màn gọi `WishlistViewModel.addItem` → `WishlistService.add` (`9185cc7`) |
| **CR-02** | Copilot | `lib/services/report_service.dart:32` | Maintainability | Một hàm vừa dựng layout PDF vừa gửi file đi | **Modified** | Tách trách nhiệm: `ReportService` chỉ dựng PDF; việc chia sẻ chuyển sang `ReportShareService` (package `printing`). Không còn tải lên đám mây (D7). | Đã xử lý (`72a94db`) |
| **CR-03** | CodeRabbit | `lib/models/wishlist_item.dart:18` | Security / Data | Trường `userId` được truyền thủ công từ client thay vì lấy từ token xác thực | **Accepted** | Nguy cơ client giả mạo uid. Bỏ `userId` khỏi model; dữ liệu nằm dưới `users/{uid}` và `firestore.rules` chỉ cho chủ tài khoản đọc/ghi; uid lấy từ `AuthViewModel` qua ProxyProvider. | Đã xử lý (`7e16045`, `9185cc7`) |
| **CR-04** | Copilot | `lib/viewmodels/wishlist_vm.dart:55` (file thật: `wishlist_viewmodel.dart`) | Performance | Tải lại toàn bộ danh sách mỗi khi một thuộc tính nhỏ của item thay đổi | **Accepted** | Gây lãng phí số lượt đọc Firestore (read quota) và gây giật lag UI. Đổi sang dùng `Firestore snapshots stream` có cập nhật cục bộ. | Đã xử lý: `WishlistService.watchItems` (snapshots stream) |
| **CR-05** | Copilot | `lib/widgets/motive_chip.dart:28` | Accessibility | Nút chọn động cơ có kích thước vùng bấm nhỏ hơn 48dp | **Accepted** | Vi phạm danh mục kiểm tra Accessibility Lab 2 (Mục 6: touch targets tối thiểu 48dp). `MotiveChip` bấm được luôn cao ≥ 48dp. | Đã xử lý (`6a33e12`) |
