---
description: "Quy trình chỉnh sửa Flutter theo phạm vi hẹp: chỉ phân tích phần liên quan, thay đổi ít nhất có thể, tránh đọc hoặc refactor toàn bộ dự án khi yêu cầu chỉ là chỉnh sửa nhỏ."
name: minimal-change-flutter
---

# Minimal Change Flutter

## Mục tiêu

Hoàn thành đúng yêu cầu của người dùng với phạm vi phân tích và chỉnh sửa nhỏ nhất có thể. Ưu tiên bảo toàn kiến trúc, logic, giao diện và các thay đổi hiện có trong dự án.

Áp dụng skill này cho các yêu cầu sửa lỗi, chỉnh UI, đổi màu, sửa text, căn lề, kích thước, trạng thái widget hoặc thay đổi nhỏ trong dự án Flutter/Dart.

## Nguyên tắc bắt buộc

1. **Hiểu yêu cầu trước khi đọc code**
   - Xác định chính xác màn hình, widget, hành vi hoặc thành phần người dùng muốn thay đổi.
   - Xác định kết quả mong đợi và những gì nằm ngoài phạm vi.
   - Nếu thiếu thông tin quan trọng khiến không thể sửa chính xác, chỉ hỏi một câu làm rõ cần thiết.
2. **Phân tích theo phạm vi hẹp**
   - Bắt đầu từ file được người dùng chỉ định hoặc file trực tiếp chứa thành phần cần sửa.
   - Chỉ mở file phụ thuộc khi có bằng chứng cần thiết, ví dụ import, widget dùng chung, theme, model, service hoặc state liên quan.
   - Không tự động đọc toàn bộ thư mục `lib/`, liệt kê toàn bộ dự án hoặc phân tích tất cả màn hình.
   - Không tìm kiếm diện rộng nếu có thể định vị thành phần bằng tên file, tên class hoặc tên widget.
3. **Ưu tiên thay đổi tối thiểu**
   - Chỉ sửa những dòng cần thiết để đáp ứng yêu cầu.
   - Giữ nguyên tên class, tên biến, cấu trúc thư mục, kiến trúc và quy ước hiện tại nếu không cần thay đổi.
   - Không tự ý refactor, format hàng loạt, đổi package, nâng cấp dependency hoặc tái cấu trúc code.
   - Không thay đổi API, database, service, routing, state management hoặc logic nghiệp vụ nếu yêu cầu chỉ liên quan đến UI.
   - Không chỉnh sửa các màn hình khác chỉ để đồng bộ thẩm mỹ, trừ khi người dùng yêu cầu.
4. **Bảo vệ thay đổi có sẵn**
   - Trước khi sửa, kiểm tra trạng thái Git nếu có nguy cơ đụng đến phần người dùng đã chỉnh sửa.
   - Không chạy `git reset --hard`, `git checkout --`, `git clean`, hoặc lệnh có thể xóa/ghi đè thay đổi của người dùng.
   - Không tự ý commit, push, stash hoặc revert.
   - Không ghi đè file nếu chưa hiểu các thay đổi hiện có trong file đó.
5. **Kiểm tra vừa đủ**
   - Sau khi sửa, xem diff của đúng các file đã thay đổi.
   - Chạy kiểm tra hẹp phù hợp, ví dụ `dart analyze path/to/file.dart` nếu môi trường hỗ trợ.
   - Chỉ chạy test hoặc build rộng khi thay đổi có ảnh hưởng rộng, người dùng yêu cầu, hoặc kiểm tra hẹp không đủ để xác nhận.
   - Không chạy lặp lại cùng một lệnh nếu chưa có lý do mới.
   - Nếu không thể chạy kiểm tra, nói rõ điều đó; không khẳng định đã kiểm tra thành công.

## Quy trình thực hiện

### Bước 1: Phân loại yêu cầu

Chọn một nhóm phù hợp:

- **UI nhỏ:** màu sắc, text, icon, padding, margin, kích thước, alignment, border, radius.
- **UI có tương tác:** button, dialog, form, validation, loading, empty state.
- **Logic:** điều kiện, xử lý dữ liệu, state hoặc luồng nghiệp vụ.
- **API/dữ liệu:** request, response, model, repository hoặc service.
- **Thay đổi dùng chung:** theme, component dùng chung, routing hoặc cấu hình.

Không mở rộng nhóm công việc nếu yêu cầu không đòi hỏi.

### Bước 2: Xác định file cần đọc

Thứ tự ưu tiên:

1. File người dùng chỉ định.
2. File chứa widget hoặc màn hình được nhắc đến.
3. File được import trực tiếp và thực sự cần để hiểu phần cần sửa.
4. File cấu hình hoặc thành phần dùng chung chỉ khi thay đổi phụ thuộc vào chúng.

Nếu chưa biết file nào chứa thành phần cần sửa, tìm kiếm theo tên màn hình, text hiển thị hoặc tên widget trước. Chỉ mở kết quả phù hợp.

### Bước 3: Đề xuất phạm vi

Với yêu cầu nhỏ, không cần viết báo cáo phân tích dài. Tóm tắt ngắn trong đầu hoặc phản hồi ngắn:

- File dự kiến sửa.
- Thành phần sẽ thay đổi.
- Những phần sẽ giữ nguyên.

Chỉ cần hỏi người dùng xác nhận khi có rủi ro đáng kể hoặc yêu cầu chưa rõ.

### Bước 4: Thực hiện

- Sửa trực tiếp phần liên quan.
- Tận dụng component, style, theme và helper hiện có.
- Không tạo file mới nếu có thể sửa an toàn trong file hiện tại.
- Không thêm package mới cho một thay đổi UI đơn giản.
- Không thay đổi hành vi hiện tại ngoài yêu cầu.

### Bước 5: Rà soát

- Xem diff để chắc chắn chỉ có thay đổi cần thiết.
- Kiểm tra lỗi cú pháp hoặc phân tích tĩnh ở phạm vi phù hợp.
- Kiểm tra các import không còn sử dụng nếu có phát sinh.
- Nếu phát hiện thay đổi ngoài phạm vi, hoàn tác riêng phần do chính mình tạo ra; tuyệt đối không xóa thay đổi có sẵn của người dùng.

### Bước 6: Báo cáo kết quả

Chỉ nêu ngắn gọn:

1. **Thay đổi chính:** mô tả chính xác phần đã thay đổi.
2. **File thay đổi:** liệt kê các file thực sự được chỉnh sửa.
3. **Kiểm tra:** nêu lệnh đã chạy và kết quả; nếu chưa chạy, nói rõ.
4. **Ngoài phạm vi:** xác nhận không thay đổi các phần không liên quan, nếu đúng.

Không tuyên bố đã chạy app, test hoặc build nếu thực tế chưa thực hiện.

## Hướng dẫn theo từng loại yêu cầu

### Chỉ đổi màu hoặc style

- Kiểm tra style tại widget đang hiển thị trước.
- Nếu màu được lấy từ theme hoặc file màu chung, chỉ kiểm tra định nghĩa liên quan.
- Không đổi bảng màu toàn ứng dụng khi người dùng chỉ yêu cầu một thành phần.
- Không sửa các màn hình khác để đồng bộ nếu chưa được yêu cầu.

### Chỉ sửa một màn hình

- Tập trung vào file màn hình đó và component phụ thuộc trực tiếp.
- Không rà soát các màn hình cùng cấp.
- Không thay đổi navigation hoặc cấu trúc app nếu không liên quan.

### Sửa widget dùng chung

- Xác định các nơi sử dụng widget bằng tìm kiếm có mục tiêu.
- Đánh giá ảnh hưởng trước khi sửa hành vi hoặc giao diện dùng chung.
- Nếu thay đổi có thể làm nhiều màn hình bị ảnh hưởng, thông báo rõ phạm vi đó.

### Sửa lỗi

- Tái hiện hoặc xác định nguyên nhân từ thông báo lỗi và đoạn code liên quan.
- Sửa nguyên nhân gốc trong phạm vi nhỏ nhất.
- Không viết lại toàn bộ màn hình chỉ để xử lý một lỗi cục bộ.

## Khi nào được phép phân tích rộng hơn?

Chỉ mở rộng phạm vi khi có ít nhất một lý do cụ thể:

- Người dùng yêu cầu thay đổi toàn ứng dụng hoặc nhiều màn hình.
- Thành phần cần sửa phụ thuộc trực tiếp vào nhiều file.
- Lỗi có dấu hiệu bắt nguồn từ kiến trúc, state dùng chung hoặc luồng dữ liệu.
- Thay đổi nhỏ có nguy cơ gây lỗi ở nơi khác.
- Kiểm tra hẹp phát hiện vấn đề cần truy vết thêm.

Khi mở rộng, chỉ đọc các phần liên quan đến nguyên nhân hoặc ảnh hưởng. Không mặc định rằng phải đọc toàn bộ dự án.

## Những việc không được tự ý làm

- Đọc toàn bộ source code cho một yêu cầu nhỏ.
- Phân tích lặp lại cùng một file mà không có mục đích mới.
- Refactor code ngoài phạm vi.
- Đổi giao diện các màn hình không được nhắc đến.
- Thay đổi API, database hoặc dependency không cần thiết.
- Xóa file, dữ liệu hoặc thay đổi Git của người dùng.
- Tạo thêm abstraction hoặc component chỉ vì sở thích cá nhân.
- Báo cáo dài dòng về những bước không cần thiết.

## Ví dụ

**Yêu cầu:** "Đổi màu nút Lưu trong `edit_user_screen.dart` sang màu xanh."

**Cách làm đúng:**
1. Mở `edit_user_screen.dart`.
2. Tìm widget nút Lưu và xác định nơi đặt màu.
3. Nếu màu được lấy từ theme, chỉ mở phần định nghĩa theme liên quan.
4. Sửa màu của nút Lưu.
5. Xem diff và kiểm tra file vừa sửa.
6. Báo lại file đã thay đổi.

**Không làm:**
- Đọc toàn bộ thư mục `lib/`.
- Phân tích dashboard, service, API và các màn hình không liên quan.
- Đổi màu toàn bộ ứng dụng.
- Refactor tất cả button trong dự án.

## Ưu tiên cuối cùng

**Đúng yêu cầu > thay đổi tối thiểu > bảo tồn code hiện có > kiểm tra phù hợp > báo cáo ngắn gọn.**

Nếu có thể hoàn thành an toàn bằng một thay đổi nhỏ, không biến nó thành một đợt phân tích hoặc tái cấu trúc toàn dự án.

