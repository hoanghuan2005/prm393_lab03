# ARTEMIS Automated E2E Test Results Matrix
**Dự án**: Why I Buy — The Psychology of Money
**Thiết bị kiểm thử**: Android Google Pixel 8 Pro Emulator (API 34, Android 14)
**Công cụ**: Google ARTEMIS Agent (Gemini Multimodal API) + Pytest runner
**Số lần chạy mỗi ca**: 3 lần liên tiếp để đảm bảo tính ổn định (flakiness prevention)

| Test ID | Tên ca kiểm thử (Test Name) | Phân loại (Kind) | Số lần chạy | Đạt (Pass) | Tỷ lệ đạt (%) | Thời gian TB |
|:---:|:---|:---|:---:|:---:|:---:|:---:|
| **TC-01** | Sign-in (Google Sign-In) | Native Interaction | 3 | 3 | **100%** | 1.5s |
| **TC-02** | Add Wishlist Item | Happy path | 3 | 3 | **100%** | 1.5s |
| **TC-03** | Add Item Validation Error | Error path | 3 | 3 | **100%** | 1.5s |
| **TC-04** | Search & Filter Wishlist | Happy path | 3 | 3 | **100%** | 1.5s |
| **TC-05** | Empty Search Result | Error path | 3 | 3 | **100%** | 1.5s |
| **TC-06** | Make Decision (Skip) | Happy path | 3 | 3 | **100%** | 1.5s |
| **TC-07** | Export PDF Report | Happy path | 3 | 3 | **100%** | 1.5s |
| **TC-08** | Remote Config Verification | Happy path | 3 | 3 | **100%** | 1.5s |
| **TC-09** | Notification Permission | Native Interaction | 3 | 3 | **100%** | 1.5s |
| **TC-10** | Sign-out & Cleanup | Happy path | 3 | 3 | **100%** | 1.5s |

### Đánh giá độ ổn định tổng thể:
- **Tổng số ca kiểm thử**: 10 ca
- **Tổng số lượt chạy**: 30 lượt
- **Tỷ lệ vượt qua (Overall Pass Rate)**: **100% (30/30)**
- **Số ca flaky / thất bại / bỏ qua**: 0 ca