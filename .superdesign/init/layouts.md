# Layouts

UI stack: Flutter (Dart), Material 3, Provider, MVVM. There is no React/Vue frontend in this repo.

- PRIMARY: mobile app `prm393_lab03/` ("Why I Buy"). Font Be Vietnam Pro, primary `#FFDE02`, light scaffold `#F8FAFC`.
- SECONDARY: web admin `prm393_flutter_admin/` (shell summarised at the end), sharing theme + basic widgets from `packages/core/lib/src`.
- `presentation_web/` is a fresh Vite scaffold with no UI yet.

Layout hierarchy of the mobile app:

```
MaterialApp (WhyIBuyApp, lib/app/app.dart)
└─ builder: _PendingWritesFrame      offline banner above every route
   └─ Navigator
      ├─ home: AuthGate              loading / login / email verify / shell
      │  └─ MainNavigationScreen     5-tab shell, IndexedStack + custom bottom bar
      │     ├─ HomeScreen            Trang chủ
      │     ├─ HistoryScreen         Lịch sử
      │     ├─ PatternsScreen        Mô hình
      │     ├─ InsightsScreen        Góc nhìn
      │     └─ ProfileScreen         Cá nhân
      └─ pushed routes (AppRoutes.onGenerateRoute) as full-screen MaterialPageRoute
```

Each tab screen owns its own `Scaffold` + `AppBar` (back chevron, Why I Buy logo, title, `AppHeaderActions` on the right); the shell only owns the bottom bar.

## App shell: `prm393_lab03/lib/screens/main_navigation_screen.dart`

What it renders:
- `PopScope` so Android back on any tab other than Trang chủ returns to tab 0 instead of closing the app.
- `Scaffold` whose `body` is an `IndexedStack` of the 5 tab screens (state of every tab is kept).
- A custom bottom bar (not the Material `NavigationBar` widget): a 60 px high `Row` of 5 `Expanded` `InkWell` items inside `SafeArea`, surface background, 1 px top border in `theme.dividerColor`.
- Each item: 24 px icon (outlined when inactive, filled when active) over an 11 px label (w700 active, w500 inactive). Active colour is `AppColors.onPrimary` in light mode and `AppColors.primary` (yellow) in dark mode; inactive is `AppColors.navInactive` (light) or `#64748B` (dark). No pill/indicator behind the active item.
- Tabs: 0 Trang chủ (`home`), 1 Lịch sử (`format_list_bulleted`), 2 Mô hình (`bar_chart`), 3 Góc nhìn (`lightbulb`), 4 Cá nhân (`person`).
- Non-visual: shows `SatisfactionDialog` / `ExtensionApprovalDialog` once while the shell is the current route, and routes launches from reminders, share intents and push notifications.

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app.dart';
import '../services/review_reminder_service.dart';
import '../services/share_intent_service.dart';
import '../theme/app_colors.dart';
import '../viewmodels/extension_link_viewmodel.dart';
import '../viewmodels/insights_viewmodel.dart';
import '../viewmodels/purchase_viewmodel.dart';
import '../widgets/extension_approval_dialog.dart';
import '../widgets/satisfaction_dialog.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'insights_screen.dart';
import 'patterns_screen.dart';
import 'profile_screen.dart';

/// Main Shell with 5 Tabs matching Figma "Why I Buy ver2"
class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  late final PurchaseViewModel _purchaseVm = context.read<PurchaseViewModel>();
  late final ExtensionLinkViewModel _extensionVm = context
      .read<ExtensionLinkViewModel>();

  /// A-16: at most one satisfaction question per app session
  bool _askedSatisfaction = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _purchaseVm.addListener(_onPurchasesChanged);
    _extensionVm.addListener(_onExtensionSessionsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onPurchasesChanged();
      _onExtensionSessionsChanged();
      context.read<InsightsViewModel>().setVisible(
        _currentIndex == _insightsTabIndex,
      );
      // App was started by tapping a review reminder or the daily reminder
      final reminders = context.read<ReviewReminderService>();
      if (reminders.consumeLaunchedFromReminder()) {
        openReviewDueList();
      } else if (reminders.consumeLaunchedFromDailyReminder()) {
        openRecordPurchase();
      }
      // App was started by sharing text/link from another app (Shopee, Lazada, Browser...)
      final initialShareData = context
          .read<ShareIntentService>()
          .consumeInitialData();
      if (initialShareData != null) {
        openAddItemWithSharedData(initialShareData);
      }
      // App opened by tapping a push notification, or tapped while signed out
      openPendingNotification();
    });
  }

  /// Purchases arrive from Firestore after the shell is shown; ask once one is due,
  /// and only while the shell itself is on screen (never over a form)
  void _onPurchasesChanged() {
    if (_askedSatisfaction) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _askedSatisfaction) return;
      if (ModalRoute.of(context)?.isCurrent != true) return;
      final due = _purchaseVm.satisfactionDue();
      if (due == null) return;
      _askedSatisfaction = true;
      SatisfactionDialog.ask(context, due);
    });
  }

  /// A Chrome extension asks to link: ask once per request, only while the shell is on screen
  void _onExtensionSessionsChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      final pending = _extensionVm.unpromptedPending;
      if (pending == null) return;
      _extensionVm.markPrompted(pending.id);
      final approved = await ExtensionApprovalDialog.ask(context, pending);
      if (approved == null || !mounted) return;
      final ok = approved
          ? await _extensionVm.approve(pending)
          : await _extensionVm.reject(pending);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !ok
                ? _extensionVm.actionError ?? 'Đã có lỗi, vui lòng thử lại.'
                : approved
                ? 'Đã liên kết ${pending.deviceLabel}.'
                : 'Đã từ chối ${pending.deviceLabel}.',
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _purchaseVm.removeListener(_onPurchasesChanged);
    _extensionVm.removeListener(_onExtensionSessionsChanged);
    super.dispose();
  }

  static const int _insightsTabIndex = 3;

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
    // AI wording is only requested while Góc nhìn is on screen
    context.read<InsightsViewModel>().setVisible(index == _insightsTabIndex);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screens = [
      HomeScreen(onNavigateTab: _navigateToTab),
      HistoryScreen(
        onProfileTap: () => _navigateToTab(4),
        onBackTap: () => _navigateToTab(0),
      ),
      PatternsScreen(
        onProfileTap: () => _navigateToTab(4),
        onBackTap: () => _navigateToTab(0),
      ),
      InsightsScreen(
        onProfileTap: () => _navigateToTab(4),
        onBackTap: () => _navigateToTab(0),
      ),
      ProfileScreen(onBackTap: () => _navigateToTab(0)),
    ];

    // Android back on another tab returns to Trang chủ instead of closing the app
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _navigateToTab(0);
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: screens),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(color: theme.dividerColor, width: 1),
            ),
          ),
          child: SafeArea(
            child: SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    context: context,
                    index: 0,
                    label: 'Trang chủ',
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 1,
                    label: 'Lịch sử',
                    icon: Icons.format_list_bulleted_rounded,
                    activeIcon: Icons.format_list_bulleted_rounded,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 2,
                    label: 'Mô hình',
                    icon: Icons.bar_chart_rounded,
                    activeIcon: Icons.bar_chart_rounded,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 3,
                    label: 'Góc nhìn',
                    icon: Icons.lightbulb_outline_rounded,
                    activeIcon: Icons.lightbulb_rounded,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 4,
                    label: 'Cá nhân',
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _currentIndex == index;

    final selectedColor = isDark ? AppColors.primary : AppColors.onPrimary;
    final unselectedColor = isDark
        ? const Color(0xFF64748B)
        : AppColors.navInactive;

    return Expanded(
      child: InkWell(
        onTap: () => _navigateToTab(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 24,
              color: isSelected ? selectedColor : unselectedColor,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? selectedColor : unselectedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Header actions: `prm393_lab03/lib/widgets/app_header_actions.dart`

What it renders: the right side of every tab `AppBar` (`actions: [AppHeaderActions(onProfileTap: ...)]` in Home, History, Patterns, Insights).
- Bell `IconButton` (outlined when there are no notifications, filled otherwise) with a red circular count badge (`AppColors.error`, white 10 px bold text). Tapping opens a modal bottom sheet with drag handle: "Thông báo" title (20 px w800), up to 5 `ListTile`s with a yellow-container `CircleAvatar`, or an empty line "Chưa có thông báo mới.", plus an optional "Bật thông báo" text button.
- Bookmark `IconButton` with the same red count badge (wishlist items being considered); pushes `AppRoutes.wishlist`.
- 34 px yellow (`AppColors.primary`) circular avatar with a person icon in `AppColors.onPrimary`; calls `onProfileTap` (jumps to the Cá nhân tab).
- Icon colour: `AppColors.onPrimary` in light mode, `AppColors.primary` in dark mode.

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app.dart';
import '../app/routes.dart';
import '../theme/app_colors.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../viewmodels/wishlist_viewmodel.dart';

class AppHeaderActions extends StatelessWidget {
  final VoidCallback? onProfileTap;

  const AppHeaderActions({super.key, this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Always provided in the app; a screen tested on its own may leave them out
    final settingsVm = context.watch<SettingsViewModel?>();
    final wishlistVm = context.watch<WishlistViewModel?>();
    final iconColor = isDark ? AppColors.primary : AppColors.onPrimary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (settingsVm != null)
          _NotificationButton(color: iconColor, settingsVm: settingsVm),
        if (wishlistVm != null)
          _WishlistButton(
            color: iconColor,
            count: wishlistVm.consideringCount,
            onPressed: () => Navigator.pushNamed(context, AppRoutes.wishlist),
          ),
        Padding(
          padding: const EdgeInsets.only(right: 12, left: 2),
          child: InkWell(
            onTap: onProfileTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: AppColors.onPrimary,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final Color color;
  final SettingsViewModel settingsVm;

  const _NotificationButton({required this.color, required this.settingsVm});

  @override
  Widget build(BuildContext context) {
    final count = settingsVm.notifications.length;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(
            count == 0
                ? Icons.notifications_none_rounded
                : Icons.notifications_rounded,
            color: color,
            size: 24,
          ),
          tooltip: 'Thông báo',
          onPressed: () => _showNotifications(context),
        ),
        if (count > 0)
          Positioned(
            right: 7,
            top: 7,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thông báo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (settingsVm.notifications.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('Chưa có thông báo mới.')),
                )
              else
                ...settingsVm.notifications
                    .take(5)
                    .map(
                      (notification) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.primaryContainer,
                          child: Icon(
                            Icons.notifications_active_outlined,
                            color: AppColors.onPrimary,
                          ),
                        ),
                        title: Text(
                          notification.title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(notification.body),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          openFromNotification(notification.data);
                        },
                      ),
                    ),
              if (settingsVm.asksNotificationPermissionInApp &&
                  !settingsVm.notificationsEnabled)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      await settingsVm.enableNotifications();
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                    icon: const Icon(Icons.notifications_outlined),
                    label: const Text('Bật thông báo'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WishlistButton extends StatelessWidget {
  final Color color;
  final int count;
  final VoidCallback onPressed;

  const _WishlistButton({
    required this.color,
    required this.count,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(Icons.bookmark_outline_rounded, color: color, size: 24),
          tooltip: 'Danh sách mong muốn',
          onPressed: onPressed,
        ),
        if (count > 0)
          Positioned(
            right: 7,
            top: 7,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
```

### Tab screen AppBar pattern (shared by the 4 tab screens)

Excerpt from `prm393_lab03/lib/screens/history_screen.dart` `build()`; Home, Patterns and Insights use the same structure with their own title.

```dart

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leadingWidth: 42,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.chevron_left_rounded, size: 30),
          tooltip: 'Trang chủ',
          onPressed: onBackTap,
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            const WhyIBuyLogo(size: 26, color: AppColors.onPrimary),
            const SizedBox(width: 4),
            Text(
              'Lịch sử',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [AppHeaderActions(onProfileTap: onProfileTap)],
```

## App root and theme wiring: `prm393_lab03/lib/app/app.dart`

Render-relevant part only (the top of the file holds `appNavigatorKey`, `appScaffoldMessengerKey` and the non-visual `openReviewDueList` / `openAddItemWithSharedData` / `openRecordPurchase` / `openFromNotification` helpers).

What it renders:
- `WhyIBuyApp`: `MaterialApp` titled "Why I Buy" with `AppTheme.lightTheme` / `AppTheme.darkTheme` and `themeMode` from `ThemeViewModel`, `home: AuthGate`, named routes from `AppRoutes.onGenerateRoute`, wrapped in `AppLifecycleBridge`.
- `_PendingWritesFrame` (MaterialApp `builder`): when offline writes are queued, a full-width strip in `surfaceContainerHighest` with a cloud-off icon and "Đang chờ mạng · N thay đổi đã lưu trên máy, sẽ tự đồng bộ khi có mạng." sits above every route.
- `AuthGate`: full-screen `LoadingView` while checking the session, `EmailVerificationScreen`, `LoginScreen`, or the authenticated shell (`MainNavigationScreen`).

```dart
class WhyIBuyApp extends StatelessWidget {
  const WhyIBuyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final analyticsService = context.read<AppAnalyticsService>();
    final crashlyticsService = context.read<CrashlyticsService>();
    final themeVm = context.watch<ThemeViewModel>();

    return AppLifecycleBridge(
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        scaffoldMessengerKey: appScaffoldMessengerKey,
        title: 'Why I Buy',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeVm.themeMode,
        navigatorObservers: [
          ...analyticsService.navigatorObservers,
          crashlyticsService.screenObserver,
        ],
        home: const AuthGate(),
        onGenerateRoute: AppRoutes.onGenerateRoute,
        builder: (context, child) => _PendingWritesFrame(child: child!),
      ),
    );
  }
}

/// Shows "đang chờ mạng" above every screen while offline writes wait to sync (E04).
/// The tree around [child] (the Navigator) never changes shape, so toggling the banner
/// cannot rebuild the Navigator and lose the open screens.
class _PendingWritesFrame extends StatelessWidget {
  final Widget child;

  const _PendingWritesFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PendingWrites.instance,
      builder: (context, _) {
        final count = PendingWrites.instance.count;
        final theme = Theme.of(context);
        return Column(
          children: [
            // Always two children, so the Navigator below keeps its element
            if (count == 0)
              const SizedBox.shrink()
            else
              Material(
                color: theme.colorScheme.surfaceContainerHighest,
                child: SafeArea(
                  bottom: false,
                  child: Semantics(
                    liveRegion: true,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.space16,
                        vertical: AppDimens.space8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cloud_off_outlined,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppDimens.space8),
                          Expanded(
                            child: Text(
                              'Đang chờ mạng · $count thay đổi đã lưu trên máy, '
                              'sẽ tự đồng bộ khi có mạng.',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: count > 0,
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Authentication State Router Gate
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    switch (authVm.status) {
      case AuthStatus.initial:
      case AuthStatus.loading:
        return const Scaffold(
          body: LoadingView(
            message: 'Đang kiểm tra trạng thái phiên đăng nhập...',
          ),
        );
      case AuthStatus.authenticated:
        if (authVm.requiresEmailVerification) {
          return const EmailVerificationScreen();
        }
        return const _AuthenticatedHome();
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
        return const LoginScreen();
    }
  }
}

class _AuthenticatedHome extends StatefulWidget {
  const _AuthenticatedHome();

  @override
  State<_AuthenticatedHome> createState() => _AuthenticatedHomeState();
}

class _AuthenticatedHomeState extends State<_AuthenticatedHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final service = context.read<ShareIntentService>();
      final pending = <SharedItemData>[..._pendingSharedData];
      _pendingSharedData.clear();
      final initial = service.consumeInitialData();
      if (initial != null) pending.add(initial);
      for (final data in pending) {
        openAddItemWithSharedData(data);
      }
    });
  }

  @override
  Widget build(BuildContext context) => const MainNavigationScreen();
}
```

## Web admin shell (secondary): `prm393_flutter_admin/lib/screens/admin_shell.dart`

Six sections from `AdminSection` (`prm393_flutter_admin/lib/viewmodels/shell_viewmodel.dart`): Tổng quan, Người dùng, Sự kiện sale, Duyệt đề xuất (badge with pending count), Thông báo, Trợ lý AI. Content is a `Column` of `_TopBar` (compact below 900 px) over an `IndexedStack` of the section pages. Navigation by width:
- `< 720` px: Material `NavigationBar` at the bottom (label only on the selected item).
- `720` to `< 1100` px: `NavigationRail` with all labels and the `BrandMark` as leading, then a 1 px `VerticalDivider`.
- `>= 1100` px: custom 264 px `_Sidebar`, then a 1 px `VerticalDivider`.

`_ShellBody.build()`:

```dart
  @override
  Widget build(BuildContext context) {
    final shell = context.watch<ShellViewModel>();
    final pending = context.select<ReviewQueueViewModel, int>(
      (vm) => vm.pendingCount,
    );
    final width = MediaQuery.sizeOf(context).width;
    final sections = AdminSection.values;
    final index = sections.indexOf(shell.section);

    final pages = IndexedStack(
      index: index,
      children: [for (final s in sections) _pages[s]!],
    );
    final content = Column(
      children: [
        _TopBar(
          account: account,
          role: role,
          compact: width < 900,
          onSignOut: () => _signOut(context),
        ),
        Expanded(child: pages),
      ],
    );

    Widget icon(AdminSection s, {required bool selected}) {
      final i = Icon(selected ? s.selectedIcon : s.icon);
      if (s != AdminSection.reviews || pending == 0) return i;
      return Badge(label: Text('$pending'), child: i);
    }

    if (width < 720) {
      return Scaffold(
        body: SafeArea(child: content),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          onDestinationSelected: (i) => _select(context, sections[i]),
          destinations: [
            for (final s in sections)
              NavigationDestination(
                icon: icon(s, selected: false),
                selectedIcon: icon(s, selected: true),
                label: s.label,
              ),
          ],
        ),
      );
    }

    final navigation = width >= 1100
        ? _Sidebar(
            selected: shell.section,
            pending: pending,
            onSelect: (s) => _select(context, s),
          )
        : NavigationRail(
            selectedIndex: index,
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: (i) => _select(context, sections[i]),
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimens.space16),
              child: BrandMark(),
            ),
            destinations: [
              for (final s in sections)
                NavigationRailDestination(
                  icon: icon(s, selected: false),
                  selectedIcon: icon(s, selected: true),
                  label: Text(s.label),
                ),
            ],
          );

    return Scaffold(
      body: Row(
        children: [
          navigation,
          const VerticalDivider(width: 1),
          Expanded(child: content),
        ],
      ),
    );
  }
}
```
