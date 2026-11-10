# Đánh giá UX — X2 và sửa nhỏ X3

Ngày 11/11/2026; mốc trước sửa `b9f03bb`, phạm vi [12 luồng](user-flows.md). Người dùng đã chọn “X1–X3: đánh giá rồi sửa các lỗi nhỏ; soạn kế hoạch X4”. Vì vậy các sửa S mức 3–4 và S mức 2 trong L1/L2/L4/L5 được thực hiện trong X3; **không suy ra cho phép làm đề xuất L**. Không dùng số người gặp lỗi giả hoặc tự nhận đã thử với người dùng thật.

## Tiêu chí và cách đọc

- N1 trạng thái hệ thống; N2 ngôn ngữ quen thuộc; N3 kiểm soát/thoát/hoàn tác; N4 nhất quán; N5 phòng lỗi; N6 nhận diện thay vì ghi nhớ; N7 linh hoạt; N8 tối giản; N9 khắc phục lỗi; N10 giải thích/trợ giúp.
- P1 giúp dừng suy nghĩ, không thúc mua; P2 câu chữ trung tính; P3 riêng tư/đồng ý; A tiếp cận: nhãn, target, thông tin ngoài màu.
- Mức 4: chặn hoàn thành; 3: lỗi/mất thông tin đáng kể; 2: gây chậm/khó hiểu; 1: thẩm mỹ. S: sửa UI nhỏ, giữ model/service/rules; L: cần quyết định sản phẩm/thiết kế lại hoặc đổi service.
- Mức độ là đánh giá từ code, không phải số liệu nghiên cứu người dùng. Không kết luận task “đạt” chỉ vì không có issue trong bảng; quyền OS, mạng, provider, theme và đọc màn hình thật vẫn cần kiểm tra.

## Bảng vấn đề

Dòng dẫn theo bản sau sửa, tên hàm giữ đường đối chiếu; mô tả “trước” đối chiếu `git show b9f03bb:<path>`. “Đã sửa” cần được đối chiếu kết quả kiểm tra cuối file.

| Mã | Luồng | Vị trí | Trước sửa / vấn đề | Nguyên tắc | Mức | Loại | Cách xử lý / trạng thái |
|---|---|---|---|---|---:|:---:|---|
| UX-01 | L1 | `lib/screens/login_screen.dart:554` | Login/Signup mở bằng named route không tự rời form khi thành công; AuthGate ở dưới đổi màn vẫn bị che | N1,N3,N9 | 4 | S | **Đã sửa**: quay qua AuthGate, giữ nhánh email verification, huỷ/lỗi không điều hướng |
| UX-02 | L2 | `lib/screens/add_item_screen.dart:91` | Back huỷ form thêm/sửa mà không hỏi; mất tên/link/nhóm/ưu tiên/động cơ đang nhập | N3,N5 | 3 | S | **Đã sửa**: so snapshot với draft, hỏi Bỏ thay đổi; Huỷ giữ input, prefill chưa sửa không hỏi |
| UX-03 | L5 | `lib/screens/record_purchase_screen.dart:134` | Back khỏi bước 1 mất sửa đổi số tiền/tên/ghi chú/ngày/nhóm | N3,N5 | 3 | S | **Đã sửa**: xác nhận khi rời bước 1; bước 2 chỉ về bước 1, không hỏi thừa |
| UX-04 | L2 | `lib/screens/add_item_screen.dart:324` | Có thể rời màn thêm món khi đang lưu rồi không biết kết quả, dễ tạo thao tác lặp | N1,N5 | 3 | S | **Đã sửa**: chặn Back và nút quay lại trong lúc lưu; không đổi request/service |
| UX-05 | L4 | `lib/screens/item_detail_screen.dart:60` | Retry chỉ lặp lệnh ghi, bỏ mất phần tiếp theo của handler; Bỏ qua không hiện undo/quay về, Chờ thiếu thông báo/quyền | N1,N3,N9 | 3 | S | **Đã sửa**: callback retry toàn hành động; giữ ngày/giá đã chọn; không dùng State sau dispose |
| UX-06 | L4 | `lib/screens/item_detail_screen.dart:306` | Retry xoá xong không kết thúc route và báo thành công như lần đầu | N1,N9 | 3 | S | **Đã sửa**: tách phần xoá sau xác nhận, retry tiếp đúng phần đó, không bắt xác nhận lại |
| UX-07 | L4 | `lib/widgets/wishlist_card.dart:123`; `lib/screens/item_detail_screen.dart:727` | Đếm ngược “Còn…” dễ hiểu thành thời hạn phải quyết định; thực tế không khoá hành động | P1,P2,N2,N10 | 2 | S | **Đã sửa**: dùng mốc ngày/giờ cố định; nói rõ vẫn có thể chọn hành động bất cứ lúc nào; không sửa cooldown model |
| UX-08 | L2,L4 | `lib/screens/add_item_screen.dart:286`; `lib/screens/item_detail_screen.dart:751` | Snackbar còn Wishlist, tiêu đề viết hoa không nhất quán; ý nghĩa ba hành động chưa nói ngay tại chỗ | N2,N4,N6,N10 | 2 | S | **Đã sửa**: danh sách cân nhắc / Thẻ quyết định; giải thích Mua ghi thực chi, Chờ chọn ngày, Bỏ qua có undo |
| UX-09 | L5 | `lib/screens/history_screen.dart:280` | Rỗng chỉ hướng người dùng tìm dấu cộng hoặc chip ở nơi khác | N6,N7,N9 | 2 | S | **Đã sửa**: CTA ngay tại trạng thái rỗng; Ghi khoản mua hoặc Xoá bộ lọc tương ứng |
| UX-10 | L1 | `lib/screens/login_screen.dart:53` | Back từ quên mật khẩu/đăng ký đi tới onboarding; input bị bỏ không hỏi | N3,N4,N5 | 2 | S | **Đã sửa**: pop về nơi mở nếu có; chỉ route gốc mới mở giới thiệu; hỏi trước khi bỏ input, không lưu mật khẩu ra đĩa |
| UX-11 | L2 | `lib/app/app.dart:45` | Share mới loại sub-route hiện có; draft có thể mất dù Back đã được bảo vệ | N3,N5 | 3 | L | **Đã giảm rủi ro**: share mở route mới trên stack, Back trở về form cũ với draft; hàng đợi share/ưu tiên nhiều share liên tiếp vẫn cần quyết định và thử trên Android |
| UX-12 | L12 | `lib/services/auth_service.dart:145` | Luồng giữ UID khách chỉ có liên kết provider; tạo email mới không phải nâng tài khoản khách | N3,N5,N10,P3 | 3 | L | **Đề xuất**, chưa làm: hỗ trợ link email an toàn, xử lý credential đã tồn tại; cần service/auth changes |
| UX-13 | L1 | `lib/app/app.dart:230` | Không tự mở giới thiệu khi cài lần đầu như mô tả kế hoạch | N6,N10 | 2 | L | **Đề xuất**, chưa làm: quyết định có cần first-run onboarding/persist trạng thái hay giữ Login-first |
| UX-14 | L3 | `lib/screens/pre_purchase_screen.dart` | Back khỏi bước đầu làm mất các đáp án đã chọn | N3,N5 | 2 | S | **Đã sửa sau X3**: hỏi trước khi bỏ câu trả lời ở bước đầu; Back các bước sau vẫn giữ đáp án |
| UX-15 | L6 | `lib/widgets/budget_setting_sheet.dart` | Đóng/vuốt sheet mất hạn mức đang sửa | N3,N5 | 2 | S | **Đã sửa sau X3**: sheet hỏi trước khi bỏ hạn mức chưa lưu; huỷ giữ số đang nhập; chặn đóng lúc lưu |
| UX-16 | L7 | `lib/screens/sale_screens.dart` | “Còn N ngày” vẫn hiện ở lịch/danh sách sale, trái định hướng tránh đếm ngược sale của nhóm | P1,P2,N4 | 2 | S | **Đã sửa sau X3**: hiển thị ngày diễn ra hoặc “Hôm nay”; giữ lịch và giờ nhắc |
| UX-17 | L9 | `lib/screens/monthly_reflection_screen.dart` | Mục tiêu chưa lưu mất khi Back/đổi kỳ | N3,N5 | 2 | S | **Đã sửa sau X3**: hỏi trước khi rời màn có thay đổi; giữ bản nháp mục tiêu theo tháng khi kỳ được đổi trong phiên; không lưu nháp xuống đĩa |
| UX-18 | L10 | `lib/screens/feedback_screen.dart`; `lib/screens/shopping_profile_screen.dart` | Draft góp ý/tags/owned-item không có cảnh báo rời màn/sheet | N3,N5 | 2 | S | **Đã sửa sau X3**: góp ý, phong cách/thương hiệu và đồ đang dùng đều hỏi trước khi rời lúc có thay đổi; chặn rời lúc lưu |
| UX-19 | L2 | `lib/screens/add_item_screen.dart:556`; `lib/viewmodels/wishlist_viewmodel.dart:385` | Ô shop cho nhập khi sửa nhưng updateDetails không nhận/lưu shop, dễ hiểu sai là đã lưu | N1,N5 | 3 | S | **Đã sửa UI**: chỉ đọc khi sửa, giải thích chỉ nhập được lúc thêm; hỗ trợ sửa shop thực sự cần mở rộng service/ViewModel, chưa làm |
| UX-20 | L1 | `lib/app/app.dart` AuthGate | Route Login gốc có thể bị thay bằng LoadingView khi auth chuyển sang loading; input có thể bị khởi tạo lại sau lỗi, khác Login trên named route | N1,N3,N9 | 3 | L | **Đã sửa sau X3**: giữ LoginScreen trong stack qua loading/error và phủ trạng thái chờ; widget test xác nhận email vẫn còn sau lỗi; provider thật cần kiểm tra trên máy |

Không tự thêm undo cho xoá vĩnh viễn: xoá món và khoản mua **đã có xác nhận**; khôi phục cả lịch sử giá/decision/linked expense cần hợp đồng dữ liệu và service, thuộc đề xuất L nếu nhóm muốn. Chưa phát hiện hành động xoá vĩnh viễn không có xác nhận trong các handler được rà; không suy ra mọi trường hợp Android đều đã thử.

## Xác nhận ba ghi nhận trong prompt

1. **“Thẻ Quyết Định (Decision Card)”**: bản hiện tại đã không có phần tiếng Anh ở tiêu đề; “Decision Card” còn ở comment không phải UI. X3 chỉ đổi thành câu thường “Thẻ quyết định”, giải thích tại chỗ và bỏ Wishlist ở snackbar thêm món. Không báo lỗi cũ là vẫn y nguyên.
2. **Đếm ngược cân nhắc:** xác nhận có `remainingCooldownLabel` trong chi tiết và card. Đổi UI sang mốc ngày/giờ; không dùng “chỉ có thể quyết định từ…” vì thực tế Mua/Chờ/Bỏ qua luôn khả dụng ở trạng thái cân nhắc. Getter model cũ giữ nguyên, test model vẫn hợp lệ.
3. **Thêm link Shopee không bấm được:** **đã có nút** `_AddLinkHint` ở `PriceHistoryPanel`, callback từ chi tiết mở `wishlistEdit`. Chuỗi cũ còn ở SharedPriceSection fallback nhưng không phải tuyến không-link chính khi panel tích hợp. Không thêm nút trùng. Kiểm tra bằng `test/price_history_panel_test.dart` và trên máy khi có món nhập tay.

## Rà nguyên tắc theo luồng

Mỗi ô là bằng chứng/giới hạn đã đọc code, không phải điểm số. Các mã N được định nghĩa ở đầu file để bao phủ đủ 10 nguyên tắc, thêm bốn cột đặc thù. “Máy” là cần thử thật.

| Luồng | N1 | N2 | N3 | N4 | N5 | N6 | N7 | N8 | N9 | N10 | Dừng suy nghĩ / trung tính | Riêng tư | Tiếp cận |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| L1 | Busy/auth gate | Email/khách | Guard + Back | Các provider chung form | Validation | Nhãn field | Reset mật khẩu | Một bước đăng nhập | Named-route lỗi giữ form; root có UX-20 | Verification chỉ dẫn | Không ép chọn provider | Không lưu credentials mới | Tooltip mật khẩu; TalkBack: Máy |
| L2 | Spinner metadata/lưu | Sửa Wishlist | Guard; share mới còn UX-11 | Cùng form cho share/nhập | Tên/động cơ bắt buộc | Nhóm/động cơ có nhãn | Điền sẵn từ share | Giá/link tuỳ chọn | Form giữ khi lỗi, retry | Giải thích cân nhắc | Không tự mua sau lưu | Share cho app; QR có xác nhận | Input/touch đã UI audit; bàn phím: Máy |
| L3 | Đang phân tích | Nhận định tiếng Việt | Back từng bước; UX-14 | Các lựa chọn thống nhất | Không tiếp nếu thiếu | Đáp án hiện tại còn chọn | Bỏ nhánh sale không cần | 3–4 bước theo đáp án | Mẫu khi AI không có | Giải thích thông tin đã dùng | Có Nghĩ thêm, không buộc mua | AI/prefs cần thử cấu hình thật | Option có semantics; thứ tự đọc: Máy |
| L4 | Busy + thông báo sau write | Mốc ngày giờ | Undo bỏ qua, confirm xoá | Ba hành động có giải thích | Chặn gửi lặp | Chờ có ngày đang chọn | Cân nhắc lại | Nhận định + dữ liệu | Retry đầy đủ X3 | Giải thích mốc không khoá | Không đếm ngược cân nhắc | Góp giá là opt-in | Icon + chữ, không chỉ màu |
| L5 | Busy, saving/error | Khoản đã mua | Back/guard + confirm xoá | Cùng form sửa/mới | Amount/name/length | Prefill có thể chỉnh | Nhắc mở form, CTA rỗng | Hai bước | Giữ input khi lỗi | Help động cơ | Ghi nhận thực tế, không khuyên | Không tự gửi PDF | Label tiền/ngày; font lớn đã test |
| L6 | Tổng/đã chi/phần vượt | Mốc tham chiếu | Huỷ; UX-15 | Tháng chung viewmodel | Amount validation | Group names | Sheet theo nhóm | Không chặn mua | Error giữ values | Giải thích hạn mức | Vượt không dùng ngôn ngữ phán xét | Dữ liệu tài khoản | Viền/chữ ngoài màu; Máy |
| L7 | Trạng thái xác nhận/dự kiến | Lịch/nhắc | Có Back, tắt nhắc | UX-16 đếm ngày | Chỉ đợt xác nhận được nhắc | Lịch công khai | Mức tắt/lớn/mọi | Không tạo đơn mua | Quyền bị từ chối có thông báo | Giải thích 20:00 | Có câu sale không buộc mua, còn UX-16 | Hỏi quyền khi chọn nhắc | Chip có chữ; quyền OS: Máy |
| L8 | Loading/ít dữ liệu | Giá bạn/giá người khác | Ẩn ghép có undo | Cùng panel giá | Confirm dùng giá cộng đồng | Nguồn/ngày ghi | Khoảng thời gian/nhóm | Thiếu link có CTA | UiError retry | Thiếu dữ liệu nói rõ | Không hứa giá rẻ nhất thực tế | Công tắc góp giá ẩn danh có mô tả | Chart semantics; Máy |
| L9 | Loading/report state | Đã chi/chiêm nghiệm | UX-17; huỷ share: Máy | Kỳ tháng/tuần | Có validation mức độ | Giá trị đã lưu | PDF preview/export | Mục tiêu là tuỳ chọn | Retry PDF | Tạo ngay trên máy | Không khuyên mua ở kết quả audit | Người dùng chọn nơi gửi | Semantics chart; PDF đọc thật: Máy |
| L10 | Setting busy | Nhãn setting | Confirm xoá/logout, UX-18 | Help/link/terms có nhóm | Bảo vệ phương thức cuối | Trạng thái linked hiển thị | Theme/CSV/nhắc | Các nhóm setting | Message khi lỗi | Note khách/extension | Không bắt bật nhắc | Guest/offline/clear có cảnh báo | Switch có nhãn; focus: Máy |
| L11 | Picker/loading/error | Tên/giá ước lượng | Huỷ ảnh/retake/Back | Shared add form | Không tự lưu kết quả | Tên khác nhìn thấy | Thư viện/camera | Chỉ một ảnh | Retry hoặc ảnh khác | Cách chụp rõ | Kết quả vẫn cần chọn hành động | Ảnh bỏ khi rời màn; AI prefs | Semantics/target; camera: Máy |
| L12 | Busy/link state | Giữ dữ liệu qua liên kết | Huỷ giữ UID; logout cảnh báo | Chung linked accounts | Chặn unlink cuối | Provider đang gắn | Ba provider | Không bắt đăng xuất | Account-exists message | Note giữ UID, UX-12 email | Không ép nâng khách | UID/provider xử lý trong service có sẵn | Button có chữ; provider thật: Máy |

## Thuật ngữ

| Thuật ngữ dùng | Nghĩa/câu giải thích | Không dùng thay |
|---|---|---|
| Danh sách cân nhắc | Món đang muốn mua để xem lại trước quyết định | Wishlist trong câu hướng dẫn/snackbar |
| Mốc cân nhắc | Ngày giờ tham chiếu; không khoá Mua/Chờ/Bỏ qua | Hạn chót mua; “chỉ được mua từ” |
| Chờ | Chọn ngày xem lại, món vẫn đang cân nhắc | Hoãn thanh toán/tạo đơn |
| Mua / Ghi khoản mua | Mở form ghi **khoản đã mua**, chỉ lưu khi xác nhận form | Đặt hàng/thanh toán |
| Bỏ qua | Chuyển trạng thái, có Hoàn tác và Cân nhắc lại | Xoá vĩnh viễn |
| Giá tham khảo | Giá đã được ghi, có nguồn/ngày; không hứa giá hiện tại của sàn | Giá chắc chắn thấp nhất |
| Cùng món ở shop khác | Kết quả ghép sản phẩm/phân loại, có thể ẩn nếu ghép sai | Mọi sản phẩm cùng nhóm đều giống nhau |
| Xoá dữ liệu | Xoá phạm vi dữ liệu app như thông báo xác nhận; không tự đồng nhất xoá tài khoản Auth | Huỷ toàn bộ tài khoản Firebase |

Giải thích lần đầu: cân nhắc có mô tả ở form/chi tiết; Chờ có nội dung trong sheet trước khi chọn; giá có chú thích nguồn và số lần ghi; cùng món có cơ chế ẩn sai. Chưa có walkthrough/first-use overlay, không tự thêm bước mới. Cần hỏi người tham gia X4 giải thích lại bằng lời của họ thay vì cho rằng có text là hiểu.

## 10 mục ưu tiên và phần nhóm quyết định

10 mục ưu tiên: UX-01, UX-02, UX-03, UX-04, UX-05, UX-06, UX-19, UX-07, UX-08, UX-09. X3 còn xử lý UX-10. Tổng 11 mục: 7 mục mức 3–4 và 4 mục mức 2 thuộc L1/L2/L4/L5. UX-05/06 cùng gốc retry nhưng tách tác động hoàn tác/điều hướng xoá để kiểm tra riêng; UX-19 phát hiện khi đối chiếu form với API lưu, không tự thay hợp đồng dữ liệu.

- **Sau X3:** UX-14–18 và UX-20 đã sửa; UX-11 giữ lại route có draft nhưng hàng đợi nhiều share vẫn cần thiết kế. UX-12 link email khách cần thay đổi service/auth, UX-13 first-run onboarding cần quyết định sản phẩm và cách áp dụng cho người đã cài app. Undo xoá vĩnh viễn chỉ làm sau khi nhóm duyệt hợp đồng khôi phục dữ liệu.
- Các sửa thêm này chưa được xác nhận bằng người dùng thật; không gọi đây là “đã tối ưu UX toàn bộ”.
- **X4:** dùng [kịch bản thử nghiệm](usability-test.md), ghi vấn đề mới từ UX-21 trở đi, kèm P1–P5 và nguồn quan sát. Không có vấn đề nào trong bảng hiện tại được gắn nguồn “từ thử nghiệm”.

## Kiểm tra từng sửa nhỏ

| Mã | Cách kiểm tra | Bằng chứng tự động / giới hạn |
|---|---|---|
| UX-01 | Mở đăng nhập qua route riêng, thành công vẫn qua email verification nếu cần | `ux_flows_test.dart`: named login; auth/provider thật cần F0 và thiết bị |
| UX-02/03/10 | Nhập nội dung → Android Back → Huỷ giữ input; Back → Bỏ thay đổi mới rời | Widget tests cho các form; clean prefill không hỏi, không có write khi bỏ |
| UX-04 | Bắt đầu lưu → bấm Back/nút quay lại, không thoát hay lưu hai lần | Test với Future điều khiển, không mô phỏng bằng sleep/mạng thật |
| UX-05 | Bỏ qua lỗi lần đầu → Thử lại → quay về, có Hoàn tác → trạng thái cân nhắc | Fake lỗi rồi persistence in-memory thật; không bỏ assertion status |
| UX-06 | Xoá sau confirm lỗi lần đầu → Thử lại → route đóng và item bị xoá | Test riêng; không thêm undo giả cho hành động vĩnh viễn |
| UX-07 | Món có cooldown: ngày giờ cố định xuất hiện, không có “Còn … giờ/ngày”; Mua/Chờ vẫn bấm được | Test copy + render matrix; cảm giác áp lực cần X4 |
| UX-08 | Lưu món, đọc snackbar và phần giải thích ba hành động | Widget flow và render; bảng thuật ngữ ở trên |
| UX-09 | Lịch sử rỗng: CTA mở ghi khoản; rỗng do lọc: CTA xoá bộ lọc | Test tap thực tế và assertion filter state |
| UX-19 | Mở sửa món, ô tên shop chỉ đọc và có giải thích, không gợi ý đã có chức năng lưu thay đổi shop | Widget test kiểm tra readOnly và lời giải thích; không đổi API lưu |

## Kết quả kiểm tra ngày 11/11/2026

- Ba ca hồi quy đầu tiên tái hiện đỏ trước sửa: named login không rời form và mất input khi Back ở thêm món/ghi khoản mua. Sau sửa, bộ `test/ux_flows_test.dart` có **13/13 test đạt**, gồm guard, prefill sạch, trạng thái lưu, retry/undo/delete, CTA lịch sử, mốc ngày và ô shop chỉ đọc.
- `flutter test`: **1.348/1.348 đạt** trên môi trường Flutter test mặc định; gồm **640 ca render UI** ở hai kích thước, hai cỡ chữ, light/dark và dữ liệu đầy/rỗng. Không thêm skip, không bỏ assertion nghiệp vụ. Đây không phải kiểm tra provider, camera hay backend thật.
- `flutter analyze`: **0 error, 0 warning**; còn 2 info `use_null_aware_elements` cũ ở `lib/viewmodels/own_price_view.dart:71,75`. Lệnh có exit code 1 do info; không sửa file này để làm sạch số đếm ngoài phạm vi.
- `dart format` trên các file Dart thực tế thay đổi và `git diff --check`: hoàn tất/đạt. Đã đối chiếu 12 khối Mermaid, số dòng dẫn chứng tồn tại và danh sách tệp; không tuyên bố đã render sơ đồ bằng Figma hay thử màn hình thật.
- X1–X3 hoàn thành theo phạm vi: **20 ghi nhận, 11 S đã xử lý**, còn 4 đề xuất L và 5 nhóm S mức 2 ngoài ưu tiên đợt này. X4 mới có kế hoạch/bảng trống; chưa có kết quả usability, chưa thực hiện X5.

### Hoàn thiện thêm sau X3, trước lần push chung

- Đã xử lý thêm **UX-14–18 và UX-20**; riêng UX-11 đã giữ form cũ trên stack khi nhận share mới. Tính cả X3: 16 mục S đã sửa, UX-20 đã sửa, UX-11 giảm rủi ro; UX-12/13 và hàng đợi nhiều share còn đề xuất. Không thay đổi service, model, rules hay dependency.
- Ca mới kiểm tra Android Back giữ câu trả lời trước mua, Back ở sheet ngân sách giữ hạn mức khi huỷ, và email ở Login gốc còn sau chu kỳ loading/error. Ca sheet ngân sách kiểm tra cả PopScope và nút xác nhận. Những ca này không thay thế thử vuốt/barrier hoặc provider/share trên máy thật.
- X4 vẫn là kịch bản/bảng trống: không có người tham gia hay số liệu để điền; vì vậy chưa có mã vấn đề từ thử nghiệm cho X5. Nhóm cần chạy 3–5 phiên, ghi bằng chứng rồi duyệt mã UX mới trước khi sửa X5.
- Kiểm tra toàn bộ trước thu gọn vị trí PopScope: **1.351/1.351 test đạt**. Sau cùng, chạy lại **76/76 test** của UX, ngân sách, hồ sơ và dark widgets; thêm kiểm tra giữ nháp sheet đồ đang dùng khi Back rồi vẫn lưu được. Phân tích tĩnh các file vừa sửa không có vấn đề. `flutter analyze` toàn dự án chỉ còn 2 info cũ `own_price_view.dart:71,75`, không có error/warning mới. `git diff --check` đạt.

## Hai lệch sau merge phát hiện trong lượt full suite

Không gắn mã “từ thử nghiệm” vì đây là phát hiện từ kiểm tra tự động, không phải nghiên cứu người dùng:

- `photo_search_screen.dart` ở mốc đầu đã có màu hex/nhánh dark trực tiếp do phần giao diện ảnh mới. Dùng lại `statusOverlay`, `primaryContainer`, `primaryContainerBorder`, `onPrimaryContainer`, `textSecondary` hiện có; giữ ảnh lớn, gradient, keyword và logic AI. Các giá trị tương ứng giữ nguyên màu light/dark, không thêm token hay đổi model/service.
- `profile_settings_test.dart` vẫn chờ câu Crashlytics cũ, trong khi service từ merge trước nói thêm “Admin Web”. Chỉ cập nhật chuỗi expected chính xác theo code hiện tại; vẫn kiểm tra nguồn thông báo và không có UID. Không thay thông báo/runtime service để khớp một test cũ.

Đợt X1–X3 ban đầu chưa commit/push hoặc cài APK. Theo yêu cầu tiếp theo, các sửa thêm được kiểm tra và gom vào một commit/push chung; APK vẫn cần build/cài riêng.

## Tệp thay đổi

- `lib/screens/add_item_screen.dart`
- `lib/app/app.dart`
- `lib/screens/feedback_screen.dart`
- `lib/screens/history_screen.dart`
- `lib/screens/item_detail_screen.dart`
- `lib/screens/login_screen.dart`
- `lib/screens/monthly_reflection_screen.dart`
- `lib/screens/photo_search_screen.dart`
- `lib/screens/pre_purchase_screen.dart`
- `lib/screens/record_purchase_screen.dart`
- `lib/screens/sale_screens.dart`
- `lib/screens/shopping_profile_screen.dart`
- `lib/widgets/budget_setting_sheet.dart`
- `lib/widgets/wishlist_card.dart`
- `test/ux_flows_test.dart`
- `test/purchase_flow_test.dart`
- `test/decision_and_budget_test.dart`
- `test/profile_history_compare_test.dart`
- `test/profile_settings_test.dart`
- `docs/user-flows.md`
- `docs/ux-review.md`
- `docs/usability-test.md`
- `docs/ai-log.md`

## Kiểm tra trên máy

Chạy trong thư mục Flutter có `pubspec.yaml`:

```powershell
flutter devices
flutter run -d <device_id>
```

1. Từ Login mở Đăng ký/Quên mật khẩu; nhập thử, Back → Huỷ giữ thông tin, Bỏ thay đổi quay lại đúng nơi. Đăng nhập qua route riêng bằng tài khoản thử, kiểm tra nhánh xác minh email.
2. Thêm/sửa món; thay tên/nhóm/ưu tiên rồi thử Back bằng nút và Android. Kiểm tra prefill chưa sửa không hỏi, ô shop khi sửa có giải thích chỉ đọc.
3. Ghi khoản mua từ món đã lưu, đổi số tiền/ghi chú, Back bước 2 giữ dữ liệu, rời bước 1 hỏi trước; thử lỗi/mạng với tài khoản thử. Không bấm ghi khoản thật chỉ để minh hoạ.
4. Bỏ qua → Hoàn tác, Chờ chọn ngày, xoá một món thử có xác nhận; kiểm tra thông báo sau retry khi có thể tái hiện lỗi an toàn. Không dùng dữ liệu thật cho thử xoá.
5. Mở Lịch sử tháng trống và bộ lọc không khớp, thử CTA; xem mốc cân nhắc cố định, thử cả sáng/tối và chữ lớn.
6. Thử Back, vuốt và chạm ra ngoài sheet hạn mức/đồ đang dùng khi có nháp; Back ở Trước khi mua, góp ý, chiêm nghiệm, hồ sơ; đổi tháng khi mục tiêu chưa lưu. Thử chia sẻ vào app khi một form khác đang nhập để chắc chắn Back khôi phục form đó.
7. Thực hiện X4 theo kịch bản bằng người mới thật; ghi quan sát rồi duyệt mã trước X5. Kiểm tra share/QR/provider/PDF/camera/quyền OS cần thiết bị thật, không suy từ widget test.

## Ngoài phạm vi, tôi không sửa

Không đổi models, ViewModels, services, Firestore rules, dữ liệu thật, bảng AppRoutes, dependency, backend hoặc admin. Có sửa điều hướng bên trong UI như mô tả UX-01/10 và callback sau khi retry; không thay quy tắc quyết định, thời gian cooldown, ghi khoản mua hoặc cách gửi AI. Hai lệch sau merge chỉ sửa token UI và một chuỗi expected test.

Hàng đợi nhiều share, link email khách, first-run onboarding và khôi phục xoá vĩnh viễn vẫn là đề xuất cần quyết định hoặc thay đổi service. Đã giữ form khi AuthGate loading và giữ route cũ dưới share mới. Chưa thử người dùng/Redmi, chưa build/cài APK; X4 mới có kế hoạch, X5 chờ dữ liệu quan sát và nhóm duyệt.
