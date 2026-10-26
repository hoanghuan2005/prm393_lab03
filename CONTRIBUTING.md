# Hướng dẫn đóng góp – Why I Buy? (PRM393 Lab 3)

Tài liệu này là quy ước làm việc chung của nhóm. Đọc một lần trước khi commit đầu tiên.

## 1. Quy trình Git

- Cả nhóm làm **trực tiếp trên `main`**: không tạo nhánh, không mở Pull Request.
- Luôn `git pull --rebase` **trước khi bắt đầu làm** và **ngay trước khi push**:
  ```bash
  git pull --rebase
  # ... làm việc, commit ...
  git pull --rebase
  git push
  ```
- Nếu rebase báo xung đột: sửa xung đột, `git add <file>`, `git rebase --continue`. Không dùng `git push --force`.
- Commit nhỏ, mỗi commit một ý, để dễ rebase và dễ quay lui.

### Đặt tên commit

| Tiền tố | Dùng khi | Ví dụ |
|:---|:---|:---|
| `feat:` | Thêm tính năng / màn hình mới | `feat: màn Lịch sử mua hàng` |
| `fix:` | Sửa lỗi | `fix: giá null hiển thị thành 0đ` |
| `refactor:` | Đổi cấu trúc code, không đổi hành vi | `refactor: tách WishlistCard` |
| `docs:` | Chỉ sửa tài liệu | `docs: cập nhật ai-log` |
| `chore:` | Cấu hình, package, dọn dẹp | `chore: bật thêm lint` |

## 2. File thuộc phần base – không tự sửa

Những đường dẫn sau do người phụ trách base quản lý. Cần thay đổi thì nhắn người phụ trách base, **không tự sửa**:

- `lib/main.dart`
- `lib/app/` *(có từ B3)*
- `lib/core/` *(có từ B3)*
- `lib/models/`
- `lib/services/`
- `lib/theme/`
- `firestore.rules` *(có từ B2)*
- `pubspec.yaml` (kể cả thêm package)

Các đường dẫn ghi "có từ B2/B3" chưa tồn tại ở thời điểm viết tài liệu này; quy tắc áp dụng ngay khi chúng được tạo.

Hai file cấu hình Firebase **không ai được sửa**: `android/app/google-services.json`, `lib/firebase_options.dart`.

## 3. Quy ước code (tóm tắt)

- MVVM + Provider/ChangeNotifier. Widget chỉ đọc ViewModel; không gọi Firebase SDK, service hay analytics trực tiếp trong widget.
- Màu, cỡ chữ, khoảng cách chỉ lấy từ token trong `lib/theme/`. Không viết `Color(0x...)` trong `lib/screens/` và `lib/widgets/`. Không dùng chữ vàng trên nền trắng.
- Màn tải dữ liệu dùng `UiState` + `LoadingView` / `EmptyView` / `ErrorView`.
- Điều hướng qua `AppRoutes`, không rải `MaterialPageRoute`.
- Tiền là `int` VND; chưa có giá thì để `null`, không lưu `0`.
- Câu chữ tiếng Việt có dấu, trung tính: không khen/chê, không "tiết kiệm được", không tô đỏ khi vượt ngân sách; Mua · Chờ · Bỏ qua ngang hàng.

## 4. Checklist trước khi push

- [ ] `git pull --rebase` đã chạy, không còn xung đột.
- [ ] `dart format lib` đã chạy (không còn file nào bị đổi).
- [ ] `flutter analyze` sạch (`No issues found!`).
- [ ] Đã chạy thử trên máy (emulator hoặc thiết bị thật) phần mình vừa sửa.
- [ ] Không sửa `android/app/google-services.json` và `lib/firebase_options.dart`.
- [ ] Không có `Color(0x...)` trong `lib/screens/` và `lib/widgets/`.
- [ ] Câu chữ hiển thị trung tính, tiếng Việt có dấu.
- [ ] Không commit file bí mật (`assets/local/app_check.json`, `.env`).
- [ ] Nếu có dùng AI: đã ghi vào `docs/ai-log.md`.

## 5. Nhật ký AI (`docs/ai-log.md`)

Mỗi lần dùng công cụ AI (Claude, Copilot, Gemini, …) để viết/sửa code hoặc tài liệu, thêm **một mục** vào cuối `docs/ai-log.md` theo mẫu:

```markdown
### YYYY-MM-DD – <Tên thành viên> – <việc, ví dụ B1 / màn Wishlist>
- **Công cụ:** Claude Code / Copilot / Gemini / …
- **Prompt:** <dán prompt hoặc tóm tắt ngắn>
- **Kết quả:** <AI đã làm/đề xuất gì, file nào bị đổi>
- **Quyết định:** Chấp nhận | Sửa | Từ chối
- **Lý do / phần đã sửa tay:** <vì sao sửa hoặc từ chối>
```

Ghi trung thực, kể cả khi từ chối đề xuất của AI. Commit nhật ký cùng commit với thay đổi, hoặc bằng commit `docs:` riêng.
