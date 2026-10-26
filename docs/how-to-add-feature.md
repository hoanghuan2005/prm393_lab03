# Cách thêm một màn hình / tính năng

Ví dụ xuyên suốt: màn **"Món đang chờ"** liệt kê các món người dùng đã bấm "Chờ" (`WishlistItem.isWaiting`). Tên lớp trong ví dụ (`WaitingListViewModel`, `WaitingListScreen`) là minh hoạ, chưa có trong code.

Quy tắc chung: screen chỉ đọc ViewModel; ViewModel gọi service; chỉ service chạm Firebase. API dùng chung: [`base-api.md`](base-api.md).

---

## Bước 1 – Route trong `AppRoutes`

`lib/app/routes.dart` (file base – nhắn người phụ trách base nếu bạn không được sửa):

```dart
static const waitingList = '/wishlist/waiting';

// trong onGenerateRoute
waitingList => const WaitingListScreen(),
```

Màn cần tham số thì thêm lớp args có kiểu (như `ItemDetailArgs`) và dùng `when args is …`. Mở màn bằng:

```dart
Navigator.pushNamed(context, AppRoutes.waitingList);
```

Không dùng `MaterialPageRoute` trong screen.

## Bước 2 – ViewModel

`lib/viewmodels/waiting_list_viewmodel.dart`. Service nhận qua constructor (kiểu interface), uid nhận qua `updateUid`, lỗi qua `ErrorReporting`, thông báo trong `updateUid` dùng `notifyLater()` vì hàm này chạy lúc build.

```dart
class WaitingListViewModel extends ChangeNotifier
    with DeferredNotify, ErrorReporting {
  final WishlistService wishlistService;
  @override
  final CrashlyticsService? crashlyticsService;

  WaitingListViewModel({required this.wishlistService, this.crashlyticsService});

  StreamSubscription<List<WishlistItem>>? _sub;
  String? _uid;
  UiState<List<WishlistItem>> _state = const UiInitial();
  UiState<List<WishlistItem>> get state => _state;

  void updateUid(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _sub?.cancel();
    if (uid == null) {
      _state = const UiInitial();
      notifyLater();
      return;
    }
    _state = const UiLoading();
    notifyLater();
    _sub = wishlistService.watchItems(uid).listen(
      (items) {
        final waiting = items.where((i) => i.isWaiting).toList();
        _state = waiting.isEmpty
            ? const UiEmpty(message: 'Chưa có món nào đang chờ')
            : UiSuccess(waiting);
        notifyListeners();
      },
      onError: (Object e, StackTrace s) {
        _state = UiError(
          message: messageFor(e, s, reason: 'watchWaiting'),
          onRetry: () {
            _uid = null;
            updateUid(uid);
          },
        );
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
```

## Bước 3 – Đăng ký ProxyProvider

`lib/app/providers.dart` (file base): ViewModel nhận uid từ `AuthViewModel`, widget không bao giờ tự gán uid.

```dart
ChangeNotifierProxyProvider<AuthViewModel, WaitingListViewModel>(
  create: (context) => WaitingListViewModel(
    wishlistService: context.read<WishlistService>(),
    crashlyticsService: crashlyticsService,
  ),
  update: (_, auth, vm) => vm!..updateUid(auth.userId),
),
```

## Bước 4 – Screen dùng `UiStateBuilder` và widget chung

```dart
class WaitingListScreen extends StatelessWidget {
  const WaitingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WaitingListViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Món đang chờ')),
      body: UiStateBuilder<List<WishlistItem>>(
        state: vm.state,
        builder: (context, items) => ListView(
          padding: const EdgeInsets.all(AppDimens.space16),
          children: [
            for (final item in items)
              SectionCard(
                title: item.title,
                children: [
                  PriceChip(priceVnd: item.latestPriceVnd),
                  Text('Còn ${item.daysUntilReview} ngày', style: AppTextStyles.bodyMedium),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
```

- Màu, chữ, khoảng cách chỉ lấy từ `lib/theme/` (`AppColors`, `AppTextStyles`, `AppDimens`).
- Tiền: `MoneyText` / `formatVnd`; nhập tiền: `AmountField`.
- Hỏi xác nhận: `ConfirmDialog.show`; hoàn tác: `showUndoSnackBar`; sheet: `AppBottomSheet.show`.
- Câu chữ tiếng Việt trung tính (không khen/chê, không "tiết kiệm").

## Bước 5 – Analytics (nếu cần)

Chỉ gọi từ ViewModel, qua `AppAnalyticsService`. Event mới thì thêm hằng vào `lib/services/analytics_events.dart`, thêm hàm vào `AppAnalyticsService`, rồi cập nhật bảng trong [`analytics-plan.md`](analytics-plan.md). Không gửi tên món, email, số tiền chính xác (dùng `AmountBucket`).

```dart
unawaited(analyticsService.logViewItemDetail(motive: item.displayMotive.key, daysInCooldown: item.daysSinceCreated));
```

## Bước 6 – Chạy thử và kiểm tra trên máy

Không có CI, nên các bước này là bắt buộc (checklist đầy đủ trong [`CONTRIBUTING.md`](../CONTRIBUTING.md)):

1. Chạy app (`flutter run`) và đi qua màn mới: có dữ liệu, rỗng, mất mạng (lỗi + "Thử lại").
2. `dart format lib`
3. `flutter analyze` → `No issues found!`
4. Ghi nhật ký AI vào `docs/ai-log.md` nếu có dùng AI.

## Bước 7 – Commit và push

```bash
git pull --rebase
git add <file của bạn>
git commit -m "feat: màn Món đang chờ"
git pull --rebase
git push
```
