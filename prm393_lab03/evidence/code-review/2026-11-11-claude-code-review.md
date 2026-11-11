# Kết quả gốc: AI code review ngày 11/11/2026

- **Công cụ:** Claude Code (model Claude của Anthropic), lệnh `/code-review` mức `medium`.
- **Phạm vi:** nhánh `main` không có thay đổi chưa commit, nên công cụ rà nguyên 10 file được chỉ định. Đây không phải review một pull request; lý do ghi ở `docs/code-review.md`.
  - `prm393_lab03/lib/models/item_suggestion.dart`
  - `prm393_lab03/lib/screens/onboarding_screen.dart`
  - `prm393_lab03/lib/viewmodels/reflection_viewmodel.dart`
  - `prm393_lab03/lib/services/reflection_service.dart`
  - `prm393_lab03/lib/screens/monthly_reflection_screen.dart`
  - `prm393_lab03/lib/widgets/voucher_suggestion_card.dart`
  - `prm393_lab03/lib/screens/sale_screens.dart`
  - `prm393_flutter_admin/lib/screens/admin_main_layout.dart`
  - `prm393_flutter_admin/lib/screens/dashboard_screen.dart`
  - `prm393_flutter_admin/lib/services/admin_service.dart`
- **Commit được rà:** `28fbf4d`. Số dòng bên dưới là số dòng ở commit này.
- Phần dưới chép nguyên văn kết quả công cụ trả về (JSON, rồi phần ghi chú cuối), không sửa nội dung.

```json
[
  {
    "file": "prm393_flutter_admin/lib/services/admin_service.dart",
    "line": 313,
    "summary": "sendBroadcast always attaches `_preselectedUser?.uid` as targetUserId, whatever the targetAudience, so an 'all' broadcast carries a stale single-user target.",
    "failure_scenario": "Admin clicks 'push to this user' on the Users tab (sets _preselectedUser), then goes to Promotions and uses sendVoucherPushDirect / sendSaleEventPushDirect, or changes the audience to 'all' on the Push tab. The request body is targetAudience:'all' plus targetUserId:<that uid>, so the backend may deliver only to that user while the history row says 'all'. The call also clears _preselectedUser, silently dropping the pending specific-user draft."
  },
  {
    "file": "prm393_lab03/lib/screens/monthly_reflection_screen.dart",
    "line": 39,
    "summary": "'Bỏ thay đổi' pops the screen but never resets the unsaved rating in the app-scoped ReflectionViewModel (`_rating` is only cleared in `_subscribe`).",
    "failure_scenario": "Saved rating is 5. User taps 3, presses back and confirms 'Bỏ thay đổi'. On reopening, chip 3 is still selected (the discarded value), and hasChanges is true immediately (rating 3 != saved 5), so pressing back without touching anything shows the discard dialog again. Tapping 'Lưu' persists the rating the user discarded."
  },
  {
    "file": "prm393_lab03/lib/widgets/voucher_suggestion_card.dart",
    "line": 149,
    "summary": "The 'Đủ điều kiện' badge is rendered unconditionally, including in the nextTargetVoucher branch where no voucher applies; an unknown price is also treated as 0.",
    "failure_scenario": "Item priced 100.000 ₫ with the cheapest voucher at minOrder 250.000 ₫: the header shows the green 'Đủ điều kiện' badge while the body says 'cần thêm 150.000 ₫ để đạt mức đơn tối thiểu'. With latestPriceVnd == null (line 45 uses `?? 0`), the card says the user needs to add the full minOrder for an item whose price is simply unknown."
  },
  {
    "file": "prm393_lab03/lib/widgets/voucher_suggestion_card.dart",
    "line": 48,
    "summary": "Voucher selection never checks validUntil (neither here nor in Voucher.canApplyTo), so expired vouchers are offered as the best code; non-Lazada items also default to 'Shopee'.",
    "failure_scenario": "VoucherService.defaultVouchers expire 2026-11-12 to 2026-11-20. After those dates, or for any Firestore voucher left isActive, the card still shows 'Giảm 50.000 ₫ … Hạn đến 2026-11-12' with a 'Lưu mã' button for a dead code. A Tiki or TikTok Shop item gets Shopee vouchers because _detectPlatform returns 'Shopee' for everything that is not Lazada."
  },
  {
    "file": "prm393_flutter_admin/lib/services/admin_service.dart",
    "line": 461,
    "summary": "fetchFirebaseData assigns live results and starts the crashes listener after its awaits without re-checking `_isLiveFirebase`, so it races with toggleLiveFirebase.",
    "failure_scenario": "Admin toggles Live on (a slow fetch of every user's purchases and wishlist starts), then toggles back to Demo before it finishes. The else-branch restores mock data, then the in-flight fetch completes and overwrites _users, _metrics and _vouchers with live data and subscribes to the crashes stream. The header says 'Nguồn: Dữ liệu Demo' while real user data is shown. Toggling on, off, on runs two fetches whose results interleave."
  },
  {
    "file": "prm393_flutter_admin/lib/services/admin_service.dart",
    "line": 124,
    "summary": "addVoucher de-duplicates by code only in the local list; the Firestore doc with the old id is never deleted, so duplicates come back on the next fetch.",
    "failure_scenario": "In Live mode, autoGenerateSampleShopeePromotions (line 253) builds ids from the current timestamp with fixed codes SHOPEE50K, FREESHIPEXTRA and TECH100K. Each click writes 3 new docs; the local list shows 3, but the `vouchers` collection accumulates 3 per click. After refresh the admin (and the mobile app reading the collection) sees the same codes several times. Write failures are only debugPrinted, so the UI shows a voucher that was never saved."
  },
  {
    "file": "prm393_flutter_admin/lib/services/admin_service.dart",
    "line": 105,
    "summary": "resolveCrash wraps an un-awaited Firestore `update()` in a synchronous try/catch, so failures are never caught and local state is marked resolved anyway.",
    "failure_scenario": "The update is rejected (permission-denied, offline, doc missing because the row is a mock crash still listed in Live mode). The Future fails outside the try block as an unhandled async error, while the UI has already flipped the crash to resolved and decremented activeCrashesCount. The next snapshot or refresh resurrects the crash with no error shown to the admin."
  },
  {
    "file": "prm393_flutter_admin/lib/services/admin_service.dart",
    "line": 480,
    "summary": "Live mode only replaces `_vouchers` when the Firestore collection is non-empty (and `_crashes` only inside the listener), so mock rows stay visible and editable as if they were live.",
    "failure_scenario": "Live mode with an empty `vouchers` collection, or after deleting the last live voucher and refreshing: MockAdminData.defaultVouchers stay on screen under 'Nguồn: Firebase Live'. toggleVoucherActive on one calls `.update()` on a non-existent doc, which fails with not-found and is swallowed. If the crashes read is denied, mock crashes remain listed and the sidebar badge counts them while metrics show 0 active crashes."
  },
  {
    "file": "prm393_flutter_admin/lib/screens/admin_main_layout.dart",
    "line": 19,
    "summary": "AdminMainLayout and AdminService are an unwired legacy stack: nothing references AdminMainLayout, AdminService is never provided, and the layout mixes in screens from the new MVVM stack.",
    "failure_scenario": "admin_app.dart routes to AdminShell and registers no AdminService, so mounting AdminMainLayout throws ProviderNotFoundException at `context.watch<AdminService>()`. Its IndexedStack eagerly builds DashboardScreen, UsersScreen and AiAssistantScreen, which need DashboardViewModel, UsersViewModel and ShellViewModel instead. Cost: about 1,700 lines (layout, AdminService, push, crash and promotions screens, mock data) duplicating DashboardService, PushService and ShopeeVoucherService, with a hardcoded admin@gmail.com check and a full client-side read of every user's subcollections, to be maintained or deleted."
  },
  {
    "file": "prm393_lab03/lib/screens/onboarding_screen.dart",
    "line": 24,
    "summary": "`_pageCount = 1` with NeverScrollableScrollPhysics makes slides 2 and 3 of the PageView unreachable, leaving about 350 lines of dead UI that is still built.",
    "failure_scenario": "The only button calls _nextPage, which goes straight to _finishOnboarding because _currentPage (0) is not below _pageCount - 1 (0). _buildSecondSlide, _buildThirdSlide, _buildDecisionBadge, _onPageChanged and _currentPage are dead code. The hidden third slide also carries copy the product spec forbids ('Tuần này bạn tiết kiệm được 35%…') and would ship if _pageCount were bumped. Either remove the slides and the PageView, or set _pageCount to 3 and add a page indicator."
  }
]
```

Ghi chú công cụ trả về kèm (nguyên văn):

> There was no diff to review (branch matches `origin/main`, working tree clean apart from an untracked doc), so I reviewed the ten listed files in full. No CLAUDE.md governs these files, so the conventions angle returned nothing. Findings come from reading the code; nothing was run beyond `dart analyze` on the three admin files, which reported no issues.
>
> Candidates cut by the 10-finding cap:
> - **`admin_service.dart:408`**: the legacy fetch reads every user's `purchases` and `wishlistItems` from the browser, two sequential reads per user.
> - **`item_suggestion.dart:10`**: `normalizeTitle` builds a new `RegExp` for every character.
> - **`item_suggestion.dart:32`**: diacritic-stripped single-syllable keywords misclassify titles, e.g. "cây lau nhà" becomes food, "sơn tường" becomes beauty, and a title containing ".com" becomes food.
> - **`monthly_reflection_screen.dart:345`**: `_draftGoals` is effectively dead, since the month cannot change while the screen is open.
