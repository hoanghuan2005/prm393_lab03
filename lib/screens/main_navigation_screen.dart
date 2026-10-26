import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/insights_viewmodel.dart';
import '../viewmodels/purchase_viewmodel.dart';
import '../viewmodels/wishlist_viewmodel.dart';
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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVm = context.read<AuthViewModel>();
      if (authVm.userId != null) {
        context.read<WishlistViewModel>().setUserId(authVm.userId!);
        context.read<PurchaseViewModel>().setUserId(authVm.userId!);
      }
      context.read<InsightsViewModel>().setVisible(
        _currentIndex == _insightsTabIndex,
      );
    });
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
    final screens = [
      HomeScreen(onNavigateTab: _navigateToTab),
      const HistoryScreen(),
      const PatternsScreen(),
      const InsightsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  label: 'Trang chủ',
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                ),
                _buildNavItem(
                  index: 1,
                  label: 'Lịch sử',
                  icon: Icons.format_list_bulleted_rounded,
                  activeIcon: Icons.format_list_bulleted_rounded,
                ),
                _buildNavItem(
                  index: 2,
                  label: 'Mô hình',
                  icon: Icons.bar_chart_rounded,
                  activeIcon: Icons.bar_chart_rounded,
                ),
                _buildNavItem(
                  index: 3,
                  label: 'Góc nhìn',
                  icon: Icons.lightbulb_outline_rounded,
                  activeIcon: Icons.lightbulb_rounded,
                ),
                _buildNavItem(
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
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => _navigateToTab(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            size: 24,
            color: isSelected ? AppColors.onPrimary : AppColors.navInactive,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.onPrimary : AppColors.navInactive,
            ),
          ),
        ],
      ),
    );
  }
}
