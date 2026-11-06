# Mô hình dữ liệu Firestore

Dữ liệu cá nhân nằm dưới `users/{uid}` và chỉ chủ tài khoản đọc/ghi; dữ liệu dùng chung (`announcements`, `saleEvents`, `sharedPrices`, `extensionPairings`) nằm ở gốc. Quyền theo vai trò xem mục **Vai trò và quyền** ngay dưới; `firestore.rules` từ chối mọi đường dẫn không khai báo. Đường dẫn chỉ được viết trong `lib/services/firestore_paths.dart`. Model ở `lib/models/`. Tiền là `int` VND; "Ràng buộc (rules)" = điều `firestore.rules` kiểm tra khi ghi, "—" = rules không kiểm tra.

## Vai trò và quyền

Vai trò nằm ở `users/{uid}.role`. **Admin đầu tiên được đặt trên Firebase Console** (xem README); sau đó chỉ admin đổi vai trò người khác. Web admin chỉ cho `staff` và `admin` đăng nhập, tài khoản khác bị đăng xuất kèm thông báo. Mobile dùng cho mọi vai trò (nhân viên cũng là người dùng app).

| Collection | Create | Read | Update | Delete | Màn hình dùng |
|:---|:---|:---|:---|:---|:---|
| `users/{uid}` | Chủ tài khoản lần đầu đăng nhập, `role = user` | Chủ tài khoản; staff, admin | Chủ tài khoản (không đổi `role`); admin chỉ đổi `role` của người khác | Chủ tài khoản | Cá nhân; web danh sách người dùng |
| `users/{uid}/purchases`, `wishlistItems` (+ `priceSnapshots`), `decisions`, `budgetGroups`, `budgets`, `reflections`, `ownedItems`, `feedback`, `extensionSessions` | Chủ tài khoản (một số: cả extension đã liên kết) | Chủ tài khoản (+ extension) | Chủ tài khoản; `priceSnapshots`, `decisions`, `feedback` không sửa | Chủ tài khoản | Các màn mobile; **staff không đọc được**; admin chỉ **đọc** `purchases`, `wishlistItems` (đếm cho web, không sửa/xoá) |
| `users/{uid}/inbox` | Staff, admin | Chủ tài khoản | Chủ tài khoản, chỉ `readAt` | Chủ tài khoản | Hộp thư mobile; web gửi tin riêng |
| `announcements` | Staff, admin (`status = published`) | Mọi người đã đăng nhập: bản `published`; staff: tất cả | Staff, admin | — (lưu trữ) | Hộp thư mobile; web form thông báo |
| `saleEvents` | Staff, admin (`draft` hoặc `published`) | Mọi người đã đăng nhập: bản `published`; staff: tất cả | Staff, admin | — (lưu trữ) | Lịch sale mobile; web quản lý đợt sale |
| `saleSuggestions` | Người dùng (không ẩn danh), cho chính mình, `status = pending` | Người đề xuất; staff, admin | Staff, admin: `pending` → `approved` (cùng batch tạo `saleEvents`) hoặc `rejected` (kèm `reason`), một lần | Người đề xuất khi còn `pending` | Đề xuất sale mobile; web duyệt đề xuất |
| `/{path=**}/wishlistItems`, `/{path=**}/purchases` (collection group) | — | Admin: truy vấn `count` / `sum` cho dashboard | — | — | Web tổng quan |
| `sharedPrices/{key}/reports` | Tài khoản không ẩn danh, id băm của chính mình | Mọi người đã đăng nhập | Như create | Người tạo | Chi tiết món |
| `extensionPairings` | Extension (ẩn danh) | Ai có id (không liệt kê được) | Tài khoản không ẩn danh: duyệt/từ chối 1 lần | Extension | Liên kết extension |

**Chuyển trạng thái theo vai trò**

| Collection | Ai | Chuyển được |
|:---|:---|:---|
| `announcements.status` | Staff, admin | `published` → `published` (sửa) · `archived`; `archived` giữ nguyên |
| `saleEvents.status` | Staff, admin | `draft` → `draft` · `published` · `archived`; `published` → `published` · `archived`; `archived` giữ nguyên |
| `wishlistItems.status` | Chủ tài khoản | `considering` ↔ `purchased` (cần `purchaseId`) · `skipped` |
| `extensionPairings.status` | Tài khoản không ẩn danh | `pending` → `approved` (của chính mình) · `rejected` |

Kiểm thử: `firebase/tests/rules.test.mjs` chạy trên Firestore Emulator, mỗi vai trò có ít nhất một ca cho phép và một ca từ chối ở mỗi collection; kết quả ở `evidence/rules/firestore-rules-results.md`.

## `users/{uid}` – `UserProfile` · ghi bởi `UserService`, `DemoDataService` (nhóm)

| Trường | Kiểu | Bắt buộc | Ràng buộc |
|:---|:---|:-:|:---|
| `role` | string | | `user` · `staff` · `admin`; thiếu trường = `user`. App ghi `user` khi tạo; chủ tài khoản không đổi được; chỉ admin đổi, chỉ đổi riêng trường này, không đổi của chính mình |
| `displayName` | string? | | — |
| `email` | string? | | — |
| `fcmTokens` | string[] | | token FCM của các máy (`NotificationService`) |
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
| `productKey`, `modelId`, `imageUrl` | string? | | — (extension Chrome: `shopee:<shopId>:<itemId>`, mã phân loại, ảnh) |
| `variantLabel` | string? | | null hoặc ≤ 60 ký tự (tên phân loại đã chọn) |
| `buyIntentAt` | timestamp? | | null hoặc timestamp – đã bấm "Mua" trên extension, chờ app ghi khoản mua |
| *(khi `status == purchased`)* | | | rules bắt buộc có `purchaseId` (string) |

App chỉ ghi các trường extension khi có giá trị, nên sửa món trong app không xoá chúng. `buyIntentAt` được xoá khi ghi khoản mua (`buyFromWishlist`) hoặc bấm "Chưa mua" (`clearBuyIntent`).

### `wishlistItems/{id}/priceSnapshots/{sid}` – `PriceSnapshot` · **chỉ thêm, không sửa**

| Trường | Kiểu | Bắt buộc | Ràng buộc (rules) |
|:---|:---|:-:|:---|
| `amountVnd` | int | ✓ | 1 … 999.999.999 |
| `observedAt` | timestamp | ✓ | là timestamp |
| `source` | string | | nếu có: `manual` · `demo` · `extensionPage` · `community` (giá người khác ghi mà người dùng chọn dùng; không bao giờ chia sẻ lại) |
| `priceType` | string | | nếu có: `single` (mặc định) · `range` · `flash` · `sale` (giá đang giảm; như extension: món có giá khác thì giá sale không làm giá chính / so sánh; không chia sẻ lên `sharedPrices`) · `afterVoucher` |
| `minVnd`, `maxVnd`, `originalVnd` | int? | | — (khoảng giá: `amountVnd` = `minVnd`; giá gạch ngang) |
| `confirmation` | string | | — `userConfirmed` (mặc định) · `unconfirmed` (giá đọc từ trang, chưa xác nhận) |
| `variantLabel` | string? | | — |

Giá `afterVoucher` không cập nhật `latestPriceVnd` và không dùng để so sánh (`PriceInsights.comparable`).

## `extensionSessions/{id}` – `ExtensionSession` · tạo bởi extension Chrome, duyệt bởi `ExtensionSessionService`

| Trường | Kiểu | Bắt buộc | Ràng buộc (rules) |
|:---|:---|:-:|:---|
| `deviceLabel` | string | ✓ | 1–60 ký tự (khi tạo) |
| `status` | string | ✓ | tạo: `pending`; sửa: `pending` · `approved` · `rejected` · `revoked` |
| `createdAt`, `updatedAt` | timestamp | | — |
| `approvedAt` | timestamp? | | — (server time khi Đồng ý) |

Yêu cầu `pending` quá 5 phút coi như hết hạn (app không hỏi nữa).

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

## `feedback/{id}` – ghi bởi `FeedbackService`

"Gửi góp ý" (Cá nhân → Hỗ trợ & thông tin). Chỉ tạo mới, không sửa (rules `update: false`).

| Trường | Kiểu | Bắt buộc | Ràng buộc (rules) |
|:---|:---|:-:|:---|
| `message` | string | ✓ | 1–1000 ký tự |
| `appVersion` | string | | `AppConstants.appVersion` |
| `createdAt` | timestamp | | server time |

## `sharedPrices/{productKey}/reports/{reportId}` – `SharedPriceReport` · ghi bởi `SharedPriceService` · **dữ liệu dùng chung, ẩn danh**

"Giá người khác ghi" (đặc tả 8.3, quyết định 3). Nằm ngoài `users/{uid}`; mọi người đã đăng nhập đều đọc được, nên bản ghi **không chứa uid, tên hay link**.

| Trường | Kiểu | Bắt buộc | Ràng buộc (rules) |
|:---|:---|:-:|:---|
| *(id)* | string | ✓ | = sha256(`uid|productKey|modelKey`) dạng hex thường; rules tự tính lại, nên mỗi tài khoản Google chỉ có **một bản ghi cho mỗi sản phẩm + phân loại** và không ghi được dưới id người khác |
| `modelKey` | string | ✓ | `none` hoặc mã phân loại (chỉ chữ số) |
| `priceType` | string | ✓ | `single` · `range` (cận dưới) · `flash`; không nhận `afterVoucher` |
| `amountVnd` | int | ✓ | 1 … 999.999.999 |
| `observedAt` | timestamp | ✓ | trong 3 ngày qua, không ở tương lai (± 5 phút) |
| `source` | string | ✓ | `manual` · `extensionPage`; không nhận `demo`, `community` |

`productKey` (id document cha) phải dạng `shopee:<shopId>:<itemId>`: lấy từ món extension lưu, hoặc tách từ link Shopee của món nhập tay (`ShopeeLink`, đặc tả 6.4). Chỉ tài khoản không ẩn danh được ghi (khách và extension liên kết chỉ đọc), để một người không thành nhiều người. Tắt "Góp giá của tôi" xoá bản ghi của món đang mở; bản ghi khác hết hiệu lực sau 3 ngày vì không còn được tính. Kiểm chứng bằng Firestore Emulator: 16/16 ca cho phép/từ chối đạt.

Cách so sánh (`SharedPriceSummary`): chỉ cùng sản phẩm, cùng `modelKey`, cùng loại giá, ghi trong 3 ngày; bỏ bản ghi của chính mình; bỏ giá lệch > 30% so với trung vị; cần ≥ 2 người còn lại. Kết quả chỉ là gợi ý, người dùng phải xác nhận mới dùng làm giá của món.

## `users/{uid}/inbox/{id}` – tin nhắn riêng · ghi bởi web admin

| Trường | Kiểu | Bắt buộc | Ràng buộc (rules) |
|:---|:---|:-:|:---|
| `title` | string | ✓ | 1–80 ký tự |
| `body` | string | ✓ | 1–500 ký tự |
| `kind` | string | ✓ | `message` · `feedback_reply` · `suggestion_reply` (kết quả duyệt đề xuất sale) |
| `refId` | string? | | id liên quan (ví dụ góp ý được trả lời), ≤ 128 |
| `createdAt` | timestamp | ✓ | server time |
| `createdBy` | string | ✓ | uid người gửi (staff/admin), phải là người đang ghi |
| `readAt` | timestamp? | | `null` khi gửi; chủ tài khoản đặt khi đọc |

Không có trường nào khác (`keys().hasOnly`).

## `announcements/{id}` – thông báo chung · ghi bởi web admin

| Trường | Kiểu | Bắt buộc | Ràng buộc (rules) |
|:---|:---|:-:|:---|
| `title` | string | ✓ | 1–80 ký tự |
| `body` | string | ✓ | 1–500 ký tự |
| `status` | string | ✓ | `published` · `archived` |
| `createdAt` | timestamp | ✓ | server time, không đổi |
| `createdBy` | string | ✓ | uid người đăng, không đổi |
| `updatedAt` | timestamp | ✓ | server time mỗi lần ghi |

Mobile phải truy vấn có `where('status', '==', 'published')`, nếu không rules từ chối cả truy vấn.

## `saleEvents/{id}` – lịch sale · ghi bởi web admin

Đợt sale do nhóm theo dõi từ thông báo chính thức của sàn (trước đây nhập tay ở Remote Config `sale_calendar`).

| Trường | Kiểu | Bắt buộc | Ràng buộc (rules) |
|:---|:---|:-:|:---|
| `name` | string | ✓ | 1–40 ký tự (ví dụ "11.11") |
| `date` | timestamp | ✓ | ngày sale |
| `type` | string | ✓ | `double_day` · `mid_month` · `payday` · `other` (khớp `SaleType`) |
| `confirmed` | bool | ✓ | sàn đã công bố (chỉ đợt đã xác nhận được tính trong Thẻ Quyết Định) |
| `status` | string | ✓ | `draft` · `published` · `archived` |
| `updatedAt` | timestamp | ✓ | server time |
| `updatedBy` | string | ✓ | uid người ghi |
| `suggestionId` | string? | | đặt khi sự kiện được tạo từ đề xuất của người dùng (batch duyệt), ≤ 128 |

Chuyển trạng thái: `draft` → `draft` · `published` · `archived`; `published` → `published` · `archived`; `archived` là cuối (không khôi phục, không sửa).

## `saleSuggestions/{id}` – đề xuất đợt sale · tạo trên app, duyệt trên web

Luồng liên vai trò của Final Assignment: người dùng đề xuất một đợt sale trên app (`pending`) → staff duyệt hoặc từ chối kèm lý do trên web → app của người gửi cập nhật ngay (đề xuất của tôi + `inbox`, `kind = suggestion_reply`).

| Trường | Kiểu | Bắt buộc | Ràng buộc (rules) |
|:---|:---|:-:|:---|
| `uid` | string | ✓ | phải là người tạo |
| `name` | string | ✓ | 1–40 ký tự (thành tên `saleEvents` khi duyệt) |
| `date` | timestamp | ✓ | ngày sale |
| `note` | string? | | ≤ 200 ký tự (nguồn: "Shopee đã đăng banner…") |
| `status` | string | ✓ | tạo: `pending`; staff đổi một lần sang `approved` · `rejected` |
| `createdAt` | timestamp | ✓ | server time |
| `reason` | string | khi `rejected` | 1–200 ký tự, người gửi đọc trong hộp thư |
| `saleEventId` | string | khi `approved` | id `saleEvents` tạo trong cùng batch (`existsAfter`) |
| `reviewedBy`, `reviewedAt` | string, timestamp | khi duyệt | uid staff đang ghi, server time |

Duyệt là một batch: tạo `saleEvents` (`status = published`, `suggestionId`) + đổi đề xuất sang `approved` + ghi `users/{uid}/inbox`. Từ chối: đổi sang `rejected` kèm `reason` + ghi `inbox`. Code: `packages/core` (`FirestoreSaleSuggestionService`).

## `reflections/{yyyy-MM}` – `Reflection` · ghi bởi `ReflectionService`, `DemoDataService`

Id document khớp `^[0-9]{4}-[0-9]{2}$`. Trường: `rating` (int 1–5, bắt buộc – rules), `goal` (string?, ≤ 200 – code), `updatedAt`.

## Index tổng hợp (`firestore.indexes.json`)

| Collection | Phạm vi | Trường |
|:---|:---|:---|
| `wishlistItems` | collection | `status` ↑, `createdAt` ↓ |
| `decisions` | collection | `itemId` ↑, `at` ↓ |
| `purchases` | collection | `budgetGroupId` ↑, `occurredAt` ↓ |
| `wishlistItems` | collection group | `status` ↑, `latestPriceVnd` ↑ (dashboard: `sum` giá món bỏ qua) |
| `saleEvents` | collection | `status` ↑, `date` ↑ (app: lịch sale đang hiển thị) |
| `saleSuggestions` | collection | `status` ↑, `createdAt` ↑ / ↓ (web: hàng chờ duyệt, đã xử lý) |
| `saleSuggestions` | collection | `uid` ↑, `createdAt` ↓ (app: đề xuất của tôi) |
| `announcements` | collection | `status` ↑, `createdAt` ↓ (app: hộp thư) |

`fieldOverrides` (index một trường phạm vi collection group cho dashboard): `wishlistItems.status`, `wishlistItems.createdAt`, `purchases.createdAt`, `purchases.motive`, `purchases.amountVnd`. Trên dashboard, `count()` món bỏ qua và `sum(latestPriceVnd)` chạy ở hai truy vấn riêng: khi có `sum()` Firestore đi theo index `status + latestPriceVnd` nên món chưa có giá bị bỏ khỏi cả phép đếm.

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
