import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/wishlist_viewmodel.dart';
import 'home_screen.dart';
import 'monthly_reflection_screen.dart';
import 'profile_screen.dart';
import 'wishlist_screen.dart';

/// Main Shell with BottomNavigationBar
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    WishlistScreen(),
    MonthlyReflectionScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVm = context.read<AuthViewModel>();
      if (authVm.userId != null) {
        context.read<WishlistViewModel>().setUserId(authVm.userId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Keep user stream synchronized
    final authVm = context.watch<AuthViewModel>();
    if (authVm.userId != null) {
      context.read<WishlistViewModel>().setUserId(authVm.userId!);
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        indicatorColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.onPrimary),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark, color: AppColors.onPrimary),
            label: 'Wishlist',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights, color: AppColors.onPrimary),
            label: 'Chiêm nghiệm',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.onPrimary),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}
