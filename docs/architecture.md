# Kiến trúc – Why I Buy? (Lab 3)

MVVM + Provider/ChangeNotifier. Phụ thuộc chỉ đi một chiều: Screen → ViewModel → Service → Firebase. API chi tiết: [`base-api.md`](base-api.md) · dữ liệu: [`data-model.md`](data-model.md) · quyết định: [`decisions.md`](decisions.md).

## 1. Cây thư mục `lib/`

```text
lib/
├── main.dart            # ensureInitialized, initializeDateFormatting('vi_VN'), FirebaseSetup.initialize, runApp
├── firebase_options.dart
├── app/                 # app.dart (MaterialApp, AuthGate) · routes.dart (AppRoutes) · providers.dart (AppProviders)
├── core/                # constants · errors (AppException, mapFirebaseError) · formatters (tiền, ngày) · utils (TimeSlot, monthKey) · validators
├── firebase/            # FirebaseSetup, AppCheckSetup, PlatformSupport
├── models/              # PurchaseItem, WishlistItem, PriceSnapshot, Decision, BudgetGroup, MonthlyBudget, Reflection, UserProfile, UiState, …
├── services/            # Interface + bản Firestore/Firebase; firestore_paths.dart; analytics_events.dart
├── viewmodels/          # ChangeNotifier; mixin DeferredNotify, ErrorReporting
├── screens/             # Màn hình (dev/ = Widget Gallery, chỉ debug)
├── theme/               # AppColors, AppTextStyles, AppDimens, AppTheme, MotiveColors
└── widgets/             # Widget dùng chung; states/ = Loading/Empty/Error + UiStateBuilder
```

## 2. Sơ đồ phân tầng

```mermaid
flowchart TD
    subgraph UI["Screens & Widgets"]
        Screens["screens/* · AuthGate"]
        Widgets["widgets/* · UiStateBuilder"]
    end

    subgraph VM["ViewModels (ChangeNotifier)"]
        AuthVM[AuthViewModel]
        PurchaseVM[PurchaseViewModel]
        WishlistVM[WishlistViewModel]
        BudgetVM[BudgetViewModel]
        ReflectionVM[ReflectionViewModel]
        ReportVM[ReportViewModel]
        InsightsVM[InsightsViewModel]
        SettingsVM[SettingsViewModel]
        LinkedVM[LinkedAccountsViewModel]
    end

    subgraph SVC["Services"]
        AuthService
        UserService
        PurchaseService
        WishlistService
        BudgetService
        ReflectionService
        DemoDataService
        AiInsightService --> AiService
        ReportService
        ReportShareService
        AppAnalyticsService
        CrashlyticsService
        RemoteConfigService
        NotificationService
        PreferencesService
    end

    subgraph FB["Firebase / package"]
        Auth[(Authentication)]
        Firestore[(Cloud Firestore)]
        AILogic[(Firebase AI Logic – Gemini)]
        AppCheck[(App Check)]
        Analytics[(Analytics)]
        Crashlytics[(Crashlytics)]
        RC[(Remote Config)]
        FCM[(Cloud Messaging)]
        Printing[[printing / pdf]]
    end

    Screens --> VM
    Widgets --> Screens
    VM --> SVC
    AuthService --> Auth
    UserService & PurchaseService & WishlistService & BudgetService & ReflectionService & DemoDataService --> Firestore
    AiService --> AILogic
    AppCheck -. bảo vệ .-> AILogic
    ReportShareService --> Printing
    AppAnalyticsService --> Analytics
    CrashlyticsService --> Crashlytics
    RemoteConfigService --> RC
    NotificationService --> FCM
```

App Check được kích hoạt trong `FirebaseSetup.initialize` (`AppCheckSetup.activate`) trước khi app chạy; nó bảo vệ lời gọi Firebase AI Logic.

## 3. ViewModel ↔ Service

| ViewModel | Service được inject | Nhận từ ProxyProvider |
|:---|:---|:---|
| `AuthViewModel` | `AuthService`, `UserService`, `BudgetService`, `AppAnalyticsService`, `CrashlyticsService` | – |
| `SettingsViewModel` | `RemoteConfigService`, `CrashlyticsService`, `NotificationService`, `UserService`, `DemoDataService` | uid |
| `WishlistViewModel` | `WishlistService`, `AppAnalyticsService`, `CrashlyticsService` | uid, `coolingOffDays` (Settings) |
| `PurchaseViewModel` | `PurchaseService`, `AppAnalyticsService`, `CrashlyticsService` | uid |
| `BudgetViewModel` | `BudgetService`, `AppAnalyticsService`, `CrashlyticsService` | uid, khoản mua + tháng (Purchase) |
| `ReflectionViewModel` | `ReflectionService`, `CrashlyticsService` | uid, tháng (Purchase) |
| `ReportViewModel` | `ReportService`, `ReportShareService`, `AppAnalyticsService`, `CrashlyticsService` | uid, tên, khoản mua, món (Purchase, Wishlist) |
| `LinkedAccountsViewModel` | `AuthService`, `UserService`, `CrashlyticsService` | uid |
| `InsightsViewModel` | `AiInsightService` (→ `AiService`), `RemoteConfigService`, `PreferencesService`, `CrashlyticsService` | khoản mua, món, tháng (Purchase, Wishlist) |

## 4. Luồng phiên đăng nhập

```mermaid
sequenceDiagram
    participant FA as FirebaseAuth
    participant Auth as AuthViewModel
    participant P as ProxyProviders
    participant VM as Purchase/Wishlist/Budget/…VM

    FA->>Auth: userChanges(user)
    Auth->>Auth: status = loading
    Auth->>Auth: UserService.ensureUserDocument + BudgetService.ensureDefaultGroups (lỗi → Crashlytics, không chặn)
    Auth->>Auth: status = authenticated, userId = uid
    Auth-->>P: notifyListeners
    P->>VM: updateUid(uid)
    VM->>VM: huỷ stream cũ, xoá dữ liệu, UiLoading, đăng ký stream mới
    Note over FA,VM: Đăng xuất: user = null → userId = null → updateUid(null) → UiInitial
```

- `AuthViewModel` nghe `userChanges` (phát cả khi đăng nhập/đăng xuất, liên kết/huỷ liên kết, làm mới token). Sự kiện cùng `uid` chỉ cập nhật `user` / `displayName`; không chạy lại ensure*, `setUserId` và không đổi `userId`, nên `updateUid` của các ViewModel không làm gì.
- `AuthGate` hiện Loading khi `status` là `initial`/`loading`, `MainNavigationScreen` khi `authenticated`, `LoginScreen` khi chưa đăng nhập.
- `update` của ProxyProvider chạy trong lúc build, nên ViewModel thông báo bằng `notifyLater()` (mixin `DeferredNotify`).

## 5. Luồng liên kết tài khoản

```mermaid
sequenceDiagram
    participant UI as Cá nhân · LinkedAccountsSection
    participant LVM as LinkedAccountsViewModel
    participant AS as AuthService
    participant FA as FirebaseAuth
    participant Auth as AuthViewModel
    participant US as UserService

    UI->>LVM: linkGoogle() / linkGithub() / unlink(id)
    LVM->>LVM: dòng đó busy, khoá mọi nút
    LVM->>AS: linkGoogle / linkGithub / unlink (bọc guard())
    AS->>FA: linkWithCredential / linkWithProvider / unlink
    AS->>FA: reload() (lỗi bỏ qua)
    FA-->>LVM: userChanges(user) → dòng linked / notLinked
    FA-->>Auth: userChanges(user) cùng uid → isAnonymous, displayName mới
    LVM->>US: ensureUserDocument(isAnonymous: false) (chỉ sau khi liên kết)
    LVM-->>UI: successMessage / errorMessage → SnackBar
```

- Lỗi ra khỏi `AuthService` luôn là `AppException`; huỷ (`null` hoặc `sign-in-cancelled`) không báo lỗi; lỗi có `cause` ghi Crashlytics kèm `auth_method` (`link_google` · `link_github` · `unlink`).
- `canUnlink` tính trên mọi `providerId` của người dùng (kể cả cách không hiện trên màn), để không bao giờ huỷ cách đăng nhập cuối cùng.
- Lý do và giới hạn: [`decisions.md`](decisions.md) – "Liên kết nhiều cách đăng nhập vào một tài khoản".

## 6. Quy tắc

1. Widget không gọi Firebase SDK, service, analytics hay crashlytics; chỉ đọc ViewModel.
2. Mỗi service có `abstract interface class` + bản Firestore/Firebase, nhận `FirebaseFirestore` qua constructor; lỗi Firebase → `AppException`.
3. ViewModel: `AppException` → `UiError(messageVi, onRetry)`; lỗi khác → Crashlytics + "Đã có lỗi, vui lòng thử lại." (`ErrorReporting`).
4. Điều hướng qua `AppRoutes`; màu/chữ/khoảng cách qua token trong `lib/theme/`.
