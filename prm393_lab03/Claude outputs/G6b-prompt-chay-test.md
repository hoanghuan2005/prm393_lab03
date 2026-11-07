# G6b — Prompt kiểm tra

Dán prompt dưới đây vào Claude Code (hoặc AI bạn đang dùng), mở ở thư mục repo `prm393_lab03` (thư mục cha có `.git`), nhánh `price-chart`.

```text
Bối cảnh: repo prm393_lab03, nhánh price-chart. Bước G6b (gộp "Giá tham khảo" vào khu "Lịch sử giá" của Chi tiết món) đã được code sẵn nhưng CHƯA chạy format/analyze/test. Việc của bạn chỉ là kiểm tra và sửa lỗi biên dịch/lint/test, KHÔNG đổi hành vi, KHÔNG refactor, KHÔNG commit.

Các file G6b đã đổi (trong prm393_lab03/):
- lib/widgets/price_history_panel.dart (viết lại: khu giá duy nhất, biểu đồ cộng đồng + chấm rỗng "Giá bạn ghi", hoặc biểu đồ từ giá của chính người dùng; nút "Thêm link Shopee"; "Xem toàn màn hình"; "Giá người khác ghi" nằm bên trong)
- lib/viewmodels/own_price_view.dart (mới: ownPriceView, ownPriceDots)
- lib/viewmodels/price_history_viewmodel.dart (thêm getter reportCount)
- lib/widgets/price_history_chart.dart (thêm tham số ownPrices, caption; chú thích "Giá bạn ghi")
- lib/widgets/shared_price_section.dart (thêm tham số embedded)
- lib/screens/item_detail_screen.dart (bỏ PriceHistoryEntryCard và SharedPriceSection riêng, dùng PriceHistoryPanel)
- test/price_history_panel_test.dart (mới: 2 unit test + 5 widget test)

Chạy trong prm393_lab03/:
1. dart format lib test
   Sau khi format, chạy `git status`: nếu có file NGOÀI danh sách trên bị đổi thì trả file đó về bản HEAD (`git checkout -- <file>`).
2. flutter analyze
3. flutter test

Nếu có lỗi:
- Chỉ sửa trong các file ở danh sách trên, sửa tối thiểu để hết lỗi.
- Không sửa aggregateDaily, compareGroup, computeBand, fillForward, axisDayIndices, stepSpots, smoothSteps.
- Nếu một test CŨ hỏng vì hành vi mới của G6b (thẻ "Giá tham khảo" riêng đã bỏ, "Giá người khác ghi" nay nằm trong khu "Lịch sử giá"), đừng tự sửa test đó: liệt kê tên test + lỗi để tôi quyết định.

Kết thúc: báo kết quả 3 lệnh (số test qua/hỏng), danh sách file đã sửa thêm và lý do, mục "Ngoài phạm vi, tôi không sửa". Không commit.
```

## Kiểm tra trên máy (sau khi xanh)

- Món nhập tay không có link (vd "Máy ảnh film mini"), có ≥ 5 ngày ghi giá: thấy biểu đồ "Giá bạn đã ghi" và nút "Thêm link Shopee" (bấm mở màn sửa món).
- Món có link, mới chỉ mình bạn ghi: biểu đồ "Giá bạn đã ghi" + dòng "Chưa đủ người ghi giá để vẽ đường cộng đồng (n lần ghi)".
- Món có link và đủ dữ liệu cộng đồng (hoặc món mẫu): biểu đồ "Vùng tô…", chấm rỗng "Giá bạn ghi", nút "Xem toàn màn hình" mở màn Giá tham khảo.
- Món chỉ có 1 lần ghi: không có biểu đồ, chỉ danh sách mốc giá + "Ghi thêm giá để xem biến động".
- Chi tiết món không còn thẻ "Giá tham khảo" riêng; "Cùng món ở shop khác" nằm ngay sau khu "Lịch sử giá".

## Commit (khi bạn đã xác nhận)

```
feat(price-history): merge reference prices into item price section
```

## Gợi ý mục `docs/ai-log.md`

```markdown
### 2026-11-07 – <Tên bạn> – G6b (gộp Giá tham khảo vào khu Lịch sử giá)
- **Công cụ:** Claude (Cowork).
- **Prompt:** Prompt G6b trong kế hoạch bản 13.
- **Kết quả:** `PriceHistoryPanel` thành khu giá duy nhất của Chi tiết món: đủ dữ liệu cộng đồng thì vẽ biểu đồ Giá tham khảo kèm chấm rỗng "Giá bạn ghi" và nút "Xem toàn màn hình"; không đủ thì vẽ từ priceSnapshots của chính người dùng ("Giá bạn đã ghi") kèm dòng "Chưa đủ người ghi giá…"; món không có link có nút "Thêm link Shopee". "Giá người khác ghi" nằm trong khu (`SharedPriceSection(embedded: true)`); bỏ thẻ `PriceHistoryEntryCard` khỏi Chi tiết món. Thêm `own_price_view.dart`, `PriceHistoryChart.ownPrices/caption`, `PriceHistoryViewModel.reportCount`, `test/price_history_panel_test.dart`.
- **Quyết định:** <Chấp nhận / Sửa>.
- **Lý do / phần đã sửa tay:** <…>
```
