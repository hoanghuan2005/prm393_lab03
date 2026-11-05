import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app.dart';
import '../app/routes.dart';
import '../core/constants/app_constants.dart';
import '../core/formatters/email_format.dart';
import '../models/ui_state.dart';
import '../services/pending_writes.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/budget_viewmodel.dart';
import '../viewmodels/linked_accounts_viewmodel.dart';
import '../viewmodels/purchase_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/linked_devices_section.dart';
import '../widgets/section_card.dart';

/// Screen Profile & Firebase Demo Area
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authVm = context.watch<AuthViewModel>();
    final settingsVm = context.watch<SettingsViewModel>();
    final themeVm = context.watch<ThemeViewModel>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Cá nhân & Cài đặt'),
        actions: [
          // Nút công tắc Dark Mode trên AppBar
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  size: 20,
                  color: isDark ? AppColors.primary : AppColors.onPrimary,
                ),
                const SizedBox(width: 4),
                Switch(
                  value: isDark,
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: theme.colorScheme.primaryContainer,
                  inactiveThumbColor: theme.colorScheme.onSurfaceVariant,
                  inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
                  onChanged: (bool value) {
                    themeVm.setThemeMode(
                      value ? ThemeMode.dark : ThemeMode.light,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Card
            const AccountHeaderCard(),
            const SizedBox(height: AppDimens.space16),

            // Link Google / GitHub to this account (hidden where unsupported)
            const LinkedAccountsSection(),

            // Chrome extension linked with this account: "Quét mã QR" to link a browser
            const LinkedDevicesSection(),
            const SizedBox(height: AppDimens.space16),

            // Theme Mode Switch Card
            SectionCard(
              title: 'Giao diện ứng dụng',
              icon: Icons.palette_outlined,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2706)
                          : AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: isDark ? AppColors.primary : AppColors.onPrimary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Chế độ tối (Dark Mode)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    isDark
                        ? 'Đang bật nền tối cao cấp, dịu mắt'
                        : 'Đang bật nền sáng chuẩn',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value: isDark,
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: theme.colorScheme.primaryContainer,
                  inactiveThumbColor: theme.colorScheme.onSurfaceVariant,
                  inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
                  onChanged: (bool value) {
                    themeVm.setThemeMode(
                      value ? ThemeMode.dark : ThemeMode.light,
                    );
                  },
                ),
                Divider(color: theme.dividerColor, height: 20),
                // Lựa chọn tự động theo hệ thống
                InkWell(
                  onTap: () {
                    themeVm.setThemeMode(
                      themeVm.themeMode == ThemeMode.system
                          ? (isDark ? ThemeMode.dark : ThemeMode.light)
                          : ThemeMode.system,
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.brightness_auto_rounded,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tự động theo thiết bị',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Checkbox(
                          value: themeVm.themeMode == ThemeMode.system,
                          activeColor: AppColors.primary,
                          checkColor: AppColors.onPrimary,
                          onChanged: (bool? checked) {
                            if (checked == true) {
                              themeVm.setThemeMode(ThemeMode.system);
                            } else {
                              themeVm.setThemeMode(
                                isDark ? ThemeMode.dark : ThemeMode.light,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimens.space16),
            // Figma 10 (bản sửa): reminders, data, support
            const _GroupLabel('Cài đặt nhắc nhở'),
            _SettingsGroup(
              children: [_DailyReminderTile(settingsVm: settingsVm)],
            ),
            const SizedBox(height: AppDimens.space16),

            const _GroupLabel('Cài đặt dữ liệu'),
            _SettingsGroup(
              children: [
                _SettingsTile(
                  key: const ValueKey('export-csv'),
                  title: 'Xuất dữ liệu',
                  subtitle: 'Tải bản sao nhật ký và động cơ dưới dạng CSV',
                  busy: settingsVm.isExporting,
                  onTap: () => _exportCsv(context, settingsVm),
                ),
                _SettingsTile(
                  key: const ValueKey('clear-all-data'),
                  title: 'Xóa toàn bộ dữ liệu',
                  subtitle: 'Xóa vĩnh viễn mọi khoản mua đã ghi.',
                  isDanger: true,
                  onTap: settingsVm.isDemoBusy
                      ? null
                      : () => _confirmClear(context, settingsVm),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.space16),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space16,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppDimens.space12),
                  Expanded(
                    child: Text(
                      'Dữ liệu được lưu trên máy và đồng bộ với tài khoản của bạn '
                      'khi có mạng.',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space24),

            const _GroupLabel('Hỗ trợ & thông tin'),
            _SettingsGroup(
              children: [
                _SettingsTile(
                  key: const ValueKey('open-feedback'),
                  title: 'Gửi góp ý',
                  subtitle: 'Báo lỗi hoặc đề xuất tính năng mới',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.feedback),
                ),
                _SettingsTile(
                  key: const ValueKey('open-terms'),
                  title: 'Điều khoản sử dụng',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.terms),
                ),
                _SettingsTile(
                  key: const ValueKey('open-privacy'),
                  title: 'Chính sách quyền riêng tư',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.privacy),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.space24),

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
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2C2706)
                    : AppColors.primaryContainer,
                borderRadius: AppDimens.borderPill,
              ),
              child: Text(
                'FIREBASE DEMO AREA',
                style: AppTextStyles.labelMedium.copyWith(
                  color: isDark ? AppColors.primary : AppColors.onPrimary,
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
                Text(
                  'Thiết lập ngân sách tham chiếu theo tháng và theo nhóm hàng, tự động đồng bộ Firestore:',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
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

            // Shopping profile (spec 7.2): owned items, style, brands
            SectionCard(
              title: 'Hồ sơ mua sắm',
              icon: Icons.inventory_2_outlined,
              children: [
                Text(
                  'Ghi đồ đang dùng, phong cách và thương hiệu hay dùng để Thẻ '
                  'Quyết Định nhắc khi bạn cân nhắc món cùng loại. Tất cả tùy chọn.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 12),
                AppButton(
                  key: const ValueKey('open-shopping-profile'),
                  title: 'Mở hồ sơ mua sắm',
                  variant: AppButtonVariant.secondary,
                  icon: Icons.chevron_right_rounded,
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.shoppingProfile),
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
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppDimens.space12),
                AppButton(
                  title: 'Tạo lại dữ liệu demo',
                  icon: Icons.auto_awesome_motion_outlined,
                  isLoading: settingsVm.isDemoBusy,
                  onPressed: () => _confirmSeed(context, settingsVm),
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
                  context,
                  'Thời gian hoãn mua (cooling_off_days):',
                  '${settingsVm.coolingOffDays} ngày',
                ),
                _buildKeyValueRow(
                  context,
                  'Bật tính năng AI (enable_ai_insight):',
                  settingsVm.enableAiInsight ? 'Bật (True)' : 'Tắt (False)',
                ),
                _buildKeyValueRow(
                  context,
                  'Số món tối đa (max_wishlist_items):',
                  '${settingsVm.maxWishlistItems} món',
                ),
                _buildKeyValueRow(
                  context,
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

            // Crashlytics and local notification test buttons (debug builds only)
            FirebaseDemoTools(userId: authVm.userId ?? 'unknown_user'),

            // 2. FCM Notification Center
            SectionCard(
              title: '2. Cloud Messaging (FCM) Center',
              icon: Icons.notifications_active_outlined,
              children: [
                if (settingsVm.asksNotificationPermissionInApp) ...[
                  if (settingsVm.notificationsEnabled)
                    Text(
                      'Đã bật thông báo cho ứng dụng.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      icon: const Icon(Icons.notifications_outlined),
                      label: const Text('Bật thông báo'),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final ok = await settingsVm.enableNotifications();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? 'Đã bật thông báo. Tin nhắn FCM và nhắc xem lại sẽ hiện kể cả khi app đang đóng.'
                                  : 'Chưa được phép gửi thông báo. Bạn có thể bật lại trong cài đặt của máy hoặc trình duyệt.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: AppDimens.space12),
                ],
                Text(
                  'Hộp thư nhận thông báo (${settingsVm.notifications.length} tin nhắn):',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppDimens.space8),
                if (settingsVm.notifications.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimens.space12,
                    ),
                    child: Text(
                      'Chưa có thông báo nào. Bạn có thể gửi tin nhắn thử từ Firebase Console FCM để kiểm tra nhận thông báo ở 3 trạng thái.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: settingsVm.notifications.length,
                    separatorBuilder: (_, _) =>
                        Divider(color: theme.dividerColor),
                    itemBuilder: (context, index) {
                      final notif = settingsVm.notifications[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        // Same screen as tapping the system notification
                        onTap: () => openFromNotification(notif.data),
                        leading: const Icon(
                          Icons.mark_email_unread_outlined,
                          color: AppColors.info,
                        ),
                        title: Text(
                          notif.title,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notif.body,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (notif.openedVia != null)
                              Text(
                                'Đã mở',
                                style: AppTextStyles.caption.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                          ],
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
                final isGuest = authVm.user?.isAnonymous ?? false;
                final pending = PendingWrites.instance.count;
                final ok = await ConfirmDialog.show(
                  context,
                  title: 'Đăng xuất?',
                  message: [
                    if (isGuest) 'Bạn đang dùng tài khoản khách. Sau khi đăng xuất sẽ không đăng nhập lại được tài khoản này, dữ liệu của nó không còn xem được.',
                    if (pending > 0)
                      'Còn $pending thay đổi chưa đồng bộ do mất mạng; chúng chỉ được gửi lên khi bạn đăng nhập lại tài khoản này.',
                    if (!isGuest && pending == 0) 'Dữ liệu vẫn lưu trên tài khoản, đăng nhập lại để xem tiếp.',
                  ].join('\n\n'),
                  confirmLabel: 'Đăng xuất',
                  isDanger: isGuest || pending > 0,
                );
                if (ok) await authVm.signOut();
              },
            ),
            const SizedBox(height: AppDimens.space16),
            Center(
              child: Text(
                'Phiên bản ${AppConstants.appVersion}',
                style: AppTextStyles.caption,
              ),
            ),
            const SizedBox(height: AppDimens.space24),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCsv(
    BuildContext context,
    SettingsViewModel settingsVm,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final purchaseVm = context.read<PurchaseViewModel>();
    final groups = context.read<BudgetViewModel>().groups;
    void show(String text) => messenger.showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
    switch (purchaseVm.state) {
      case UiInitial() || UiLoading():
        show('Đang tải khoản mua, thử lại sau giây lát.');
        return;
      case UiError(:final message):
        show(message);
        return;
      case UiEmpty() || UiSuccess():
        break;
    }
    final result = await settingsVm.exportPurchasesCsv(
      purchaseVm.allPurchases,
      groups,
    );
    show(switch (result) {
      ExportSaved(:final fileName) => 'Đã lưu "$fileName" vào Tải xuống',
      ExportNothing() => 'Chưa có khoản mua nào để xuất.',
      ExportFailed() => 'Chưa xuất được dữ liệu. Thử lại sau ít phút.',
    });
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

  Widget _buildKeyValueRow(BuildContext context, String key, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.space4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              key,
              style: AppTextStyles.bodyMedium.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppDimens.space8),
          Text(
            value,
            style: AppTextStyles.labelLarge.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Uppercase caption above a settings group ("CÀI ĐẶT NHẮC NHỞ")
class _GroupLabel extends StatelessWidget {
  final String text;

  const _GroupLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.space8),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.labelMedium.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// White rounded card holding rows separated by thin dividers
class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppDimens.borderLarge,
        border: Border.all(color: theme.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                Divider(
                  color: theme.dividerColor,
                  height: 1,
                  indent: AppDimens.space16,
                  endIndent: AppDimens.space16,
                ),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// Row with a chevron that opens something
class _SettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isDanger;
  final bool busy;
  final VoidCallback? onTap;

  const _SettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.isDanger = false,
    this.busy = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDanger
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;
    return ListTile(
      minTileHeight: AppDimens.minTouchTarget + AppDimens.space16,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space16,
        vertical: AppDimens.space4,
      ),
      title: Text(
        title,
        style: AppTextStyles.titleMedium.copyWith(color: color),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
      trailing: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(Icons.chevron_right_rounded, color: color),
      onTap: busy ? null : onTap,
    );
  }
}

/// "Nhắc ghi khoản mua": switch turns the daily reminder on/off; tapping the row
/// changes its time. Only on Android/iOS (local notifications).
class _DailyReminderTile extends StatelessWidget {
  final SettingsViewModel settingsVm;

  const _DailyReminderTile({required this.settingsVm});

  Future<void> _toggle(BuildContext context, bool on) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!on) {
      await settingsVm.disableDailyReminder();
      return;
    }
    final ok = await settingsVm.enableDailyReminder();
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Chưa được phép gửi thông báo. Bạn có thể bật lại trong cài đặt của máy.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      helpText: 'Giờ nhắc ghi khoản mua',
      initialTime: TimeOfDay(
        hour: settingsVm.dailyReminderHour,
        minute: settingsVm.dailyReminderMinute,
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    await settingsVm.setDailyReminderTime(picked.hour, picked.minute);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final supported = settingsVm.supportsDailyReminder;
    final time = settingsVm.dailyReminderTimeText;
    return ListTile(
      key: const ValueKey('daily-reminder-tile'),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space16,
        vertical: AppDimens.space4,
      ),
      title: Text(
        'Nhắc ghi khoản mua',
        style: AppTextStyles.titleMedium.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        supported
            ? 'Nhắc bạn ghi lại khoản mua lúc $time mỗi tối. Chạm để đổi giờ.'
            : 'Chỉ có trên ứng dụng Android.',
        style: AppTextStyles.bodyMedium.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: supported ? () => _pickTime(context) : null,
      trailing: Switch(
        key: const ValueKey('daily-reminder-switch'),
        value: supported && settingsVm.dailyReminderEnabled,
        onChanged: supported ? (on) => _toggle(context, on) : null,
      ),
    );
  }
}

/// Crashlytics and local notification test buttons; release builds show nothing
class FirebaseDemoTools extends StatelessWidget {
  final String userId;

  /// Defaults to [kDebugMode]; tests pass false to check a release build
  final bool visible;

  const FirebaseDemoTools({
    super.key,
    required this.userId,
    this.visible = kDebugMode,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final settingsVm = context.read<SettingsViewModel>();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.space16),
      child: SectionCard(
        title: 'Khu trình diễn (chỉ bản debug)',
        icon: Icons.bug_report_outlined,
        children: [
          Text(
            'Kiểm thử ghi nhận lỗi Crashlytics có gắn User ID và Custom Key per Lab 3:',
            style: AppTextStyles.bodyMedium.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppDimens.space12),
          AppButton(
            title: 'Bắn lỗi có xử lý (Non-Fatal)',
            variant: AppButtonVariant.secondary,
            icon: Icons.warning_amber_rounded,
            onPressed: () async {
              await settingsVm.testHandledNonFatalError(userId);
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
            onPressed: () async {
              final ok = await ConfirmDialog.show(
                context,
                title: 'Crash thử ứng dụng?',
                message: 'App sẽ đóng ngay để gửi báo cáo crash lên Firebase Crashlytics.',
                confirmLabel: 'Crash thử',
                isDanger: true,
              );
              if (ok) await settingsVm.testForcedCrash();
            },
          ),
          const SizedBox(height: AppDimens.space12),
          AppButton(
            title: 'Thử thông báo trên máy',
            icon: Icons.notification_important_rounded,
            variant: AppButtonVariant.primary,
            onPressed: () async {
              await settingsVm.sendTestNotification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Đã kích hoạt hiển thị thông báo trên thanh trạng thái điện thoại.',
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
          ),
          const SizedBox(height: AppDimens.space8),
          Text(
            'Thông báo FCM thật gửi từ Firebase Console.',
            style: AppTextStyles.caption.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Account card at the top of Cá nhân. Never shows the full email or uid.
class AccountHeaderCard extends StatelessWidget {
  /// Defaults to [kDebugMode]; tests pass false to check a release build
  final bool showDebugUid;

  const AccountHeaderCard({super.key, this.showDebugUid = kDebugMode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authVm = context.watch<AuthViewModel>();
    // AuthService.displayName falls back to the email when there is no name
    final rawName = authVm.displayName;
    final name = rawName.contains('@') ? maskEmail(rawName) : rawName;
    final uid = authVm.userId;
    final linkedNames = context.select<LinkedAccountsViewModel, List<String>>(
      (vm) => vm.linkedProviderNames,
    );

    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppDimens.borderLarge,
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
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
                  name,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  _accountLabel(authVm, linkedNames),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (showDebugUid && uid != null)
                  Text(
                    'UID: ${uid.length > 6 ? uid.substring(0, 6) : uid}…',
                    style: AppTextStyles.caption.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Based on isAnonymous, not on having an email: a GitHub account may hide it
  static String _accountLabel(AuthViewModel authVm, List<String> linkedNames) {
    if (authVm.isAnonymous) return 'Khách';
    final email = authVm.user?.email;
    if (email != null && email.isNotEmpty) return maskEmail(email);
    // The name is already the title above; list the linked methods instead
    if (linkedNames.isNotEmpty) return 'Đã liên kết: ${linkedNames.join(', ')}';
    return 'Tài khoản đã liên kết';
  }
}

/// "Tài khoản liên kết": Google and GitHub rows; one action at a time
class LinkedAccountsSection extends StatelessWidget {
  const LinkedAccountsSection({super.key});

  static const extensionNote =
      'Extension Why I Buy? chỉ đăng nhập bằng Google. Huỷ liên kết sẽ ngắt đồng bộ với extension.';

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LinkedAccountsViewModel>();
    if (!vm.isAvailable) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.space16),
      child: SectionCard(
        title: 'Tài khoản liên kết',
        icon: Icons.link_rounded,
        children: [
          if (vm.isGuest)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.space8),
              child: Text(
                'Liên kết Google hoặc GitHub để giữ dữ liệu khi đổi máy hoặc đăng xuất.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          for (final row in vm.rows) _LinkedAccountTile(row: row),
        ],
      ),
    );
  }
}

class _LinkedAccountTile extends StatelessWidget {
  final LinkedAccountRow row;

  const _LinkedAccountTile({required this.row});

  bool get _isGoogle => row.providerId == LinkedAccountsViewModel.googleId;
  String get _name => _isGoogle ? 'Google' : 'GitHub';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = context.read<LinkedAccountsViewModel>();
    // Every button waits while any row is busy: the ViewModel ignores a second action
    final locked = context.select<LinkedAccountsViewModel, bool>(
      (vm) => vm.isBusy,
    );
    final isLinked = row.state == LinkState.linked;
    final showLastNote = isLinked && !row.canUnlink && !vm.isGuest;
    final subtitleStyle = AppTextStyles.bodyMedium.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        _isGoogle ? Icons.g_mobiledata : Icons.code_rounded,
        color: theme.colorScheme.onSurface,
      ),
      title: Text(
        _name,
        style: AppTextStyles.titleMedium.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: isLinked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.label == null
                      ? 'Đã liên kết'
                      : 'Đã liên kết · ${row.label}',
                  style: subtitleStyle,
                ),
                if (showLastNote)
                  Text(
                    'Phải giữ ít nhất một cách đăng nhập',
                    style: AppTextStyles.caption.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            )
          : null,
      trailing: switch (row.state) {
        LinkState.busy => const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        LinkState.linked =>
          vm.isGuest
              ? null
              : TextButton(
                  onPressed: locked || !row.canUnlink
                      ? null
                      : () => _unlink(context, vm),
                  child: const Text('Huỷ liên kết'),
                ),
        LinkState.notLinked => TextButton(
          onPressed: locked ? null : () => _link(context, vm),
          child: const Text('Liên kết'),
        ),
      },
    );
  }

  Future<void> _link(BuildContext context, LinkedAccountsViewModel vm) async {
    final messenger = ScaffoldMessenger.of(context);
    await (_isGoogle ? vm.linkGoogle() : vm.linkGithub());
    _showResult(messenger, vm);
  }

  Future<void> _unlink(BuildContext context, LinkedAccountsViewModel vm) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ConfirmDialog.show(
      context,
      title: 'Huỷ liên kết $_name?',
      message: [
        'Bạn sẽ không đăng nhập bằng $_name được nữa cho tới khi liên kết lại.',
        if (_isGoogle) LinkedAccountsSection.extensionNote,
      ].join('\n\n'),
      confirmLabel: 'Huỷ liên kết',
      isDanger: true,
    );
    if (!ok) return;
    await vm.unlink(row.providerId);
    _showResult(messenger, vm);
  }

  void _showResult(
    ScaffoldMessengerState messenger,
    LinkedAccountsViewModel vm,
  ) {
    final text = vm.errorMessage ?? vm.successMessage;
    if (text == null) return;
    messenger.showSnackBar(SnackBar(content: Text(text)));
    vm.clearMessages();
  }
}
