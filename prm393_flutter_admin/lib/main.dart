import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/admin_service.dart';
import 'theme/admin_colors.dart';
import 'screens/admin_main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.web,
    );
  } catch (e) {
    debugPrint('Firebase init web fallback: $e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AdminService(),
      child: const AdminAuthGate(),
    ),
  );
}

class AdminAuthGate extends StatelessWidget {
  const AdminAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.expand(
            child: ColoredBox(
              color: Color(0xFF020617),
              child: Center(child: CircularProgressIndicator(color: AdminColors.primary)),
            ),
          );
        }
        final user = snapshot.data;
        if (user == null) return const AdminLoginScreen();
        if (user.email != AdminService.adminEmail) {
          FirebaseAuth.instance.signOut();
          return const AdminLoginScreen(
            error: 'Tài khoản này không có quyền Admin.',
          );
        }
        return const WhyIBuyAdminApp();
      },
    );
  }
}

class AdminLoginScreen extends StatefulWidget {
  final String? error;

  const AdminLoginScreen({super.key, this.error});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  static const _defaultEmail = 'admin@gmail.com';
  static const _defaultPassword = '123456';
  final _emailController = TextEditingController(text: _defaultEmail);
  final _passwordController = TextEditingController(text: _defaultPassword);
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_passwordController.text.length < 6) {
      setState(() => _error = 'Mật khẩu tối thiểu 6 ký tự');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final auth = FirebaseAuth.instance;
      try {
        await auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code != 'user-not-found') rethrow;
        await auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = switch (e.code) {
          'invalid-credential' || 'wrong-password' => 'Email hoặc mật khẩu không đúng.',
          'email-already-in-use' => 'Email này đã được đăng ký.',
          'operation-not-allowed' => 'Firebase chưa bật đăng nhập bằng Email/Mật khẩu.',
          'weak-password' => 'Mật khẩu phải có ít nhất 6 ký tự.',
          _ => e.message ?? e.code,
        };
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error ?? widget.error;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AdminColors.primary,
          brightness: Brightness.light,
        ),
      ),
      home: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF111827), Color(0xFFF8FAFC)],
            ),
          ),
          child: Center(
            child: LayoutBuilder(
              builder: (context, viewport) {
                final contentWidth = viewport.maxWidth > 980 ? 980.0 : viewport.maxWidth;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: SizedBox(
                    width: contentWidth,
                    child: Card(
                  elevation: 24,
                  shadowColor: Colors.black.withValues(alpha: 0.35),
                  color: const Color(0xFFF8FAFC),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  clipBehavior: Clip.antiAlias,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 720;
                      final form = Padding(
                        padding: EdgeInsets.all(isCompact ? 28 : 54),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Đăng nhập',
                            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Truy cập vào không gian quản trị của bạn',
                            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 32),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDecoration(Icons.email_outlined, 'Email quản trị'),
                            validator: (value) => value == null || !value.contains('@') ? 'Nhập email hợp lệ' : null,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword == true,
                            decoration: _inputDecoration(
                              Icons.lock_outline_rounded,
                              'Mật khẩu',
                              suffix: IconButton(
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                              ),
                            ),
                          ),
                          if (error != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(error, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12)),
                            ),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AdminColors.primary,
                                foregroundColor: AdminColors.onPrimary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AdminColors.onPrimary))
                                  : const Text('Đăng nhập', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shield_outlined, size: 16, color: Color(0xFF10B981)),
                              SizedBox(width: 6),
                              Text('Kết nối bảo mật với Firebase', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            ],
                          ),
                        ],
                          ),
                        ),
                      );

                      final brand = Container(
                        padding: const EdgeInsets.all(44),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.shopping_bag_rounded, size: 38, color: AdminColors.primary),
                            ),
                            const SizedBox(height: 28),
                            const Text(
                              'Why I Buy',
                              style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Quản lý dữ liệu.\nHiểu người dùng.\nTăng trưởng thông minh.',
                              style: TextStyle(fontSize: 20, height: 1.35, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 30),
                            _featureRow(Icons.people_alt_outlined, 'Quản lý người dùng tập trung'),
                            _featureRow(Icons.insights_outlined, 'Theo dõi chỉ số theo thời gian thực'),
                            _featureRow(Icons.notifications_active_outlined, 'Kết nối và gửi thông điệp'),
                          ],
                        ),
                      );

                      return isCompact
                          ? Column(children: [brand, form])
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(width: constraints.maxWidth * 5 / 11, child: brand),
                                SizedBox(width: constraints.maxWidth * 6 / 11, child: form),
                              ],
                            );
                    },
                      ),
                    ),
                  ),
                  );
                },
              ),
            ),
          ),
      ),
    );
  }

  Widget _featureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF0F172A)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(IconData icon, String label, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AdminColors.primary, width: 2),
      ),
    );
  }
}

class WhyIBuyAdminApp extends StatelessWidget {
  const WhyIBuyAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminService>();

    return MaterialApp(
      title: 'Why I Buy - Quản Trị Hệ Thống (Flutter Web)',
      debugShowCheckedModeBanner: false,
      themeMode: admin.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: const ColorScheme.light(
          primary: AdminColors.primary,
          surface: Color(0xFFFFFFFF),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF020617),
        colorScheme: const ColorScheme.dark(
          primary: AdminColors.primary,
          surface: Color(0xFF0F172A),
        ),
      ),
      home: const AdminMainLayout(),
    );
  }
}
