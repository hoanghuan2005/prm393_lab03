# API dùng chung (phần base)

Danh sách lớp/hàm dùng chung, đúng với code hiện tại. Service có interface thì ViewModel nhận **interface**; bản Firestore được gắn trong `lib/app/providers.dart`. Mọi lỗi Firebase được service đổi thành `AppException` (`lib/core/errors`).

## 1. Services (`lib/services/`)

### Dữ liệu người dùng – Firestore, đường dẫn `users/{uid}/...`

| Interface → bản dùng | Hàm | Mô tả |
|:---|:---|:---|
| `UserService` → `FirestoreUserService` | `Future<void> ensureUserDocument(String uid, {String? displayName, required bool isAnonymous})` | Tạo `users/{uid}` lần đầu, các lần sau chỉ cập nhật tên / cờ khách |
| | `Stream<UserSettings> watchSettings(String uid)` | Cài đặt người dùng (mặc định khi chưa có document) |
| | `Future<void> updateSettings(String uid, UserSettings settings)` | Ghi đè `settings` (merge) |
| `PurchaseService` → `FirestorePurchaseService` | `Stream<List<PurchaseItem>> watchPurchases(String uid, {DateTime? from, DateTime? to})` | Khoản mua mới nhất trước, lọc khoảng thời gian ở server |
| | `Future<void> setSatisfaction(String uid, String purchaseId, int? stars)` | A-16: 1–5 sao, hoặc `null` = "Bỏ qua" |
| | `Future<PurchaseItem> add(String uid, PurchaseItem purchase)` | Thêm, trả về bản có id |
| | `Future<void> update(String uid, PurchaseItem purchase)` | Sửa (giữ `createdAt`) |
| | `Future<void> delete(String uid, String purchaseId)` | Xoá |
| | `Future<String> buyFromWishlist(String uid, WishlistItem item, PurchaseDraft draft)` | Một batch: tạo purchase + đánh dấu món đã mua + decision `buy`; trả id purchase |
| `WishlistService` → `FirestoreWishlistService` | `Stream<List<WishlistItem>> watchItems(String uid)` | Món mới nhất trước |
| | `Future<WishlistItem> add(String uid, {required String title, BuyingMotive? motive, int? priceVnd, String? url, String? note, String? budgetGroupId, int priority, SaveChannel saveChannel, required int coolingOffDays})` | Thêm món; có giá thì tạo kèm 1 priceSnapshot; cooldown trừ động cơ Nhu cầu |
| | `Future<void> update(String uid, WishlistItem item)` | Sửa món |
| | `Future<void> addPrice(String uid, String itemId, int amountVnd)` | Snapshot giá mới + `latestPriceVnd` |
| | `Future<List<PriceSnapshot>> priceHistory(String uid, String itemId)` | Mọi lần ghi giá, mới nhất trước (A-14; S3 so với lần đầu) |
| | `Future<void> setReview(String uid, String itemId, DateTime reviewAt)` | "Chờ": đặt `reviewAt` + decision `wait` |
| | `Future<void> skip(String uid, String itemId)` / `undoSkip(...)` | "Bỏ qua" / hoàn tác + decision `skip` / `undo` |
| | `Future<void> delete(String uid, String itemId)` | Xoá món và các priceSnapshot |
| | `Future<void> clearBuyIntent(String uid, String itemId)` | "Chưa mua": xoá `buyIntentAt` (ý định Mua từ extension), món vẫn Đang cân nhắc |
| `ExtensionSessionService` → `FirestoreExtensionSessionService` | `watchSessions(uid)`, `approve(uid, id)`, `reject(uid, id)`, `revoke(uid, id)` | Liên kết extension Chrome (`extensionSessions`) |
| `BudgetService` → `FirestoreBudgetService` | `Stream<List<BudgetGroup>> watchGroups(String uid)` | Nhóm ngân sách theo `order` |
| | `Future<void> ensureDefaultGroups(String uid)` | Tạo 6 nhóm mặc định khi chưa có nhóm nào |
| | `Stream<MonthlyBudget> watchMonthlyBudget(String uid, String monthKey)` | Hạn mức tháng (rỗng khi chưa có) |
| | `Future<void> setGroupLimit(String uid, String monthKey, String groupId, int? limit)` | Đặt hạn mức; `null` / ≤ 0 = bỏ |
| `ShoppingProfileService` → `FirestoreShoppingProfileService` | `watchOwnedItems(uid)`, `saveOwnedItem(uid, item)`, `deleteOwnedItem(uid, id)`, `watchTags(uid)`, `saveTags(uid, tags)` | Hồ sơ mua sắm (đặc tả 7.2) |
| `ReflectionService` → `FirestoreReflectionService` | `Stream<Reflection?> watch(String uid, String monthKey)` / `Future<void> save(String uid, Reflection r)` | Chiêm nghiệm tháng |
| `DemoDataService` → `FirestoreDemoDataService` | `Future<void> seed(String uid)` / `Future<void> clearAll(String uid)` | Thay dữ liệu bằng bộ demo / xoá mọi dữ liệu (giữ hồ sơ + nhóm) |
| `FirestorePaths` | `purchases(uid)`, `wishlistItem(uid, id)`, `priceSnapshots(uid, itemId)`, `decisions(uid)`, `budgetGroups(uid)`, `budget(uid, monthKey)`, `reflection(uid, monthKey)`, … | Nơi duy nhất viết chuỗi đường dẫn Firestore |
| `guard` / `guardStream` (`service_guard.dart`) | `Future<T> guard<T>(Future<T> Function())`, `Stream<T> guardStream<T>(Stream<T>)` | Bọc lời gọi Firebase, ném `AppException`; `guard` giữ stack trace gốc (`Error.throwWithStackTrace`), `guardStream` chuyển tiếp stack trace của lỗi |

### Khác

| Lớp | Hàm chính | Mô tả |
|:---|:---|:---|
| `AuthService` | `authStateChanges`, `signInWithGoogle()`, `signInWithGithub()`, `signInAnonymously()`, `signOut()`, `displayName` | Firebase Auth + Google Sign-In. Các hàm đăng nhập bọc `guard()`, mọi lỗi ném ra là `AppException` (huỷ đăng nhập: code `sign-in-cancelled`); huỷ chọn tài khoản Google trả `null`; `signInWithGoogle()` ném `UnsupportedError` trên Windows |
| | `Stream<User?> userChanges` | Như `authStateChanges` nhưng phát cả khi liên kết / huỷ liên kết |
| | `Set<String> linkedProviderIds` | `providerId` trong `currentUser.providerData` (`google.com`, `github.com`, …); Khách hoặc chưa đăng nhập → rỗng |
| | `Future<UserCredential?> linkGoogle()`, `Future<UserCredential?> linkGithub()` | Liên kết vào tài khoản đang đăng nhập (web: popup; mobile: `google_sign_in` + `linkWithCredential` / `linkWithProvider`), rồi `reload()`. Huỷ chọn tài khoản Google → `null`; `linkGoogle()` ném `UnsupportedError` trên Windows; lỗi khác là `AppException` (chưa đăng nhập: code `no-current-user`) |
| | `Future<void> unlink(String providerId)` | Huỷ liên kết rồi `reload()`; huỷ Google trên mobile thì đăng xuất `google_sign_in` để lần sau hỏi lại tài khoản. Cách đăng nhập duy nhất → `AuthService.lastProvider` (code `last-provider`, "Phải giữ ít nhất một cách đăng nhập."), không gọi Firebase |
| `AiService` → `FirebaseAiService` | `Future<String> generateJson({required String systemInstruction, required String prompt, required List<String> cardIds})`, `Future<String> generateChoice({required String systemInstruction, required String prompt, required AiChoiceSchema schema})`, `Future<String> generateFields({required String systemInstruction, required String prompt, required List<String> fields})` | Nơi duy nhất gọi `firebase_ai` (Gemini). `generateChoice` chỉ cho model chọn trong các giá trị liệt kê, không viết chữ |
| `AiDecisionService` | `Future<String?> reasonFor(DecisionAssessment)`, `Future<Map<PlanOption, String>> explainPlans(SalePlanResult)` | Một câu lý do cho nhãn Decision Card (AI tính năng 2); 1–2 câu cho mỗi phương án gói mua, một lần gọi cho cả ba (AI tính năng 5). Câu có số lạ hoặc từ cấm bị bỏ |
| `AiSuggestionService` | `Future<String?> suggestGroup(String title, List<BudgetGroup> groups)`, `Future<Set<String>> pickDuplicates(String title, List<DuplicateCandidate> candidates)` | Gợi ý nhóm ngân sách và món có thể trùng; bỏ giá trị lạ, nhớ kết quả theo tên món |
| `AiInsightService` | `InsightReport buildTemplateReport(MonthlySpendingStats)`, `Future<InsightReport> generate(MonthlySpendingStats)` | Câu nhận định Góc nhìn / Chiêm nghiệm; kiểm tra câu AI, rơi về câu mẫu |
| `ReportService` | `Future<Uint8List> generateMonthlyReportPdf({required String userName, required DateTime month, required List<PurchaseItem> purchases, required List<WishlistItem> decidedItems})` | Dựng PDF tháng |
| `ReportShareService` → `PrintingReportShareService` | `Future<bool> sharePdf(Uint8List bytes, String fileName)`, `Future<bool> previewPdf(Uint8List bytes)` | Chia sẻ / xem trước PDF (package `printing`) |
| `AppAnalyticsService` | `logLogin`, `logLogout`, `logSearch`, `logAddToWishlist`, `logViewItemDetail`, `logMakeDecision`, `logPurchaseRecorded`, `logBudgetSet`, `logExportReport`, `logClickSaleReminder`, `setUserId` | Chỉ dùng hằng trong `analytics_events.dart`; xem [`analytics-plan.md`](analytics-plan.md). Mọi hàm tự bắt lỗi (chỉ `debugPrint` ở bản debug), không ném |
| `CrashlyticsService` | `recordHandledError(error, stack, {reason, customKeys})`, `setUserId(uid)`, `setCustomKey`, `screenObserver` | Ghi lỗi; key `screen` theo route |
| `RemoteConfigService` | `coolingOffDays`, `enableAiInsight`, `maxWishlistItems`, `saleReminderEnabled`, `aiInsightModel`, `enableAiSuggestions`, `saleCalendarJson`, `fetchAndActivate()` | Cấu hình từ xa |
| `NotificationService` | `initialize({onNotificationOpened})`, `isPermissionGranted()`, `requestPermissionFromUser()`, `receivedNotifications`, `notificationsStream`, `foregroundMessages`, `saleRemindersEnabled`, `Future<void> reload()`, `Future<void> clearReceived()` | FCM. Tin nhận lúc app đang mở được phát trên `foregroundMessages` (sau khi lưu, trừ tin sale bị ẩn); `AppLifecycleBridge` (`lib/app/`) hiện SnackBar qua `appScaffoldMessengerKey`. Lịch sử thông báo lưu trên máy qua `NotificationHistoryStore` (`SharedPreferencesAsync`, tối đa 50 tin, cả tin nhận lúc app chạy nền); `reload()` đọc lại store, `clearReceived()` xoá store. Tin sale chỉ hiện khi `sale_reminder_enabled` bật (vẫn được lưu). Chạm thông báo gọi `openFromNotification` (`lib/app/app.dart`), mở màn theo custom data `type` (`NotificationRoute`) |
| `PreferencesService` | `getAiInsightEnabled()`, `setAiInsightEnabled(bool)` | Bật/tắt AI trên máy (SharedPreferences) |

## 2. ViewModels (`lib/viewmodels/`)

ViewModel có dữ liệu người dùng nhận uid qua `updateUid(String? uid)` từ ProxyProvider. Mixin dùng chung: `DeferredNotify` (`notifyLater()` cho thay đổi trong `update`), `ErrorReporting` (`messageFor(error, stack, reason:, customKeys:)`: `AppException` có `cause` và lỗi không phải `AppException` được ghi Crashlytics non-fatal, `AppException` không có `cause` (lỗi đã có câu riêng) thì không ghi; có `cause` thì ghi `cause` kèm custom key `error_code`. Không có Crashlytics thì chỉ `debugPrint` ở bản debug, qua `describeError` (kiểu + mã, không in message). `AuthViewModel` cũng dùng mixin này, thêm key `auth_method`).

| ViewModel | Thành phần chính |
|:---|:---|
| `AuthViewModel` | `status`, `userId` (null tới khi xong ensure*), `displayName`, `signInWithGoogle()`, `signInAnonymously()`, `signOut()` |
| `PurchaseViewModel` | `state`, `selectedMonth`, `previousMonth()`, `nextMonth()`, `setSelectedMonth()`, `monthPurchases`, `filteredPurchases`, `monthTotal`/`monthCount`, `weekTotal`/`weekCount`, `timeSlotStats`, `motiveDistribution`, `addPurchase(...)`, `updatePurchase(...)`, `deletePurchase(id)`, `satisfactionDue()`, `rateSatisfaction(purchase, stars)`, `actionError` |
| `WishlistViewModel` | `state`, `allItems`, `filteredItems`, `setSearchQuery`, `setMotiveFilter`, `setStatusFilter`, `consideringCount`, `reviewDueCount`, `setReviewDueFilter`, `coolingOffDays`, `addItem(...)`, `updateDetails(...)`, `updatePrice(...)`, `deleteItem(...)`, `wait(item, reviewAt)`, `skip(item)`, `reconsider(item)`, `setConfirmedDuplicate(item, value)`, `buyIntentItems`, `clearBuyIntent(item)`, `onItemViewed(item)`, `maxShown`/`updateMaxShown` (Remote Config `max_wishlist_items_shown`), `visibleOf(items)`, `showAllItems()`, `showConsidering()`, `actionError` |
| `BudgetViewModel` | `state`, `groups`, `limits`, `limitFor(id)`, `spentByGroup`, `spentFor(id)`, `totalLimit`, `totalSpent`, `limitedSpent` (chỉ các nhóm có hạn mức), `unlimitedSpent`, `progress`, `isExceeded`, `remaining`, `isBudgetLoaded`, `available(id)`, `bufferFor(id)`, `hasEnoughHistory`, `daysLeftInMonth`, `setGroupLimit(id, limit)`, `setGroupLimits(changes)` |
| `ReflectionViewModel` | `state`, `month`, `nextMonth`, `saved`, `rating`, `selectRating(int)`, `save(goal)`, `isSaving` |
| `ReportViewModel` | `status` (`idle`→`generating`→`ready`→`shared` / `error`), `generateAndShare(month)`, `preview(month)`, `fileNameFor(month)` |
| `InsightsViewModel` | `stats`, `report`, `isGenerating`, `fallbackReason`, `userAiEnabled`, `setVisible(bool)`, `refresh()`, `setUserAiEnabled(bool)` |
| `DecisionSupportViewModel` | `assess(item)` → `DecisionAssessment` (nhãn, tín hiệu, câu mẫu), `reasonFor(assessment)` → `DecisionReason`, `loadPriceHistory(item)`, `priceInsightsFor(item)`, `sameGroupItems(item)`, `availableFor(groupId)` (ngân sách **tháng hiện tại**), `upcomingSales`, `nextConfirmedSale`, `consideringItems`, `plan()` → `SalePlanResult`, `explainPlans(result)` → câu AI hoặc câu mẫu cho từng phương án |
| `ShoppingProfileViewModel` | `state`, `ownedItems`, `tags`, `matchesFor(title, budgetGroupId)`, `saveOwnedItem(...)`, `deleteOwnedItem(item)`, `saveTags(...)`, `actionError` |
| `ExtensionLinkViewModel` | `pendingSession` (yêu cầu chờ < 5 phút), `unpromptedPending`, `markPrompted(id)`, `linkedSessions`, `approve(s)`, `reject(s)`, `revoke(s)`, `actionError` |
| `ItemSuggestionViewModel` | `suggestGroup(title, groups)` → `GroupSuggestion?`, `findDuplicates(title, {excludeItemId, budgetGroupId})` → `List<DuplicateMatch>`, `updateSources(purchases, wishlistItems)` |
| `SettingsViewModel` | `settings`, `coolingOffDays` (của người dùng, không có thì Remote Config), `updateSettings`, `seedDemoData()`, `clearAllData()`, `refreshRemoteConfig()`, `notifications` |

## 3. Widgets (`lib/widgets/`)

| Widget / hàm | Chữ ký | Mô tả |
|:---|:---|:---|
| `UiStateBuilder<T>` | `UiStateBuilder({required UiState<T> state, required Widget Function(BuildContext, T) builder, String? loadingMessage, IconData emptyIcon})` | Loading / Empty / Error ("Thử lại") / dữ liệu |
| `LoadingView` · `EmptyView` · `ErrorView` | `LoadingView({message})` · `EmptyView({required title, subtitle, icon, actionTitle, onAction})` · `ErrorView({required message, onRetry, retryTitle})` | Ba trạng thái màn hình |
| `AmountField` | `AmountField({label, hint, initialValue, ValueChanged<int?>? onChanged, bool optional, controller})` | Nhập tiền int VND, tự chèn dấu chấm, hậu tố ₫, nút xoá |
| `ConfirmDialog.show` | `Future<bool> show(context, {required title, required message, confirmLabel, bool isDanger})` | Hộp xác nhận, luôn có "Huỷ" |
| `showUndoSnackBar` | `void showUndoSnackBar(context, String message, VoidCallback onUndo)` | SnackBar 5 giây có "Hoàn tác" |
| `AppBottomSheet.show` | `Future<T?> show<T>(context, {required String title, required Widget child})` | Sheet bo góc 24, thanh kéo, cuộn, tránh bàn phím |
| `SectionCard` | `SectionCard({required title, icon, action, required List<Widget> children})` | Thẻ có tiêu đề + nội dung |
| `MoneyText` | `MoneyText(int? amountVnd, {MoneyTextSize size, color, emptyLabel})` | Hiển thị tiền; null → "Chưa có giá" |
| `PriceChip` | `PriceChip({required int? priceVnd})` | Giá món; null → "Cần giá" |
| `MotiveChip` | `MotiveChip({required motive, isSelected, onSelected, isCompact})` | Chip động cơ, vùng chạm ≥ 48dp khi bấm được |
| `BudgetBar` | `BudgetBar({required int spentVnd, required int limitVnd, String? label})` | Thanh ngân sách trung tính, "Đã vượt …" khi vượt |
| `AppButton` | `AppButton({required title, required onPressed, variant, isLoading, icon, width})` | Nút primary / secondary / danger |
| `AppTextField` | `AppTextField({label, hint, controller, onChanged, validator, keyboardType, …})` | Ô nhập chữ |
| `WishlistCard` · `InsightSourceChip` · `WhyIBuyLogo` | `WishlistCard({required item, required onTap})` · `InsightSourceChip({required fromAi})` · `WhyIBuyLogo({size, color})` | Thẻ món · nhãn AI/Câu mẫu · logo |
| `ExtensionApprovalDialog.ask` · `LinkedDevicesSection` · `BuyIntentSection` | `Future<bool?> ask(context, session)` · `LinkedDevicesSection()` · `BuyIntentSection()` | Hỏi "Cho phép … liên kết?" · "Thiết bị đã liên kết" ở Cá nhân · "Định mua từ máy tính" ở Wishlist |
| `MonthPickerSheet.show` · `BudgetSettingSheet.show` | `Future<DateTime?> show(context, initialDate)` · `Future<void> show(context)` | Chọn tháng · đặt ngân sách tổng |

Xem mẫu trực quan: Profile → "Widget Gallery (debug)" (chỉ bản debug).

## 4. Core (`lib/core/`)

| Thành phần | Mô tả |
|:---|:---|
| `formatVnd(int? amount, {String empty})`, `parseVnd(String)` | "389.000 ₫"; parse trả null khi rỗng hoặc 0 |
| `formatRelativeDateTime`, `formatDate`, `formatTime`, `formatWeekdayDate`, `formatMonthLabel` | "Hôm nay 12:15", "26/10/2026", "Tháng 10/2026", … |
| `monthKey(DateTime)` | "2026-10" |
| `TimeSlot` | Sáng 05–11 · Trưa 11–14 · Chiều 14–18 · Tối 18–05 |
| `Validators.validateTitle / validateAmount / validateOptionalAmount / validateNote` | Validator form, thông điệp tiếng Việt |
| `AppConstants` | `titleMaxLength` 60, `noteMaxLength` 200, `amountMax` 999.999.999 |
| `AppException(code, messageVi, {Object? cause})`, `mapFirebaseError(Object)` | Lỗi có `messageVi`; `cause` là lỗi gốc, chỉ có khi lỗi không nhận ra (code `unknown`, instance mới, không phải `AppException.unknown`) hoặc mã auth/Firestore chưa có câu riêng; `toString()` thêm ` <- cause`. Hằng `signInCancelled` (code `sign-in-cancelled`) dùng chung cho mọi cách đăng nhập bị huỷ. Chỉ service dùng `mapFirebaseError` |
| `describeError(Object?)` (`describe_error.dart`) | Chuỗi kiểu + mã lỗi để `debugPrint`, ví dụ `AppException(unknown) <- FirebaseAuthException(internal-error)`; không bao giờ chứa message (có thể có email). Dùng thay cho `'$e'` khi log lỗi Firebase |
