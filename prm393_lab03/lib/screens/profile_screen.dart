import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app.dart';
import '../app/routes.dart';
import '../core/constants/app_constants.dart';
import '../core/formatters/email_format.dart';
import '../models/ui_state.dart';
import '../services/auth_service.dart';
import '../services/floating_bubble_service.dart';
import '../services/pending_writes.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_semantic_colors.dart';
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
import '../widgets/price_history_demo_section.dart';
import '../widgets/section_card.dart';
import '../widgets/why_i_buy_logo.dart';

/// Screen Profile & Firebase Demo Area
class ProfileScreen extends StatelessWidget {
  final VoidCallback? onBackTap;

  const ProfileScreen({super.key, this.onBackTap});

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
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leadingWidth: 42,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.chevron_left_rounded, size: 30),
          tooltip: 'Trang chủ',
          onPressed: onBackTap,
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            const WhyIBuyLogo(size: 26, color: AppColors.onPrimary),
            const SizedBox(width: 4),
            Text(
              'Cá nhân',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Đăng xuất',
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
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text('Chế độ tối'),
                  trailing: Semantics(
                    label: 'Chế độ tối',
                    child: Switch(
                      value: isDark,
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor:
                          theme.colorScheme.surfaceContainerHighest,
                      activeThumbColor: AppColors.onPrimary,
                      inactiveThumbColor: AppColors.primary,
                      thumbIcon: WidgetStateProperty.resolveWith(
                        (states) => Icon(
                          states.contains(WidgetState.selected)
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: states.contains(WidgetState.selected)
                              ? AppColors.primary
                              : AppColors.onPrimary,
                          size: 16,
                        ),
                      ),
                      onChanged: (value) => themeVm.setThemeMode(
                        value ? ThemeMode.dark : ThemeMode.light,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimens.space16),
            // Figma 10 (bản sửa): reminders, data, support
            const _GroupLabel('Cài đặt nhắc nhở'),
            _SettingsGroup(
              children: [
                _DailyReminderTile(settingsVm: settingsVm),
                const _FloatingBubbleTile(),
              ],
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
                  title: 'Xoá toàn bộ dữ liệu',
                  subtitle: 'Xoá vĩnh viễn khoản mua, món mong muốn, ngân sách và chiêm nghiệm.',
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
                      style: AppTextStyles.bodyMedium.themed(context),
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

            // Button to preview Onboarding screen
            OutlinedButton.icon(
              icon: const Icon(Icons.school_outlined, size: 20),
              label: const Text('Xem màn hình giới thiệu'),
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
                color: AppSemanticColors.of(context).primaryContainer,
                borderRadius: AppDimens.borderPill,
              ),
              child: Text(
                'NGÂN SÁCH & HỒ SƠ MUA SẮM',
                style: AppTextStyles.labelMedium
                    .themed(context)
                    .copyWith(
                      color: AppSemanticColors.of(context).emphasis,
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
                  'Đặt mốc tham chiếu cho từng nhóm hàng mỗi tháng để so với số đã chi. App không chặn mua.',
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
                  style: AppTextStyles.bodyMedium.themed(context),
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

            // Demo data, sample price chart, Remote Config and test tools are for the team
            // and the demo video: folded away so users do not land on developer panels
            Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                key: const ValueKey('profile-dev-tools'),
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.build_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                title: Text(
                  'Công cụ cho nhóm phát triển',
                  style: AppTextStyles.titleMedium
                      .themed(context)
                      .copyWith(color: theme.colorScheme.onSurface),
                ),
                subtitle: Text(
                  'Dữ liệu demo, Remote Config, thử thông báo',
                  style: AppTextStyles.bodyMedium
                      .themed(context)
                      .copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                children: [
                  // Demo data (never seeded automatically)
                  SectionCard(
                    title: 'Dữ liệu demo',
                    icon: Icons.dataset_outlined,
                    children: [
                      Text(
                        'Tạo khoảng 20 khoản mua, 6 món mong muốn, ngân sách tháng này và chiêm nghiệm tháng trước để thử các màn hình.',
                        style: AppTextStyles.bodyMedium
                            .themed(context)
                            .copyWith(
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

                  // Sample data of "Biểu đồ giá tham khảo" (admins only)
                  const PriceHistoryDemoSection(),

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
                    title: 'Firebase Remote Config',
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
                        settingsVm.enableAiInsight
                            ? 'Bật (True)'
                            : 'Tắt (False)',
                      ),
                      _buildKeyValueRow(
                        context,
                        'Số món tối đa (max_wishlist_items):',
                        '${settingsVm.maxWishlistItems} món',
                      ),
                      _buildKeyValueRow(
                        context,
                        'Nhắc nhở đợt sale (sale_reminder_enabled):',
                        settingsVm.saleReminderEnabled
                            ? 'Bật (True)'
                            : 'Tắt (False)',
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
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space16),

            // 2. FCM Notification Center
            SectionCard(
              title: 'Thông báo',
              icon: Icons.notifications_active_outlined,
              children: [
                if (settingsVm.asksNotificationPermissionInApp) ...[
                  if (settingsVm.notificationsEnabled)
                    Text(
                      'Đã bật thông báo cho ứng dụng.',
                      style: AppTextStyles.bodyMedium
                          .themed(context)
                          .copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                                  : 'Thông báo đang bị chặn. Bật lại trong cài đặt của máy hoặc trình duyệt.',
                            ),
                            behavior: SnackBarBehavior.floating,
                            action: ok
                                ? null
                                : SnackBarAction(
                                    label: 'Mở cài đặt',
                                    onPressed: () =>
                                        settingsVm.openNotificationSettings(),
                                  ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: AppDimens.space12),
                ],
                Text(
                  'Hộp thư nhận thông báo (${settingsVm.notifications.length} tin nhắn):',
                  style: AppTextStyles.labelLarge
                      .themed(context)
                      .copyWith(color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: AppDimens.space8),
                if (settingsVm.notifications.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimens.space12,
                    ),
                    child: Text(
                      'Chưa có thông báo nào.',
                      style: AppTextStyles.bodyMedium
                          .themed(context)
                          .copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                        leading: Icon(
                          Icons.mark_email_unread_outlined,
                          color: AppSemanticColors.of(context).info,
                        ),
                        title: Text(
                          notif.title,
                          style: AppTextStyles.titleMedium
                              .themed(context)
                              .copyWith(color: theme.colorScheme.onSurface),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notif.body,
                              style: AppTextStyles.bodyMedium
                                  .themed(context)
                                  .copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            if (notif.openedVia != null)
                              Text(
                                'Đã mở',
                                style: AppTextStyles.caption
                                    .themed(context)
                                    .copyWith(
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
                style: AppTextStyles.caption.themed(context),
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
              style: AppTextStyles.bodyMedium
                  .themed(context)
                  .copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: AppDimens.space8),
          Text(
            value,
            style: AppTextStyles.labelLarge
                .themed(context)
                .copyWith(color: theme.colorScheme.onSurface),
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
        style: AppTextStyles.labelMedium
            .themed(context)
            .copyWith(
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
        style: AppTextStyles.titleMedium.themed(context).copyWith(color: color),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: AppTextStyles.bodyMedium
                  .themed(context)
                  .copyWith(color: theme.colorScheme.onSurfaceVariant),
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
        style: AppTextStyles.titleMedium
            .themed(context)
            .copyWith(color: theme.colorScheme.onSurface),
      ),
      subtitle: Text(
        supported
            ? 'Nhắc bạn ghi lại khoản mua lúc $time mỗi tối. Chạm để đổi giờ.'
            : 'Chỉ có trên ứng dụng Android.',
        style: AppTextStyles.bodyMedium
            .themed(context)
            .copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      onTap: supported ? () => _pickTime(context) : null,
      trailing: Semantics(
        label: 'Nhắc ghi khoản mua',
        child: Switch(
          key: const ValueKey('daily-reminder-switch'),
          value: supported && settingsVm.dailyReminderEnabled,
          onChanged: supported ? (on) => _toggle(context, on) : null,
        ),
      ),
    );
  }
}

/// Floating shopping assistant bubble tile (Option A: Shopping Guardian Bubble)
class _FloatingBubbleTile extends StatefulWidget {
  const _FloatingBubbleTile();

  @override
  State<_FloatingBubbleTile> createState() => _FloatingBubbleTileState();
}

class _FloatingBubbleTileState extends State<_FloatingBubbleTile>
    with WidgetsBindingObserver {
  bool _isRunning = false;
  bool _isLoading = false;
  bool _isA11yEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStatus();
    }
  }

  Future<void> _checkStatus() async {
    final running = await FloatingBubbleService.isBubbleRunning();
    final a11y = await FloatingBubbleService.isAccessibilityServiceEnabled();
    if (mounted) {
      setState(() {
        _isRunning = running;
        _isA11yEnabled = a11y;
      });
    }
  }

  Future<void> _toggle(bool on) async {
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    if (!on) {
      await FloatingBubbleService.stopFloatingBubble();
      if (mounted) {
        setState(() {
          _isRunning = false;
          _isLoading = false;
        });
      }
      return;
    }

    final hasPerm = await FloatingBubbleService.checkOverlayPermission();
    if (!hasPerm) {
      if (mounted) {
        final grant = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.layers_outlined, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Cấp quyền hiển thị',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: const Text(
              'Để hiển thị bong bóng hỗ trợ săn sale và cảnh báo không mua vội khi bạn xem món đồ, ứng dụng cần quyền "Xuất hiện trên cùng" (Display over other apps).\n\nBấm Tiếp tục để mở cài đặt cấp quyền.',
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Bỏ qua'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Tiếp tục'),
              ),
            ],
          ),
        );

        if (grant == true) {
          await FloatingBubbleService.requestOverlayPermission();
        }
        if (mounted) setState(() => _isLoading = false);
        return;
      }
    }

    final ok = await FloatingBubbleService.startFloatingBubble();
    if (mounted) {
      setState(() {
        _isRunning = ok;
        _isLoading = false;
      });
      if (ok) {
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: const Text('✨ Đã bật bong bóng trợ lý mua sắm!'),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Thử thông báo',
              textColor: AppColors.primary,
              onPressed: () {
                FloatingBubbleService.showTestAlert();
              },
            ),
          ),
        );
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            messenger.hideCurrentSnackBar();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space16,
            vertical: AppDimens.space4,
          ),
          leading: const WhyIBuyLogo(size: 36),
          title: Text(
            'Bong bóng trợ lý săn sale',
            style: AppTextStyles.titleMedium
                .themed(context)
                .copyWith(color: theme.colorScheme.onSurface),
          ),
          subtitle: Text(
            'Tự động thức tỉnh khi xem lâu & giữ giá khi sao chép link.',
            style: AppTextStyles.bodyMedium
                .themed(context)
                .copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          trailing: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Semantics(
                  label: 'Bong bóng trợ lý',
                  child: Switch(
                    value: isAndroid && _isRunning,
                    onChanged: isAndroid ? _toggle : null,
                  ),
                ),
        ),
        if (_isRunning)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.space16,
              0,
              AppDimens.space16,
              AppDimens.space12,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.6),
                          ),
                        ),
                        icon: const Icon(
                          Icons.notifications_active_outlined,
                          size: 15,
                        ),
                        label: const Text(
                          'Thử thông báo',
                          style: TextStyle(fontSize: 11),
                        ),
                        onPressed: () {
                          FloatingBubbleService.showTestAlert();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.6),
                          ),
                        ),
                        icon: const Icon(Icons.air_rounded, size: 15),
                        label: const Text(
                          'Thử Pulse xem lâu',
                          style: TextStyle(fontSize: 11),
                        ),
                        onPressed: () {
                          FloatingBubbleService.showTestLingeringAlert();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (!_isA11yEnabled)
                  InkWell(
                    onTap: () async {
                      await FloatingBubbleService.openAccessibilitySettings();
                    },
                    borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppDimens.radiusSmall,
                        ),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Bật tự động nhận diện khi xem lâu (Hỗ trợ tiếp cận)',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 12),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppSemanticColors.of(context).linkedAccountAccent
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppDimens.radiusSmall,
                      ),
                      border: Border.all(
                        color: AppSemanticColors.of(context).linkedAccountAccent
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 15,
                          color: AppSemanticColors.of(context)
                              .linkedAccountAccent,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Tự động thức tỉnh khi xem lâu đang hoạt động',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppSemanticColors.of(context)
                                  .linkedAccountText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
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
            style: AppTextStyles.bodyMedium
                .themed(context)
                .copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                  SnackBar(
                    content: const Text(
                      'Đã ghi nhận 1 Non-fatal error lên Crashlytics dashboard.',
                    ),
                    backgroundColor: AppSemanticColors.of(context)
                        .snackbarSuccess,
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
                  SnackBar(
                    content: const Text(
                      'Đã kích hoạt hiển thị thông báo trên thanh trạng thái điện thoại.',
                    ),
                    backgroundColor: AppSemanticColors.of(context)
                        .snackbarSuccess,
                  ),
                );
              }
            },
          ),
          const SizedBox(height: AppDimens.space8),
          Text(
            'Thông báo FCM thật gửi từ Firebase Console.',
            style: AppTextStyles.caption
                .themed(context)
                .copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Account card at the top of Cá nhân. Never shows the full email or uid.
class AccountHeaderCard extends StatelessWidget {
  const AccountHeaderCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authVm = context.watch<AuthViewModel>();
    // AuthService.displayName falls back to the email when there is no name
    final rawName = authVm.displayName;
    final name = rawName.contains('@') ? maskEmail(rawName) : rawName;
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
              style: AppTextStyles.headlineMedium
                  .themed(context)
                  .copyWith(color: AppColors.onPrimary),
            ),
          ),
          const SizedBox(width: AppDimens.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.titleMedium
                      .themed(context)
                      .copyWith(color: theme.colorScheme.onSurface),
                ),
                Text(
                  _accountLabel(authVm, linkedNames),
                  style: AppTextStyles.bodyMedium
                      .themed(context)
                      .copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                'Liên kết Google, Facebook hoặc GitHub để giữ dữ liệu khi đổi máy hoặc đăng xuất.',
                style: AppTextStyles.bodyMedium
                    .themed(context)
                    .copyWith(color: theme.colorScheme.onSurfaceVariant),
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
  String get _name => switch (row.providerId) {
    LinkedAccountsViewModel.googleId => 'Google',
    LinkedAccountsViewModel.facebookId => 'Facebook',
    _ => 'GitHub',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = context.read<LinkedAccountsViewModel>();
    // Every button waits while any row is busy: the ViewModel ignores a second action
    final locked = context.select<LinkedAccountsViewModel, bool>(
      (vm) => vm.isBusy,
    );
    final isLinked = row.state == LinkState.linked;
    // Why "Huỷ liên kết" is disabled: the only sign-in method left
    final showLastNote = isLinked && !vm.isGuest && !locked && !row.canUnlink;
    final subtitleStyle = AppTextStyles.bodyMedium
        .themed(context)
        .copyWith(color: theme.colorScheme.onSurfaceVariant);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(switch (row.providerId) {
        LinkedAccountsViewModel.googleId => Icons.g_mobiledata,
        LinkedAccountsViewModel.facebookId => Icons.facebook,
        _ => Icons.code_rounded,
      }, color: theme.colorScheme.onSurface),
      title: Text(
        _name,
        style: AppTextStyles.titleMedium
            .themed(context)
            .copyWith(color: theme.colorScheme.onSurface),
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
                    AuthService.lastProvider.messageVi,
                    style: subtitleStyle,
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
    await switch (row.providerId) {
      LinkedAccountsViewModel.googleId => vm.linkGoogle(),
      LinkedAccountsViewModel.facebookId => vm.linkFacebook(),
      _ => vm.linkGithub(),
    };
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
