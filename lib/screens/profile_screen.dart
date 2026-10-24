import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../widgets/app_button.dart';
import 'budget_screen.dart';
import 'onboarding_screen.dart';

/// Screen Profile & Firebase Demo Area (Section 6)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final settingsVm = context.watch<SettingsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cá nhân & Firebase Demo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Card
            Container(
              padding: const EdgeInsets.all(AppDimens.space16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppDimens.borderLarge,
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      authVm.displayName.isNotEmpty ? authVm.displayName[0].toUpperCase() : 'U',
                      style: AppTextStyles.headlineMedium.copyWith(color: AppColors.onPrimary),
                    ),
                  ),
                  const SizedBox(width: AppDimens.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(authVm.displayName, style: AppTextStyles.titleMedium),
                        Text(
                          authVm.user?.email ?? 'Tài khoản ẩn danh / Khách',
                          style: AppTextStyles.bodyMedium,
                        ),
                        Text(
                          'UID: ${authVm.userId ?? "N/A"}',
                          style: AppTextStyles.caption,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space12),

            // Button to preview 01 Onboarding screen
            OutlinedButton.icon(
              icon: const Icon(Icons.school_outlined, size: 20),
              label: const Text('Xem màn hình giới thiệu (01 Onboarding)'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                );
              },
            ),

            const SizedBox(height: AppDimens.space24),

            // Firebase Demo Area Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.space12, vertical: AppDimens.space6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: AppDimens.borderPill,
              ),
              child: Text(
                'FIREBASE DEMO AREA (Section 6)',
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: AppDimens.space16),

            // Budget Management Section
            _buildSectionCard(
              title: 'Ngân sách chi tiêu (Figma 31)',
              icon: Icons.account_balance_wallet_outlined,
              children: [
                const Text(
                  'Thiết lập ngân sách tham chiếu theo tháng và theo nhóm hàng, tự động đồng bộ Firestore:',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6D6E73)),
                ),
                const SizedBox(height: 12),
                AppButton(
                  title: 'Quản lý ngân sách theo nhóm',
                  variant: AppButtonVariant.primary,
                  icon: Icons.bar_chart_rounded,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BudgetScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppDimens.space16),

            // 1. Remote Config Section
            _buildSectionCard(
              title: '1. Firebase Remote Config',
              icon: Icons.tune,
              children: [
                _buildKeyValueRow('Thời gian hoãn mua (cooling_off_days):', '${settingsVm.coolingOffDays} ngày'),
                _buildKeyValueRow('Bật tính năng AI (enable_ai_insight):', settingsVm.enableAiInsight ? 'Bật (True)' : 'Tắt (False)'),
                _buildKeyValueRow('Số món tối đa (max_wishlist_items):', '${settingsVm.maxWishlistItems} món'),
                _buildKeyValueRow('Nhắc nhở đợt sale (sale_reminder_enabled):', settingsVm.saleReminderEnabled ? 'Bật (True)' : 'Tắt (False)'),
                const SizedBox(height: AppDimens.space12),
                AppButton(
                  title: 'Cập nhật Remote Config (Live Fetch)',
                  variant: AppButtonVariant.secondary,
                  isLoading: settingsVm.isRefreshingConfig,
                  onPressed: () async {
                    await settingsVm.refreshRemoteConfig();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã cập nhật cấu hình Remote Config mới nhất từ Firebase!')),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: AppDimens.space16),

            // 2. Crashlytics Section
            _buildSectionCard(
              title: '2. Firebase Crashlytics',
              icon: Icons.bug_report_outlined,
              children: [
                Text(
                  'Kiểm thử ghi nhận lỗi Crashlytics có gắn User ID và Custom Key per Lab 3:',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppDimens.space12),
                AppButton(
                  title: 'Bắn lỗi có xử lý (Non-Fatal)',
                  variant: AppButtonVariant.secondary,
                  icon: Icons.warning_amber_rounded,
                  onPressed: () async {
                    await settingsVm.testHandledNonFatalError(authVm.userId ?? 'unknown_user');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã ghi nhận 1 Non-fatal error lên Crashlytics dashboard thành công!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: AppDimens.space12),
                AppButton(
                  title: 'Kích hoạt thử nghiệm Crash thật',
                  variant: AppButtonVariant.danger,
                  icon: Icons.dangerous_outlined,
                  onPressed: () {
                    settingsVm.testForcedCrash();
                  },
                ),
              ],
            ),
            const SizedBox(height: AppDimens.space16),

            // 3. FCM Notification Center
            _buildSectionCard(
              title: '3. Cloud Messaging (FCM) Center',
              icon: Icons.notifications_active_outlined,
              children: [
                Text(
                  'Hộp thư nhận thông báo (${settingsVm.notifications.length} tin nhắn):',
                  style: AppTextStyles.labelLarge,
                ),
                const SizedBox(height: AppDimens.space8),
                if (settingsVm.notifications.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppDimens.space12),
                    child: Text(
                      'Chưa có thông báo nào. Bạn có thể gửi tin nhắn thử từ Firebase Console FCM để kiểm tra nhận thông báo ở 3 trạng thái.',
                      style: AppTextStyles.bodyMedium,
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: settingsVm.notifications.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final notif = settingsVm.notifications[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.mark_email_unread_outlined, color: AppColors.info),
                        title: Text(notif.title, style: AppTextStyles.titleMedium),
                        subtitle: Text(notif.body, style: AppTextStyles.bodyMedium),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppDimens.space24),

            // Sign Out Button
            AppButton(
              title: 'Đăng xuất tài khoản',
              variant: AppButtonVariant.secondary,
              icon: Icons.logout,
              onPressed: () async {
                await authVm.signOut();
              },
            ),
            const SizedBox(height: AppDimens.space24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.borderLarge,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.onPrimary, size: 20),
              const SizedBox(width: AppDimens.space8),
              Text(title, style: AppTextStyles.titleMedium),
            ],
          ),
          const SizedBox(height: AppDimens.space12),
          const Divider(),
          const SizedBox(height: AppDimens.space12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildKeyValueRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.space4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(key, style: AppTextStyles.bodyMedium)),
          const SizedBox(width: AppDimens.space8),
          Text(value, style: AppTextStyles.labelLarge),
        ],
      ),
    );
  }
}
