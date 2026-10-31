# Mô hình dữ liệu Firestore

Mọi dữ liệu nằm dưới `users/{uid}`; chỉ chủ tài khoản đọc/ghi (`firestore.rules`). Đường dẫn chỉ được viết trong `lib/services/firestore_paths.dart`. Model ở `lib/models/`. Tiền là `int` VND; "Ràng buộc (rules)" = điều `firestore.rules` kiểm tra khi ghi, "—" = rules không kiểm tra.

## `users/{uid}` – `UserProfile` · ghi bởi `UserService`, `DemoDataService` (nhóm)

| Trường | Kiểu | Bắt buộc | Ràng buộc |
|:---|:---|:-:|:---|
| `displayName` | string? | | — |
| `isAnonymous` | bool | ✓ | — |
| `createdAt` | timestamp | ✓ | server time khi tạo |
| `settings.coolingOffDays` | int? | | null → dùng Remote Config `cooling_off_days` |
| `settings.reminderHour` | int | | 0–23 (code), mặc định 20 |
| `settings.notificationsEnabled` | bool | | mặc định true |
| `shoppingStyles`, `favoriteBrands` | string[] | | Hồ sơ mua sắm (đặc tả 7.2): phong cách, thương hiệu hay dùng; ≤ 8 thẻ (code) |

## `purchases/{id}` – `PurchaseItem` · ghi bởi `PurchaseService`, `DemoDataService`

| Trường | Kiểu | Bắt buộc | Ràng buộc (rules) |
|:---|:---|:-:|:---|
| `title` | string | ✓ | 1–60 ký tự |
| `amountVnd` | int | ✓ | 1 … 999.999.999 |
| `motive` | string | ✓ | 1 trong 8 key: need, want, sale, emotion, social, convenience, ads, other |
| `occurredAt` | timestamp | ✓ | là timestamp |
| `note` | string? | | ≤ 200 ký tự |
| `budgetGroupId` | string | ✓ | — (mặc định `other`) |
| `wishlistItemId` | string? | | — (khi mua từ danh sách mong muốn) |
| `usedDiscountCode` | bool | | — |
| `createdAt`, `updatedAt` | timestamp | | — (server time) |
| `satisfaction` | int? | | null hoặc 1–5 (rules) – mức hài lòng, hỏi sau 7 ngày (A-16) |
| `satisfactionSkipped` | bool | | người dùng chọn "Bỏ qua"; không hỏi lại |
| `satisfactionAt` | timestamp? | | server time khi trả lời |

## `wishlistItems/{id}` – `WishlistItem` · ghi bởi `WishlistService`, `PurchaseService.buyFromWishlist`, `DemoDataService`

| Trường | Kiểu | Bắt buộc | Ràng buộc (rules) |
|:---|:---|:-:|:---|
| `title` | string | ✓ | 1–60 ký tự |
| `status` | string | ✓ | `considering` · `purchased` · `skipped` |
| `motive` | string? | | null hoặc 1 trong 8 key |
| `priority` | int | | 1–5 (mặc định 3) |
| `latestPriceVnd` | int? | | null hoặc 1 … 999.999.999 |
| `note` | string? | | ≤ 200 ký tự |
| `url`, `budgetGroupId`, `purchaseId` | string? | | — |
| `cooldownUntil`, `reviewAt`, `latestPriceAt`, `decidedAt` | timestamp? | | — |
| `saveChannel` | string | | — (`manual` · `share` · `extension`) |
| `confirmedDuplicate` | bool | | người dùng xác nhận trùng với đồ đang có / khoản mua gần đây (nhãn 5 của Decision Card) |
| `createdAt`, `updatedAt` | timestamp | ✓ / | — |

### `wishlistItems/{id}/priceSnapshots/{sid}` – `PriceSnapshot` · **chỉ thêm, không sửa**

| Trường | Kiểu | Bắt buộc | Ràng buộc (rules) |
|:---|:---|:-:|:---|
| `amountVnd` | int | ✓ | 1 … 999.999.999 |
| `observedAt` | timestamp | ✓ | là timestamp |
| `source` | string | | — (`manual` · `demo`) |

## `decisions/{id}` – `Decision` · **chỉ thêm, không sửa** · ghi bởi `WishlistService`, `PurchaseService.buyFromWishlist`, `DemoDataService`

| Trường | Kiểu | Bắt buộc | Ràng buộc (rules) |
|:---|:---|:-:|:---|
| `choice` | string | ✓ | `buy` · `wait` · `skip` · `undo` |
| `itemId` | string | ✓ | — |
| `at` | timestamp | ✓ | — (server time) |
| `reviewAt` | timestamp? | | — (chỉ với `wait`) |

## `budgetGroups/{groupId}` – `BudgetGroup` · ghi bởi `BudgetService.ensureDefaultGroups`, `DemoDataService`

`name` (string), `order` (int). Rules không kiểm tra trường. 6 nhóm mặc định, id cố định: `food` Ăn uống · `fashion` Thời trang · `tech` Công nghệ · `beauty` Làm đẹp · `study` Học tập · `other` Khác.

## `budgets/{yyyy-MM}` – `MonthlyBudget` · ghi bởi `BudgetService`, `DemoDataService`

Id document phải khớp `^[0-9]{4}-[0-9]{2}$` (rules). Trường: `limits` (map `groupId → int`, chỉ giá trị > 0), `updatedAt`.

Không lưu tổng riêng: **tổng ngân sách tháng = tổng `limits`**, nên không thể thấp hơn tổng các nhóm. Sheet ngân sách lưu mọi nhóm thay đổi trong một lần ghi (`BudgetService.setGroupLimits`).

Phần khả dụng cho danh sách mong muốn (`AvailableBudget`, đặc tả 7.1): `max(0, hạn mức − đã chi − dự phòng) × 90%`; dự phòng = chi trung bình mỗi ngày của nhóm trong tối đa 90 ngày gần nhất (không tính khoản mua từ danh sách mong muốn) × số ngày còn lại của tháng; bằng 0 khi người dùng có dưới 30 ngày dữ liệu. Có dưới 90 ngày dữ liệu thì chia cho số ngày thực có.

## `ownedItems/{id}` – `OwnedItem` · ghi bởi `ShoppingProfileService`

"Đồ đang dùng" trong Hồ sơ mua sắm (đặc tả 7.2, A-12). Người dùng tự nhập; không lấy lịch sử mua Shopee.

| Trường | Kiểu | Bắt buộc | Ràng buộc (rules) |
|:---|:---|:-:|:---|
| `name` | string | ✓ | 1–60 ký tự |
| `tags` | string[] | ✓ | ≤ 8 thẻ |
| `note` | string? | | ≤ 100 ký tự |
| `budgetGroupId` | string? | | — |
| `createdAt`, `updatedAt` | timestamp | | — |

Dùng cho tín hiệu S5 của Decision Card (cùng nhóm hoặc thẻ/tên xuất hiện trong tên món) và làm ứng viên "món có thể trùng".

## `reflections/{yyyy-MM}` – `Reflection` · ghi bởi `ReflectionService`, `DemoDataService`

Id document khớp `^[0-9]{4}-[0-9]{2}$`. Trường: `rating` (int 1–5, bắt buộc – rules), `goal` (string?, ≤ 200 – code), `updatedAt`.

## Index tổng hợp (`firestore.indexes.json`)

| Collection | Trường |
|:---|:---|
| `wishlistItems` | `status` ↑, `createdAt` ↓ |
| `decisions` | `itemId` ↑, `at` ↓ |
| `purchases` | `budgetGroupId` ↑, `occurredAt` ↓ |

Truy vấn hiện có trong code (`purchases` theo `occurredAt`, `wishlistItems` theo `createdAt`, `budgetGroups` theo `order`) chỉ dùng index một trường; ba index trên được khai báo sẵn cho truy vấn lọc theo trạng thái / món / nhóm.

## Quy tắc nghiệp vụ

1. **Món mong muốn ≠ khoản mua.** `wishlistItems` là món đang cân nhắc; chỉ `purchases` được tính vào "đã chi" và ngân sách.
2. **Mua từ danh sách mong muốn là một batch** (`PurchaseService.buyFromWishlist`): tạo purchase có `wishlistItemId`, đổi món sang `purchased` + `purchaseId` + `decidedAt` (xoá `reviewAt`), thêm decision `buy` – thành công hoặc thất bại cùng nhau.
3. **"Chờ" chỉ đặt `reviewAt`** (+ decision `wait`); trạng thái vẫn là `considering`. Người dùng chọn ngày (sau N ngày cân nhắc, sau 7 ngày hoặc tự chọn); giờ xem lại cố định 09:00 để ngoài khung 22:00–08:00.
4. **"Bỏ qua"** đổi trạng thái sang `skipped` + decision `skip`; hoàn tác (5 giây) hoặc "Cân nhắc lại" về sau đều đưa về `considering` + decision `undo`.
3a. **Nhắc xem lại** (`ReviewReminderService`, chỉ Android/iOS): không lưu Firestore. `WishlistViewModel` đồng bộ thông báo cục bộ theo danh sách món – món `considering` có `reviewAt` trong tương lai thì có một thông báo (id ổn định theo `itemId`), mọi món khác bị huỷ, kể cả khi đổi từ máy khác; đăng xuất huỷ hết. Món đã tới `reviewAt` hiện trong mục **"Cần xem lại"** trên mọi nền tảng (dự phòng khi tắt thông báo, web, Windows).
4a. **Xoá khoản mua liên kết món** (`PurchaseService.delete`): cùng một batch xoá purchase, đưa món về `considering` (xoá `purchaseId`, `decidedAt`), xoá decision `buy_{itemId}` (khoá chống mua trùng của `buyFromWishlist`, để món mua lại được) và thêm decision `undo`. Chỉ áp dụng khi món vẫn trỏ đúng purchase đó.
5. **Giá chưa biết là `null`, không bao giờ lưu `0`.** Có giá thì mỗi lần ghi giá thêm một `priceSnapshot` và cập nhật `latestPriceVnd` / `latestPriceAt`.
6. **Cooldown:** khi thêm món, `cooldownUntil = createdAt + coolingOffDays` trừ khi động cơ là Nhu cầu.
7. **Lịch sử chỉ thêm:** `priceSnapshots` và `decisions` không sửa được (rules `update: false`).
8. **Mất mạng (E04):** Firestore bật bộ nhớ đệm trên máy (`firebase_setup.dart`). Mọi lệnh ghi qua `awaitWrite` (`service_guard.dart`): server chưa xác nhận sau 5 giây thì coi như đã lưu trên máy, đếm trong `PendingWrites` và hiện dải "Đang chờ mạng" trên mọi màn; Firestore tự gửi khi có mạng. Đọc trước khi ghi (`buyFromWishlist`, `delete`) chuyển sang bộ nhớ đệm khi không có mạng. Đổi tài khoản thì `PendingWrites.reset()` – hàng chờ của tài khoản cũ chỉ gửi khi tài khoản đó đăng nhập lại.
9. **Món bỏ qua không có giá:** không cộng thành `0 ₫`. Màn Chiêm nghiệm, câu mẫu AI và PDF ghi "chưa ghi giá" hoặc "tổng giá đã ghi … (N món chưa ghi giá)"; dữ liệu gửi AI bỏ trường tổng khi không món nào có giá.

## Khác biệt giữa các nền tảng

| Tính năng | Android | Web | Windows |
|---|---|---|---|
| Firestore, Auth, ngân sách, Wishlist, PDF | Có | Có | Có |
| Góc nhìn AI (Firebase AI Logic) | Có | Có (App Check reCAPTCHA Enterprise) | Có khi có `assets/local/app_check.json`; không có thì dùng câu mẫu |
| Analytics, Remote Config | Có | Có | Không (giá trị mặc định) |
| FCM | Có | Có, sau khi bấm "Bật thông báo" ở Cá nhân | Không |
| Crashlytics | Có | Không (lỗi ghi ra console) | Không |
| Nhắc xem lại theo giờ | Có | Không – dùng mục "Cần xem lại" | Không – dùng mục "Cần xem lại" |
