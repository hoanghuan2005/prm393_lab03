import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/admin_service.dart';
import '../theme/admin_colors.dart';
import 'dashboard_screen.dart';
import 'users_screen.dart';
import 'push_screen.dart';
import 'ai_assistant_screen.dart';
import 'crash_monitor_screen.dart';

class AdminMainLayout extends StatelessWidget {
  const AdminMainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminService>();

    final screens = const [
      DashboardScreen(),
      UsersScreen(),
      PushScreen(),
      AiAssistantScreen(),
      CrashMonitorScreen(),
    ];

    final titles = [
      'Bảng Điều Khiển & Thống Kê',
      'Quản Lý Người Dùng & Hoạt Động',
      'Trung Tâm Gửi Thông Điệp (Push Broadcast)',
      'Trợ Lý AI & Gợi Ý Câu Hỏi Tự Vấn',
      'Cảnh Báo Sự Cố & Giám Sát Crash',
    ];

    return Scaffold(
      backgroundColor: AdminColors.background,
      body: Row(
        children: [
          // 1. Left Sidebar
          Container(
            width: 290,
            decoration: BoxDecoration(
              color: AdminColors.sidebar,
              border: Border(right: BorderSide(color: AdminColors.border)),
            ),
            child: Column(
              children: [
                // Brand Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AdminColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AdminColors.primary.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'W',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AdminColors.onPrimary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Why I Buy',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: AdminColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AdminColors.primary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AdminColors.primary.withValues(alpha: 0.4), width: 0.6),
                                  ),
                                  child: const Text(
                                    'FLUTTER',
                                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AdminColors.primary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Admin Web Portal',
                              style: TextStyle(fontSize: 11, color: AdminColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(color: AdminColors.border, height: 1),

                // Nav Items (Fixed to never wrap lines)
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10, bottom: 8, top: 4),
                        child: Text(
                          'MENU ĐIỀU HÀNH',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: AdminColors.textMuted,
                          ),
                        ),
                      ),
                      _buildNavItem(context, 0, 'Tổng quan & Chỉ số', Icons.dashboard_rounded, admin.selectedTabIndex == 0),
                      _buildNavItem(context, 1, 'Quản lý Người dùng', Icons.people_alt_rounded, admin.selectedTabIndex == 1),
                      _buildNavItem(context, 2, 'Gửi Thông điệp (Push)', Icons.campaign_rounded, admin.selectedTabIndex == 2),
                      _buildNavItem(
                        context,
                        3,
                        'AI Suggest & Câu hỏi',
                        Icons.auto_awesome_rounded,
                        admin.selectedTabIndex == 3,
                        badge: 'Gemini',
                      ),
                      _buildNavItem(
                        context,
                        4,
                        'Cảnh báo Sự cố / Crash',
                        Icons.warning_amber_rounded,
                        admin.selectedTabIndex == 4,
                        badge: admin.activeCrashesCount > 0 ? '${admin.activeCrashesCount} lỗi' : null,
                        badgeColor: AdminColors.rose,
                      ),
                    ],
                  ),
                ),

                // App & Project Footer
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AdminColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AdminColors.emerald.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.smartphone_rounded, size: 18, color: AdminColors.emerald),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'App: Why I Buy',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AdminColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Firebase: prm393-34056',
                              style: TextStyle(fontSize: 10, color: AdminColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Right Main View
          Expanded(
            child: Column(
              children: [
                // Top AppBar
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  decoration: BoxDecoration(
                    color: AdminColors.sidebar,
                    border: Border(bottom: BorderSide(color: AdminColors.border)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          titles[admin.selectedTabIndex],
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AdminColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ☀️🌙 Nút Đổi Theme (Sáng / Tối)
                            InkWell(
                              onTap: () => admin.toggleTheme(),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AdminColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AdminColors.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      admin.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                      size: 16,
                                      color: admin.isDarkMode ? AdminColors.primary : AdminColors.purple,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      admin.isDarkMode ? 'Chế độ Sáng' : 'Chế độ Tối',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AdminColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Toggle Live Firebase / Demo Mode
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: admin.isLiveFirebase
                                    ? AdminColors.emerald.withValues(alpha: 0.15)
                                    : AdminColors.primary.withValues(alpha: 0.15),
                                foregroundColor: admin.isLiveFirebase ? AdminColors.emerald : AdminColors.primary,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: admin.isLiveFirebase ? AdminColors.emerald : AdminColors.primary,
                                    width: 0.8,
                                  ),
                                ),
                              ),
                              onPressed: () => admin.toggleLiveFirebase(),
                              icon: const Icon(Icons.storage_rounded, size: 16),
                              label: Text(
                                admin.isLiveFirebase ? 'Nguồn: Firebase Live' : 'Nguồn: Dữ liệu Demo',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Refresh
                            IconButton(
                              icon: admin.isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AdminColors.primary),
                                    )
                                  : Icon(Icons.refresh_rounded, color: AdminColors.textSecondary, size: 20),
                              onPressed: () => admin.fetchFirebaseData(),
                            ),
                            const SizedBox(width: 10),

                            // Admin avatar
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AdminColors.surfaceLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AdminColors.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AdminColors.primary,
                                    child: Text('AD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AdminColors.onPrimary)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Admin Quản Trị',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.textPrimary),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: 'Đăng xuất',
                                    icon: const Icon(Icons.logout_rounded, size: 18),
                                    color: AdminColors.rose,
                                    onPressed: () async {
                                      try {
                                        await FirebaseAuth.instance.signOut();
                                      } catch (error) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Đăng xuất thất bại: $error')),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content View
                Expanded(
                  child: IndexedStack(
                    index: admin.selectedTabIndex,
                    children: screens,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    String label,
    IconData icon,
    bool isSelected, {
    String? badge,
    Color? badgeColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.read<AdminService>().selectTab(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AdminColors.primary.withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AdminColors.primary.withValues(alpha: 0.4) : Colors.transparent,
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected ? AdminColors.primary : AdminColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? AdminColors.onPrimary : AdminColors.textSecondary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? AdminColors.textPrimary : AdminColors.textSecondary,
                    ),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (badgeColor ?? AdminColors.primary).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: (badgeColor ?? AdminColors.primary).withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: badgeColor ?? AdminColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
