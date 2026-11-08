# G2c — Prompt kiểm tra

Dán prompt dưới đây vào Claude Code (hoặc AI bạn đang dùng), mở ở thư mục repo `prm393_lab03` (thư mục cha có `.git`), nhánh `price-chart`.

```text
Bối cảnh: repo prm393_lab03, nhánh price-chart. Bước G2c (món mẫu trong danh sách mong muốn của tài khoản admin) đã được code sẵn nhưng CHƯA chạy format/analyze/test. Việc của bạn chỉ là kiểm tra và sửa lỗi biên dịch/lint/test, KHÔNG đổi hành vi, KHÔNG refactor, KHÔNG đổi firestore.rules, KHÔNG commit.

Các file G2c đã đổi (trong prm393_lab03/):
- lib/models/wishlist_item.dart (trường isDemo: đọc/ghi, copyWith, ==, hashCode)
- lib/services/demo_price_history_service.dart (addDemoItemsToMyWishlist, removeDemoItemsFromMyWishlist, DemoWishlistPick, DemoWishlistPicker, DemoPriceHistoryData.variantLabelOf)
- lib/viewmodels/price_history_demo_viewmodel.dart (addDemoItems, removeDemoItems; clear() gỡ món mẫu của admin trước)
- lib/widgets/price_history_demo_section.dart (2 nút + ConfirmDialog)
- lib/viewmodels/shared_price_viewmodel.dart (món isDemo không gửi giá: cả G7 lẫn "Giá người khác ghi")
- lib/viewmodels/wishlist_viewmodel.dart (realItems; consideringCount, cooldownCount, totalSavedAmount bỏ món isDemo)
- lib/app/providers.dart (Report và Insights nhận realItems)
- lib/widgets/wishlist_card.dart, lib/screens/item_detail_screen.dart (DemoDataBadge)
- test/demo_price_history_test.dart (3 test G2c + fake có 2 hàm mới)
- test/price_history_contribution_test.dart (1 test: món mẫu không gửi báo cáo G7)
- test/same_product_test.dart (1 test: món mẫu chỉ ghép với sản phẩm mẫu)

Chạy trong prm393_lab03/:
1. dart format lib test
   Sau khi format, chạy `git status`: nếu có file NGOÀI danh sách trên bị đổi thì trả file đó về bản HEAD (`git checkout -- <file>`).
2. flutter analyze
3. flutter test

Nếu có lỗi:
- Chỉ sửa trong các file ở danh sách trên, sửa tối thiểu.
- Không sửa DemoPriceHistoryData.generate, seed(), clearDemo(), pickLowestOffers, aggregateDaily, computeBand, fillForward.
- Nếu test "3 coded items from 3 groups…" hoặc "the picks…" hỏng vì dữ liệu mẫu không đủ shop (expect 4 / 3 nhóm / ≥ 2 shop khác), đừng hạ điều kiện: báo lại số thực tế để tôi quyết định.
- Nếu một test CŨ hỏng vì hành vi mới của G2c, đừng tự sửa test đó: liệt kê tên test + lỗi.

Kết thúc: báo kết quả 3 lệnh (số test qua/hỏng), danh sách file đã sửa thêm và lý do, mục "Ngoài phạm vi, tôi không sửa". Không commit.
```

## Kiểm tra trên máy (sau khi xanh)

Tài khoản admin → Cá nhân → Firebase Demo Area:

1. Bấm "Tạo dữ liệu giá mẫu" (nếu chưa có).
2. Bấm "Thêm món mẫu vào danh sách của tôi". Snackbar báo "Đã thêm 4 món mẫu vào danh sách."
3. Danh sách mong muốn có 4 món, đều mang nhãn "Dữ liệu mẫu". Số "n món đang cân nhắc" ở Trang chủ không đổi.
4. Mở từng món:
   - 3 món có mã: khu "Lịch sử giá" có biểu đồ Giá tham khảo; "Cùng món ở shop khác" có 2–3 shop cùng phân loại.
   - 1 món không có mã: không có thẻ "Cùng món ở shop khác".
5. Bấm "Thêm món mẫu…" lần nữa: báo không có món mới, danh sách vẫn 4 món.
6. Bấm "Gỡ món mẫu khỏi danh sách": danh sách trở lại như cũ, món thật còn nguyên.
7. (Tuỳ chọn) "Xoá dữ liệu giá mẫu" cũng gỡ luôn món mẫu trong danh sách của bạn.

## Commit (khi bạn đã xác nhận)

```
feat(price-history): add demo items to my wishlist for testing
```

## Gợi ý mục `docs/ai-log.md`

```markdown
### 2026-11-07 – <Tên bạn> – G2c (món mẫu trong danh sách của tôi)
- **Công cụ:** Claude (Cowork).
- **Prompt:** Prompt G2c trong kế hoạch bản 13.
- **Kết quả:** `WishlistItem.isDemo`. `DemoPriceHistoryService.addDemoItemsToMyWishlist/removeDemoItemsFromMyWishlist`: chọn 3 sản phẩm mẫu có mã (3 nhóm, mỗi món có ≥ 2 shop khác cùng phân loại có giá trong 7 ngày) và 1 sản phẩm không mã; tạo món bằng `WishlistService` (add rồi update thêm productKey, modelId, phân loại, isDemo); gỡ chỉ món isDemo kèm priceSnapshots và decisions. Hai nút trong Firebase Demo Area; "Xoá dữ liệu giá mẫu" gỡ luôn món mẫu của admin. Món isDemo: nhãn "Dữ liệu mẫu" ở danh sách và Chi tiết món, không gửi giá (G7, Giá người khác ghi), không tính vào Trang chủ, Góc nhìn, báo cáo tháng. Rules `wishlistItems` không giới hạn trường nên không phải sửa.
- **Quyết định:** <Chấp nhận / Sửa>.
- **Lý do / phần đã sửa tay:** <…>
```
