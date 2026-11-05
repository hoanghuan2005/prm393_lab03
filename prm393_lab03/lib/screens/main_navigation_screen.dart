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
      final initialShareData =
          context.read<ShareIntentService>().consumeInitialData();
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
      ProfileScreen(onProfileTap: () => _navigateToTab(4)),
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
            border: Border(top: BorderSide(color: theme.dividerColor, width: 1)),
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

    return InkWell(
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
    );
  }
}
