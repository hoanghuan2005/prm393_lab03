import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/login_screen.dart';
import '../screens/main_navigation_screen.dart';
import '../services/analytics_service.dart';
import '../services/crashlytics_service.dart';
import '../theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/wishlist_viewmodel.dart';
import '../widgets/states/loading_view.dart';
import 'routes.dart';

/// Lets code outside the widget tree (a tapped notification) navigate
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Opens the Wishlist filtered to "Cần xem lại" (tapped review reminder)
void openReviewDueList() {
  final context = appNavigatorKey.currentContext;
  if (context == null || context.read<AuthViewModel>().userId == null) return;
  context.read<WishlistViewModel>().setReviewDueFilter(true);
  appNavigatorKey.currentState?.pushNamed(AppRoutes.wishlist);
}

class WhyIBuyApp extends StatelessWidget {
  const WhyIBuyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final analyticsService = context.read<AppAnalyticsService>();
    final crashlyticsService = context.read<CrashlyticsService>();

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Why I Buy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorObservers: [
        ...analyticsService.navigatorObservers,
        crashlyticsService.screenObserver,
      ],
      home: const AuthGate(),
      onGenerateRoute: AppRoutes.onGenerateRoute,
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
