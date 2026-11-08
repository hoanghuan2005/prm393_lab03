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
| Hồ sơ và mức hài lòng | Đồ đang dùng, phong cách, thương hiệu do người dùng tự ghi (không lấy lịch sử Shopee); mức hài lòng 1–5 sao hỏi sau 7 ngày, có "Bỏ qua", dùng cho Góc nhìn và gói mua. | [`data-model.md`](data-model.md) – `ownedItems`, `purchases` |
| Decision Card và sale | Nhãn theo Rules Engine v1 (đặc tả 7.4), không có "Nên mua"; lịch sale lấy từ Remote Config `sale_calendar` (đã xác nhận / dự kiến); gói mua chỉ chạy khi người dùng bấm. | [`design-traceability.md`](design-traceability.md) – DEV-09 |
| Tài khoản liên kết | Một tài khoản (`uid`) có thể liên kết Google và GitHub; Khách liên kết để thành tài khoản thật. Không gộp dữ liệu hai tài khoản đã có. Thêm trong giai đoạn chốt tính năng. | Mục 2 – Liên kết nhiều cách đăng nhập vào một tài khoản |
| Biểu đồ giá tham khảo | Giá dùng chung, ẩn danh trong `priceHistory`; một đường giá thấp nhất + vùng tô, không trục giá; tổng hợp trên máy (gói Spark); ghép cùng món bằng mã do AI trích, AI không chắc thì không ghép. Nguyên tắc N1–N8. | Mục 2 – Biểu đồ giá tham khảo; [`data-model.md`](data-model.md) – `priceHistory` |
| Extension Chrome | Extension đăng nhập Google cùng tài khoản và đọc/ghi thẳng Firestore; liên kết bằng một phiên `pending` được **duyệt trên điện thoại** thay cho mã 6 số (X4); không có backend, chạy trên gói Spark. Nút "Mua" trên extension chỉ ghi `buyIntentAt`; khoản mua luôn ghi trong app. | Mục 2 – Extension Chrome |

## 2. Sai khác so với thiết kế Lab 2 (deviation)

### Màu chủ đạo
App giữ màu vàng `#FFDE02` (chữ trên vàng `#070E20`) thay cho indigo `#2E4A9E` trong Figma Lab 2. Lý do: quyết định của nhóm, giữ nhận diện thương hiệu đã dựng. Token màu và kiểm tra tương phản: [`design-tokens.md`](design-tokens.md).

### Cloud Storage (D7)
Nhóm không dùng Cloud Storage for Firebase vì từ 30/10/2024 dịch vụ này yêu cầu gói Blaze, còn project `prm393-34056` dùng gói Spark. Báo cáo PDF được tạo ngay trên máy (package `pdf`) và chia sẻ bằng package `printing` (`ReportShareService`). App vẫn dùng 8 dịch vụ Firebase: Authentication, Cloud Firestore, Remote Config, Crashlytics, Cloud Messaging, Analytics, Firebase AI Logic và App Check.

### AI
Dùng Firebase AI Logic (`firebase_ai`) với Gemini Developer API (bậc miễn phí, chạy được trên gói Spark), được bảo vệ bằng App Check. Tên model lấy từ Remote Config `ai_insight_model`. Số liệu do code tính (`MonthlySpendingStats`); AI chỉ viết câu nhận định. Câu AI có số lạ hoặc từ ngữ bị cấm sẽ được thay bằng câu mẫu (`AiInsightService`). Mọi lời gọi `firebase_ai` nằm trong `AiService` (`lib/services/ai_service.dart`).

Gợi ý khi thêm món (tính năng AI 3 và 4) dùng cùng nguyên tắc: code trả lời trước (bảng từ khoá cho nhóm ngân sách, so từ trong tên cho món trùng), chỉ hỏi AI khi code không chắc, và AI chỉ được **chọn** trong danh sách code đưa ra (schema enum) nên không thể bịa nhóm, bịa món hay viết câu phán xét. Gợi ý không bao giờ tự áp dụng; người dùng phải chạm. Ăn uống không tính là trùng (đồ dùng hết). Bật/tắt bằng Remote Config `enable_ai_suggestions` và cùng công tắc "Dùng AI" ở Góc nhìn.

Lý do cho nhãn Decision Card (tính năng AI 2): nhãn và mọi con số do `DecisionRules` tính; AI viết một câu từ dữ liệu tối thiểu (tên món, giá, nhóm, động cơ, số đã tính; không gửi link). Câu có số không nằm trong dữ liệu hoặc có từ cấm bị bỏ và thay bằng câu mẫu theo nhãn. Dùng chung cờ `enable_ai_suggestions` và công tắc "Dùng AI".

Giải thích gói mua (tính năng AI 5): khi người dùng mở "Lập kế hoạch cho đợt sale", app gọi AI một lần cho cả ba phương án; mỗi phương án được kiểm tra riêng (số lạ, từ cấm, ≤ 250 ký tự), phương án nào bị loại thì giữ câu mẫu "Gồm N món, tổng …, dùng khoảng X% phần khả dụng; còn lại …".

### Kiểm thử
Repo có bộ test tự động (`flutter test`, hiện 118 test) dùng Firestore giả lập (`fake_cloud_firestore`) và dịch vụ giả, không gọi Firebase thật. Chưa có CI; trước khi push, mỗi người chạy `dart format lib`, `flutter analyze`, `flutter test` và chạy thử theo checklist trong [`CONTRIBUTING.md`](../CONTRIBUTING.md). Kiểm thử đầu cuối trên Android theo [`test-plan.md`](test-plan.md).

### Đăng nhập và dữ liệu
- Đăng nhập bằng Google, GitHub hoặc chế độ Khách (Firebase Anonymous Auth). Google và GitHub liên kết được vào cùng một tài khoản (mục "Liên kết nhiều cách đăng nhập vào một tài khoản").
- Bỏ trường `revision` (extension so phiên bản bằng `updatedAt`). `productKey` và `priceType` được thêm lại cho extension Chrome. Cấu trúc dữ liệu hiện tại: [`data-model.md`](data-model.md).

### Extension Chrome
Handoff X4 đề xuất liên kết bằng mã 6 số và token do server cấp. Nhóm không có backend (Cloud Functions cần gói Blaze), nên:
- Extension đăng nhập Google bằng Firebase Auth (cùng `uid` với app) rồi đọc/ghi thẳng `users/{uid}/...`; `firestore.rules` vẫn chỉ cho chủ tài khoản.
- Bước "duyệt trên điện thoại" (25f) giữ nguyên ý: extension tạo `extensionSessions/{id}` trạng thái `pending`; app đang mở hiện hộp thoại "Cho phép … liên kết?"; Đồng ý → `approved`. Yêu cầu quá 5 phút bị bỏ qua. Huỷ liên kết ở Cá nhân → `revoked`, extension về chưa liên kết (EXT-8).
- Không còn mã 6 số và giới hạn 5 lần sai.
- "Mua · mở form trên điện thoại" chỉ ghi `buyIntentAt`; món hiện ở mục "Định mua từ máy tính" của Wishlist, khoản mua vẫn qua `buyFromWishlist` (xoá `buyIntentAt`). Extension không bao giờ đặt `purchased` (rules bắt buộc `purchaseId`).
- Giá "Sau voucher" chỉ để tham khảo: hiện trong Lịch sử giá nhưng không làm giá chính, không dùng để so sánh.

### Biểu đồ giá tham khảo
Người dùng xem giá một món theo thời gian (kiểu SteamDB) và giá cùng món ở shop khác. Dữ liệu do người dùng góp ẩn danh (`priceHistory`, G7) và dữ liệu mẫu cho demo. Chi tiết trường và rules: [`data-model.md`](data-model.md) – `priceHistory`.

| # | Nguyên tắc (theo code hiện tại) | Lý do |
|:-:|:---|:---|
| N1 | Một **đường giá thấp nhất** + **vùng tô** từ giá thấp nhất tới cao nhất mỗi ngày (giữa các shop của nhóm, hoặc giữa các báo cáo của một sản phẩm); không trục giá, không lưới. Mỗi ngày phẳng ở giữa cột, đổi giá bằng một đoạn cong ngắn (`smoothSteps`). Mỗi shop giữ giá thường gần nhất tối đa 7 ngày (nét đứt, nhạt hơn), quá 7 ngày thì đứt; giá sale/flash chỉ hiện đúng ngày. Một chấm xanh ở điểm thấp nhất kèm giá ("490k"), đường nét đứt "giá lúc bạn lưu", vạch dọc ngày sale. Trục thời gian tối đa 5 nhãn: ngày đầu, ngày cuối, ngày sale, ngày giá đổi nhiều nhất, cách nhau ≥ 1/6 kỳ. Luôn kèm danh sách mốc giá (Thấp nhất, Cao nhất, Lúc bạn lưu, Hiện tại thấp nhất). | Nhiều đường riêng từng shop rất rối (G5, G5b); so chỉ các shop báo giá trong ngày làm đường nhảy; giữ giá sale nhiều ngày tạo các khối thấp giả; bậc vuông khó nhìn. |
| N2 | **Đường** cộng đồng: một ngày cần ≥ 2 báo cáo giá niêm yết, bỏ báo cáo lệch > 30% so với trung vị ngày. **"Cùng món ở shop khác"**: 1 người ghi là đủ nhưng giá phải trong 7 ngày, luôn ghi số người và ngày. | Đường cần ổn định; danh sách theo shop thì mỗi shop thường chỉ có 1 người ghi. |
| N3 | Gom "cùng một món" bằng **mã món** (`productCode`) + **mã phân loại** (`variantCodes`) do AI trích từ tên (tính năng AI 9), không so chuỗi tên; AI không chắc thì không ghép; người dùng ẩn được dòng sai ("Không phải món này"). | Tên trên Shopee mỗi shop một kiểu; ghép nhầm (A3 với A3 Pro, 128GB với 256GB) tệ hơn không ghép. |
| N4 | Đánh giá (sao sản phẩm, số lượt, sao shop) lưu **theo từng báo cáo**. | Chi tiết ngày cần "đánh giá tại thời điểm ghi". |
| N5 | Biểu đồ nằm trong khu **"Lịch sử giá"** của Chi tiết món (G6b), cùng "Giá bạn ghi" và "Giá người khác ghi"; "Xem toàn màn hình" mở màn "Giá tham khảo". Câu chữ trung tính: không "Nên mua", không xếp hạng shop. | Giữ tinh thần app: dừng lại suy nghĩ, không thành app săn deal; một chỗ duy nhất về giá thay vì ba thẻ trùng nhau. |
| N6 | Dữ liệu mẫu luôn có nhãn **"Dữ liệu mẫu"**, không lẫn vào "Giá người khác ghi", không mở link Shopee, chỉ ghép với dữ liệu mẫu, có nút xoá sạch. | Trung thực khi demo. |
| N7 | Gói Spark: không Cloud Functions; app tự tổng hợp theo ngày; bộ mẫu ≤ ~5.000 lần ghi. | Hạn mức 20.000 lần ghi / 50.000 lần đọc mỗi ngày. |
| N8 | Giữ `afterVoucher` trong dữ liệu nhưng **không bao giờ** tính vào giá thấp nhất, trung vị hay so sánh giữa shop; chỉ hiện riêng với nhãn "Sau voucher (tham khảo)". | Voucher tuỳ từng người (người mới, theo dõi shop, cách thanh toán…), trộn vào làm giá thấp nhất ảo. |

**Giới hạn khi dữ liệu thưa.**
- Ngày chỉ có 1 người ghi thì không có điểm cộng đồng (N2); ngày trống giữ giá ≤ 7 ngày rồi đứt, không nối qua đầu kỳ.
- Khoảng đang xem có dưới 5 ngày có giá (`minChartDays`) thì không vẽ biểu đồ, chỉ hiện danh sách mốc giá; chỉ 1 lần ghi thì thêm "Ghi thêm giá để xem biến động".
- Ở Chi tiết món, khi cộng đồng chưa đủ 5 ngày có giá, biểu đồ vẽ từ chính giá người dùng đã ghi ("Giá bạn đã ghi", không cần ngưỡng 2 người) kèm dòng "Chưa đủ người ghi giá để vẽ đường cộng đồng (n lần ghi)"; món không có link Shopee thì có nút "Thêm link Shopee". Lớp cộng đồng được chọn theo khoảng đang xem, nên đổi sang 7N có thể quay về "Giá bạn đã ghi".
- Báo cáo người thật chỉ nhận giá trong 3 ngày qua; mỗi người một báo cáo cho mỗi phân loại mỗi ngày (id băm, không lưu uid). App đọc tối đa 90 ngày, ≤ 1.000 báo cáo mỗi sản phẩm.
- Ghép cùng món chỉ chạy khi sản phẩm đã có mã (AI chắc chắn) và phân loại của món đã có mã phân loại; món không phân loại chỉ ghép với sản phẩm cũng không phân loại.

**Dữ liệu mẫu và cách xoá** (chỉ admin, Cá nhân → Firebase Demo Area).
- "Tạo dữ liệu giá mẫu" (G2): xoá bộ cũ rồi ghi 8 nhóm × 3–4 shop và 3 sản phẩm ngoài nhóm (1 "bẫy" model Pro, 2 sản phẩm không mã), giá 90 ngày, tên sản phẩm và shop tự đặt; cùng ngày tạo lại ra cùng dữ liệu (seed cố định). Mọi document có `isDemo = true` hoặc `source = demo`.
- "Thêm món mẫu vào danh sách của tôi" (G2c): 4 món `isDemo` trong danh sách mong muốn của chính admin để thử đủ luồng; không tính vào thống kê, không gửi giá đi.
- "Xoá dữ liệu giá mẫu": gỡ món mẫu của admin, rồi xoá `priceHistory` có `isDemo == true` cùng báo cáo `source == demo` của chúng và `productGroups` có `isDemo == true`; dữ liệu thật không bị đụng (rules cũng chặn xoá dữ liệu thật). "Gỡ món mẫu khỏi danh sách" chỉ xoá món `isDemo` của chính người đó, kèm lịch sử giá và quyết định của món.

### Liên kết nhiều cách đăng nhập vào một tài khoản
Người dùng liên kết Google và GitHub vào cùng một tài khoản Firebase ở Cá nhân → "Tài khoản liên kết"; đăng nhập bằng cách nào cũng ra cùng `uid` và cùng dữ liệu.

**Vì sao thêm trong giai đoạn chốt tính năng.** Đăng nhập GitHub được thêm muộn (cùng nhánh share intent) và mỗi lần đăng nhập GitHub tạo một tài khoản riêng theo `uid`. Không có liên kết thì người dùng GitHub không dùng được extension, còn Khách mất dữ liệu khi đăng xuất hoặc đổi máy. Liên kết sửa cả hai mà không đổi cấu trúc dữ liệu, nên nhóm làm luôn thay vì bỏ đăng nhập GitHub.

**Lý do.**
- Mọi dữ liệu nằm dưới `users/{uid}/…`; giữ một `uid` là giữ được toàn bộ dữ liệu, không cần di chuyển gì.
- Extension Chrome chỉ đăng nhập bằng Google. Tài khoản tạo bằng GitHub phải liên kết Google thì extension mới vào đúng `uid` đó.
- Khách (Anonymous Auth) liên kết Google hoặc GitHub thì được nâng thành tài khoản thật, cùng `uid`; `users/{uid}.isAnonymous` được cập nhật thành `false`.

**Giới hạn.**
- Không gộp dữ liệu của hai tài khoản đã có sẵn. Liên kết một tài khoản Google/GitHub đã từng dùng riêng trong app thì Firebase báo `credential-already-in-use`; app chỉ báo lỗi, dữ liệu hiện tại không đổi.
- Không tự liên kết bằng credential đang chờ (credential kèm theo lỗi `account-exists-with-different-credential`), vì cách lấy và dùng credential này không ổn định giữa các phiên bản Firebase. Người dùng tự đăng nhập bằng cách cũ rồi liên kết ở Cá nhân.
- Khi trùng email (`account-exists-with-different-credential`), app dùng một câu trung tính `accountExistsOtherMethod` (`firebase_error_mapper.dart`) và không gợi ý nút nào: Firebase chặn việc tra cứu email đang thuộc cách đăng nhập nào (bảo vệ liệt kê email), app còn có email/mật khẩu, nên đoán "cách còn lại" có thể sai. Đã bỏ `AuthViewModel.suggestedProviderId` và giao diện đặt thông báo cạnh nút gợi ý.
- Luôn phải giữ ít nhất một cách đăng nhập (`last-provider`); nút "Huỷ liên kết" bị khoá khi chỉ còn một cách.
- Với chế độ "một tài khoản mỗi email" (mặc định), Google là nhà cung cấp tin cậy: đăng nhập Google vào email đã gắn GitHub có thể **không** báo lỗi mà Firebase tự chuyển tài khoản sang Google. Kết quả thật (ACC-09 trong [`test-plan.md`](test-plan.md)): _chưa chạy – điền sau khi chạy ACC-09 (có báo lỗi không, dữ liệu còn không, đăng nhập GitHub sau đó còn được không)._
- Không có trên Windows (không có plugin đăng nhập Google/GitHub): mục "Tài khoản liên kết" bị ẩn.
