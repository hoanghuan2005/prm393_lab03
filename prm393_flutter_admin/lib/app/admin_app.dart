import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import '../screens/admin_shell.dart';
import '../screens/sign_in_screen.dart';
import '../services/admin_auth_service.dart';
import '../services/dashboard_service.dart';
import '../services/push_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'admin_theme.dart';

/// Services are injected here (Provider) so every ViewModel can be tested with fakes.
class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AdminAuthService>(create: (_) => FirebaseAdminAuthService()),
        Provider<RoleService>(create: (_) => FirestoreRoleService()),
        Provider<DashboardService>(create: (_) => FirestoreDashboardService()),
        Provider<SaleEventService>(create: (_) => FirestoreSaleEventService()),
        Provider<SaleSuggestionService>(
          create: (_) => FirestoreSaleSuggestionService(),
        ),
        Provider<AnnouncementService>(
          create: (_) => FirestoreAnnouncementService(),
        ),
        Provider<PushService>(
          create: (c) => HttpPushService(c.read<AdminAuthService>()),
        ),
        ChangeNotifierProvider(
          create: (c) =>
              AuthViewModel(c.read<AdminAuthService>(), c.read<RoleService>()),
        ),
      ],
      child: MaterialApp(
        title: 'Why I Buy · Quản trị',
        debugShowCheckedModeBanner: false,
        theme: buildAdminTheme(),
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const AuthGate(),
      ),
    );
  }
}

/// Signed out → sign-in screen; signed in with role admin → admin pages.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthViewModel>().state;
    return switch (state) {
      AuthChecking() => const Scaffold(
        body: LoadingView(message: 'Đang kiểm tra quyền truy cập…'),
      ),
      AuthSignedOut() => const SignInScreen(),
      AuthAdmin(:final account) => AdminShell(
        key: ValueKey(account.uid),
        account: account,
      ),
    };
  }
}
