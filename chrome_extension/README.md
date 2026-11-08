# Why I Buy? – Save & Decide (Chrome Extension) · v0.3.1

Extension bám theo **repo `prm393_lab02`** (handoff mục 9 và phần EXT / X2–X5), **Figma "Why I Buy ver2"** (Flow 11–13, EXT-1…8, X2–X5) và **Build Plan**.
Stack: WXT + React + TypeScript, Manifest V3, lưu trên máy trước rồi mới đồng bộ.

## Hai bản build
| Lệnh | Thư mục | Quyền | Dùng cho |
|---|---|---|---|
| `npm run build` | `.output/chrome-mv3` | activeTab, storage, sidePanel | **Bản trình bày (MVP)**: đọc link + tiêu đề tab khi bấm icon |
| `npm run build:lab` | `.output/chrome-mv3-lab` | + scripting, alarms, notifications | **Thử nghiệm EX-10**: đọc giá/loại/Flash Sale trên trang, voucher, thông báo. Mặc định tắt. Chưa qua cổng 6.3 |

Cài: `chrome://extensions` → Developer mode → Load unpacked → chọn MỘT trong hai thư mục (mỗi bản có bộ nhớ riêng).
`npm test` (logic, 28 nhóm test) · `npm run typecheck`.

## Đối chiếu yêu cầu
| Yêu cầu (repo / Figma) | Trạng thái |
|---|---|
| Mô hình dữ liệu handoff 9.1: `WishlistItem`, `PriceSnapshot` (priceType, source, confirmation), `Decision` chỉ thêm, `productKey`, `saveChannel`, `priority` 1–5 (mặc định 3), tên ≤ 60 ký tự, id = hash(…), không lưu 0 ₫ | Có. Tự chuyển dữ liệu định dạng cũ |
| EXT-1 không chặn lưu (dải "Chưa liên kết"), EXT-2…EXT-8 | Có |
| Chống trùng: cùng sản phẩm **và** cùng phân loại (E03) | Có |
| Giá đọc từ trang ở trạng thái **chưa xác nhận**, xác nhận một chạm | Có (bản Lab) |
| Độ mới: ≤ 3 ngày / 4–7 ngày kèm ngày / > 7 ngày + "Xác nhận lại"; chỉ so cùng loại giá, cùng phân loại | Có |
| Rules Engine 9.4: khaDung (biên 10%, dự phòng), nhãn tóm tắt 7 mức theo thứ tự, không chia cho 0 | Có |
| X3: ba nút cùng kiểu; **"Mua · mở form trên điện thoại" chỉ ghi ý định**, món thành Đã mua khi app ghi khoản mua | Có |
| X4: gửi mã → **chờ duyệt trên điện thoại (25f)** → token; mã sai / hết hạn / khoá sau 5 lần | Có |
| Đồng bộ hai chiều (EX-07), Idempotency-Key, thử lại 1 s, 2 s, 4 s… tối đa 5 phút khi lỗi mạng / 5xx / 429, dừng ở 401 | Có |
| E04, E06/EXT-8, E07/X2a, E08, E09, E11, E14 | Có |
| Nhãn đồng bộ "Chỉ trên máy · Chờ đồng bộ · Đã đồng bộ (chỉ khi server xác nhận) · Lỗi đồng bộ" | Có |
| Màu nhãn giá "Thấp hơn" #DCF1E3 / #1B5E36 (handoff 9.3) | Có |
| Phím Esc (popup đóng, trang đóng Decision Card) | Có. Phóng to 200% cần kiểm tra trên máy |

## Voucher (bản Lab, mặc định tắt)
- Đọc voucher **đang hiển thị** trên trang món, kể cả **danh sách người dùng tự bấm mở** ("Mã Giảm Giá Của Shop").
- Phân loại: mã của Shop · mã Shopee · vận chuyển · hoàn xu; nhận biết **Chưa lưu / Đã lưu**, **HSD**, **Đã dùng x%**, **hết lượt**.
- Ước tính: mã đơn tốt nhất, và **dùng chung 1 mã Shop + 1 mã Shopee** (mã Shopee tính trên phần còn lại; Shopee có thể giới hạn).
- Có thể **lưu giá sau voucher** thành `PriceSnapshot(priceType: afterVoucher, confirmation: userConfirmed)` — handoff 9.1: chỉ để tham khảo cá nhân, không làm giá chính, không so với giá niêm yết.
- Không bấm "Lưu", không áp mã, không đọc kho voucher hay trang thanh toán. Lệch quyết định N5 → nhóm cần xác nhận trước khi đưa ra ngoài bản Lab.

## Chế độ demo (chưa có backend)
`WXT_BACKEND` và `WXT_API_BASE` trống → máy chủ giả trong extension, nhãn "Dữ liệu mô phỏng":
- Mã liên kết **482913**. Sau khi nhập mã, khung **"Bản demo · giả lập điện thoại"** có nút Đồng ý / Từ chối (thay cho màn 25f trên app).
- Decision Card: sau khi ghi ý định Mua, nút **"App đã ghi khoản mua"** giả lập app Android → đồng bộ về, món thành Đã mua.
- Cài đặt → **Công cụ demo**: giả lập app huỷ liên kết (E06 → EXT-8), giả lập lỗi server (E07 → X2a + thử lại), mở khoá mã.
- Ngân sách mẫu khớp Figma 31c (khả dụng 864.000 ₫).

## Kết nối app qua Firebase (`WXT_BACKEND=firebase`)
Extension đăng nhập **cùng tài khoản Google** với app và đọc/ghi thẳng `users/{uid}/…` trên Firestore của project `prm393-34056` (gói Spark, không cần máy chủ). Mã chuyển đổi ở `lib/firebaseMap.ts`, lời gọi Firestore ở `lib/firebaseApi.ts`.

**Liên kết (thay mã 6 số):** bấm "Đăng nhập Google để liên kết" → extension tạo `extensionSessions/{id}` trạng thái `pending` → app hỏi "Cho phép … liên kết?" → Đồng ý = `approved`. Huỷ liên kết trên app (Cá nhân → Thiết bị đã liên kết) = `revoked` → extension về EXT-8.

**Dữ liệu:** động cơ và nhóm đổi sang key của app (`khuyen-mai` → `sale`, `cong-nghe` → `tech`…); giá khoảng ghi `amountVnd` = giá thấp nhất; giá sau voucher không đổi `latestPriceVnd`; "Mua" chỉ ghi `buyIntentAt`, app ghi khoản mua; món xoá trên app thì máy xoá theo.

### Cài đặt một lần
1. ID extension cố định nhờ `key` trong manifest (`lib/extensionKey.ts`): **`onjedkaogmlffcaoimiefdbljlgomcai`**. Khoá riêng ở `extension-key.pem` (không đưa lên git).
2. [Google Cloud Console](https://console.cloud.google.com/apis/credentials?project=prm393-34056) → Create credentials → **OAuth client ID** → loại **Chrome Extension** → Item ID là ID ở trên. Chép Client ID.
3. Tạo `.env` từ `.env.example`: `WXT_BACKEND=firebase`, `WXT_OAUTH_CLIENT_ID=<Client ID>`.
4. Repo app: `firebase deploy --only firestore:rules` (rules có `extensionSessions` và các trường mới).
5. `npm run build` → `chrome://extensions` → Load unpacked → `.output/chrome-mv3`.

Chỉ chạy trên **Chrome** (`chrome.identity.getAuthToken`). Không có `.env` thì extension vẫn là bản demo.

## Còn chờ nhóm chốt
1. **Backend**: đã nối Firebase (mục trên). `HttpApi` (REST) giữ lại làm phương án dự phòng.
2. **Voucher (bản Lab)**: trái quyết định N5. Đang để tắt, ghi rõ trong Cài đặt.
3. **Extension gửi thông báo Flash Sale (bản Lab)**: handoff quy định thông báo do app gửi.
4. **Gói mua (màn 22)**: Spec để giai đoạn 5, extension chưa làm.

## Cấu trúc
```
entrypoints/popup      EXT-1…EXT-8
entrypoints/options    X2 / X2a / X3 (bảng phải) / X4 / X4a / X5
entrypoints/sidepanel  X3 bảng cạnh
entrypoints/background Nhắc Flash Sale (chỉ bản Lab)
components/            Icons, ui (PriceTag, VerdictTag, Stars, Switch, CodeInput…), PairForm, DecisionCard
features/items         model, url, price (độ mới, so được), repo (+ chuyển dữ liệu cũ), similar
features/decision      rules (khaDung, nhãn tóm tắt), context
features/pairing       liên kết có chờ duyệt, huỷ, 401
features/sync          đồng bộ hai chiều, thử lại giãn dần
features/reminders     giờ nhắc theo quy tắc thông báo
features/ex10          (Lab) đọc trang, voucher
lib/                   api (HttpApi + MockApi), firebaseApi + firebaseMap (bản Firebase), firebase, kv, format, env
tests/run.ts           35 nhóm test
```
