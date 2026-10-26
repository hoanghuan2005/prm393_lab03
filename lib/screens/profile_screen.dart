import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/section_card.dart';

/// Screen Profile & Firebase Demo Area
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final settingsVm = context.watch<SettingsViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cá nhân & Firebase Demo')),
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
                      authVm.displayName.isNotEmpty
                          ? authVm.displayName[0].toUpperCase()
                          : 'U',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authVm.displayName,
                          style: AppTextStyles.titleMedium,
                        ),
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
                Navigator.pushNamed(context, AppRoutes.onboarding);
              },
            ),

            const SizedBox(height: AppDimens.space24),

            // Firebase Demo Area Header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space12,
                vertical: AppDimens.space6,
              ),
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: AppDimens.borderPill,
              ),
              child: Text(
                'FIREBASE DEMO AREA',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppDimens.space16),

            // Budget Management Section
            SectionCard(
              title: 'Ngân sách chi tiêu',
              icon: Icons.account_balance_wallet_outlined,
              children: [
                const Text(
                  'Thiết lập ngân sách tham chiếu theo tháng và theo nhóm hàng, tự động đồng bộ Firestore:',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                AppButton(
                  title: 'Quản lý ngân sách theo nhóm',
                  variant: AppButtonVariant.primary,
                  icon: Icons.bar_chart_rounded,
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.budget);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppDimens.space16),

            // Demo data (never seeded automatically)
            SectionCard(
              title: 'Dữ liệu demo',
              icon: Icons.dataset_outlined,
              children: [
                Text(
                  'Tạo khoảng 20 khoản mua, 6 món mong muốn, ngân sách tháng này và chiêm nghiệm tháng trước để thử các màn hình.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppDimens.space12),
                AppButton(
                  title: 'Tạo lại dữ liệu demo',
                  icon: Icons.auto_awesome_motion_outlined,
                  isLoading: settingsVm.isDemoBusy,
                  onPressed: () => _confirmSeed(context, settingsVm),
                ),
                const SizedBox(height: AppDimens.space8),
                AppButton(
                  title: 'Xoá toàn bộ dữ liệu của tôi',
                  icon: Icons.delete_outline,
                  variant: AppButtonVariant.danger,
                  onPressed: settingsVm.isDemoBusy
                      ? null
                      : () => _confirmClear(context, settingsVm),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.space16),

            if (kDebugMode) ...[
              AppButton(
                title: 'Widget Gallery (debug)',
                icon: Icons.widgets_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.widgetGallery),
              ),
              const SizedBox(height: AppDimens.space16),
            ],

            // 1. Remote Config Section
            SectionCard(
              title: '1. Firebase Remote Config',
              icon: Icons.tune,
              children: [
                _buildKeyValueRow(
                  'Thời gian hoãn mua (cooling_off_days):',
                  '${settingsVm.coolingOffDays} ngày',
                ),
                _buildKeyValueRow(
                  'Bật tính năng AI (enable_ai_insight):',
                  settingsVm.enableAiInsight ? 'Bật (True)' : 'Tắt (False)',
                ),
                _buildKeyValueRow(
                  'Số món tối đa (max_wishlist_items):',
                  '${settingsVm.maxWishlistItems} món',
                ),
                _buildKeyValueRow(
                  'Nhắc nhở đợt sale (sale_reminder_enabled):',
                  settingsVm.saleReminderEnabled ? 'Bật (True)' : 'Tắt (False)',
                ),
                const SizedBox(height: AppDimens.space12),
                AppButton(
                  title: 'Cập nhật Remote Config (Live Fetch)',
                  variant: AppButtonVariant.secondary,
                  isLoading: settingsVm.isRefreshingConfig,
                  onPressed: () async {
                    await settingsVm.refreshRemoteConfig();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Đã cập nhật cấu hình Remote Config mới nhất từ Firebase.',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: AppDimens.space16),

            // 2. Crashlytics Section
            SectionCard(
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
                    await settingsVm.testHandledNonFatalError(
                      authVm.userId ?? 'unknown_user',
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Đã ghi nhận 1 Non-fatal error lên Crashlytics dashboard.',
                          ),
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
            SectionCard(
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
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimens.space12,
                    ),
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
                        leading: const Icon(
                          Icons.mark_email_unread_outlined,
                          color: AppColors.info,
                        ),
                        title: Text(
                          notif.title,
                          style: AppTextStyles.titleMedium,
                        ),
                        subtitle: Text(
                          notif.body,
                          style: AppTextStyles.bodyMedium,
                        ),
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

  Future<void> _confirmSeed(
    BuildContext context,
    SettingsViewModel settingsVm,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ConfirmDialog.show(
      context,
      title: 'Tạo lại dữ liệu demo?',
      message: 'Dữ liệu hiện tại của bạn sẽ được thay bằng dữ liệu demo.',
      confirmLabel: 'Tạo dữ liệu',
    );
    if (!ok) return;
    final done = await settingsVm.seedDemoData();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          done
              ? 'Đã tạo dữ liệu demo.'
              : 'Chưa tạo được dữ liệu demo. Thử lại sau ít phút.',
        ),
      ),
    );
  }

  Future<void> _confirmClear(
    BuildContext context,
    SettingsViewModel settingsVm,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ConfirmDialog.show(
      context,
      title: 'Xoá toàn bộ dữ liệu?',
      message:
          'Mọi khoản mua, món mong muốn, quyết định, ngân sách và chiêm nghiệm '
          'sẽ bị xoá vĩnh viễn khỏi tài khoản. Không thể hoàn tác.',
      confirmLabel: 'Xoá tất cả',
      isDanger: true,
    );
    if (!ok) return;
    final done = await settingsVm.clearAllData();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          done
              ? 'Đã xoá toàn bộ dữ liệu.'
              : 'Chưa xoá được dữ liệu. Thử lại sau ít phút.',
        ),
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
