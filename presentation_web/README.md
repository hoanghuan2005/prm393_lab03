# Why I Buy? — web thuyết trình

Trang web một trang dùng để thuyết trình app **Why I Buy?** (PRM393):
- **Bên trái:** điện thoại 3D (Three.js). Màn hình của nó là giao diện app dựng lại bằng HTML, dùng đúng màu, chữ và dữ liệu mẫu trong code Flutter.
- **Bên phải:** phần giải thích của từng bước.
- **Điều khiển:** mỗi lần lăn chuột (hoặc bấm ↓, PageDown, Space, nút "next" của bút trình chiếu) chuyển đúng một bước của luồng, và điện thoại tự chạy demo của bước đó.

Luồng: Vấn đề → Người dùng & mục tiêu → Mở app → Đăng nhập → Trang chủ → Lưu món → Từ máy tính → Cân nhắc → Chờ sale → Trước khi mua → Ghi khoản mua → Ngân sách → Mô hình → Góc nhìn → Chiêm nghiệm → Cá nhân → Hệ sinh thái → Bằng chứng → Cảm ơn.

## Chạy

```bash
cd presentation_web
npm install
npm run dev        # http://localhost:5178
```

## Bản trình chiếu (không cần mạng)

```bash
npm run build      # tạo dist/index.html: một file duy nhất, đã nhúng JS, CSS, font, icon
```

Mở `dist/index.html` bằng Chrome hoặc Edge. Có thể chép file này sang USB hay máy của lớp, không cần mạng và không cần cài gì.

## Phím tắt khi trình chiếu

| Phím | Tác dụng |
|---|---|
| Lăn chuột, ↓, →, PageDown, Space | Bước tiếp |
| ↑, ←, PageUp, Shift+Space | Bước trước |
| Home / End | Về đầu / tới cuối |
| F | Bật/tắt toàn màn hình |
| R | Chạy lại demo của bước đang xem |
| Bấm vào một bước trên thanh luồng ở đáy | Nhảy tới bước đó |

Thêm `#<id>` vào cuối địa chỉ để mở thẳng một bước, ví dụ `#dang-nhap`, `#goc-nhin`.

## Sửa nội dung

- `src/data/chapters.js`:
  - Toàn bộ chữ bên phải: tiêu đề, ý chính, nhãn công nghệ.
  - Tư thế điện thoại ở mỗi bước (`pose`).
  - Màn hiện trên điện thoại (`screen`).
  - Số liệu phần "Bằng chứng" (`evidence`).
  - Tên thành viên (`team`).
- `src/screens/<id>.js`: từng màn app trong điện thoại, gồm `render()` (giao diện) và `demo()` (kịch bản demo bằng GSAP). Các thành phần dùng chung nằm trong `src/screens/kit.js`.
- `src/three/phone.js`: mô hình điện thoại 3D.

Khi dựng màn mới, mở `http://localhost:5178/lab.html?screen=<id>&t=<giây>` để xem riêng một màn ở thời điểm bất kỳ của demo.

## Ghi chú trung thực

- Mọi tính năng trên trang đều có trong code Flutter. Màn hình khoá đầy thông báo sale ở bước "Vấn đề" là **minh hoạ**, trang có ghi chú rõ điều này.
- Dữ liệu trên màn là dữ liệu mẫu của `DemoDataService`, lấy ngày 07/11/2026 làm "hôm nay".
- Số test ở phần "Bằng chứng" là kết quả chạy lại ngày 07/11/2026:
  - Security Rules: 268/268 ca đạt.
  - App mobile: 609/610 test đạt. Ca còn lỗi là "Bỏ qua … Hoàn tác" trong `decision_and_budget_test.dart`.
  - Web admin: 42/42 test đạt.
  - Chạy lại và cập nhật các số này trước buổi thuyết trình.
