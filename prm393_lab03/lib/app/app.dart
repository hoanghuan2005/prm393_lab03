import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/notification_target.dart';
import '../screens/login_screen.dart';
import '../screens/main_navigation_screen.dart';
import '../services/analytics_service.dart';
import '../services/crashlytics_service.dart';
import '../services/pending_writes.dart';
import '../services/remote_config_service.dart';
import '../services/share_intent_service.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/decision_support_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import '../viewmodels/wishlist_viewmodel.dart';
import '../widgets/states/loading_view.dart';
import 'app_lifecycle_bridge.dart';
import 'routes.dart';

/// Lets code outside the widget tree (a tapped notification) navigate
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Shows SnackBars from outside a screen (FCM message while the app is open)
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Opens the Wishlist filtered to "Cần xem lại" (tapped review reminder)
void openReviewDueList() {
  final context = appNavigatorKey.currentContext;
  if (context == null || context.read<AuthViewModel>().userId == null) return;
  context.read<WishlistViewModel>().setReviewDueFilter(true);
  appNavigatorKey.currentState?.pushNamed(AppRoutes.wishlist);
}

/// Opens AddItemScreen with shared product title & url (from Android Share Sheet)
void openAddItemWithSharedData(SharedItemData data) {
  final context = appNavigatorKey.currentContext;
  if (context == null) return;
  appNavigatorKey.currentState?.pushNamed(
    AppRoutes.wishlistAdd,
    arguments: AddItemArgs(
      initialTitle: data.title,
      initialUrl: data.url,
    ),
  );
}

/// Opens "Ghi khoản mua" (tapped daily reminder, screen 05a)
void openRecordPurchase() {
  final context = appNavigatorKey.currentContext;
  if (context == null || context.read<AuthViewModel>().userId == null) return;
  appNavigatorKey.currentState?.pushNamed(AppRoutes.recordPurchase);
}

/// A notification tapped before the app or the user was ready (app was closed, signed out)
Map<String, dynamic>? _pendingNotification;

/// Opens the screen a tapped push notification points to (FCM custom data `type`).
/// Waits until [MainNavigationScreen] is shown when the user is not signed in yet.
void openFromNotification(Map<String, dynamic> data) {
  final context = appNavigatorKey.currentContext;
  if (context == null || context.read<AuthViewModel>().userId == null) {
    _pendingNotification = data;
    return;
  }
  final target = NotificationRoute.targetFor(
    data,
    saleRemindersEnabled: context
        .read<RemoteConfigService>()
        .saleReminderEnabled,
  );
  switch (target) {
    case NotificationTarget.saleList:
      unawaited(
        context.read<AppAnalyticsService>().logClickSaleReminder(
          NotificationRoute.saleTypeOf(data),
        ),
      );
      final sales = context.read<DecisionSupportViewModel>();
      final sale =
          sales.saleById(data[NotificationRoute.saleIdKey] as String?) ??
          sales.upcomingSales.firstOrNull;
      if (sale != null) {
        appNavigatorKey.currentState?.pushNamed(
          AppRoutes.saleList,
          arguments: SaleArgs(sale),
        );
      } else {
        context.read<WishlistViewModel>().showConsidering();
        appNavigatorKey.currentState?.pushNamed(AppRoutes.wishlist);
      }
    case NotificationTarget.reviewDue:
      openReviewDueList();
    case NotificationTarget.reflection:
      appNavigatorKey.currentState?.pushNamed(AppRoutes.reflection);
    case NotificationTarget.none:
      break;
  }
}

/// Called once the signed-in shell is on screen
void openPendingNotification() {
  final data = _pendingNotification;
  _pendingNotification = null;
  if (data != null) openFromNotification(data);
}

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
        return const MainNavigationScreen();
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
        return const LoginScreen();
    }
  }
}