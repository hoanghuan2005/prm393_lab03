import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app.dart';
import '../app/routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/inbox_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../viewmodels/wishlist_viewmodel.dart';

class AppHeaderActions extends StatelessWidget {
  final VoidCallback? onProfileTap;

  const AppHeaderActions({super.key, this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    // Always provided in the app; a screen tested on its own may leave them out
    final settingsVm = context.watch<SettingsViewModel?>();
    final wishlistVm = context.watch<WishlistViewModel?>();
    final iconColor = AppSemanticColors.of(context).emphasis;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (settingsVm != null)
          _NotificationButton(color: iconColor, settingsVm: settingsVm),
        if (wishlistVm != null)
          _WishlistButton(
            color: iconColor,
            count: wishlistVm.consideringCount,
            onPressed: () => Navigator.pushNamed(context, AppRoutes.wishlist),
          ),
        Padding(
          padding: const EdgeInsets.only(
            right: AppDimens.space12,
            left: AppDimens.space2,
          ),
          // Icon-only button: the tooltip also names it for TalkBack
          child: Tooltip(
            message: 'Cá nhân',
            child: InkWell(
              onTap: onProfileTap,
              borderRadius: AppDimens.borderPill,
              child: Container(
                width: AppDimens.minTouchTarget,
                height: AppDimens.minTouchTarget,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.onPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final Color color;
  final SettingsViewModel settingsVm;

  const _NotificationButton({required this.color, required this.settingsVm});

  @override
  Widget build(BuildContext context) {
    // Hộp thư (Firestore) is provided in the app; a screen tested alone may skip it
    final inboxVm = context.watch<InboxViewModel?>();
    final count = settingsVm.notifications.length + (inboxVm?.unreadCount ?? 0);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(
            count == 0
                ? Icons.notifications_none_rounded
                : Icons.notifications_rounded,
            color: color,
            size: 24,
          ),
          tooltip: 'Thông báo',
          onPressed: () => _showNotifications(context, inboxVm),
        ),
        if (count > 0)
          Positioned(
            right: 7,
            top: 7,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(AppDimens.space4),
                decoration: BoxDecoration(
                  color: AppSemanticColors.of(context).notificationBadge,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: AppTextStyles.caption.withInheritedColor.copyWith(
                    color: AppSemanticColors.of(context).onNotificationBadge,

                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showNotifications(BuildContext context, InboxViewModel? inboxVm) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.space20,
            0,
            AppDimens.space20,
            AppDimens.space20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thông báo',
                style: AppTextStyles.headlineMedium.withInheritedColor.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppDimens.space12),
              if (inboxVm != null) ...[
                ListTile(
                  key: const ValueKey('open-inbox'),
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppSemanticColors.of(context)
                        .primaryContainer,
                    child: Icon(
                      Icons.mail_outline,
                      color: AppSemanticColors.of(context).onPrimaryContainer,
                    ),
                  ),
                  title: const Text(
                    'Hộp thư',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    inboxVm.unreadCount == 0
                        ? 'Thông báo của nhóm và tin trả lời cho bạn'
                        : '${inboxVm.unreadCount} tin chưa đọc',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.pushNamed(context, AppRoutes.inbox);
                  },
                ),
                const Divider(),
              ],
              if (settingsVm.notifications.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppDimens.space24),
                  child: Center(child: Text('Chưa có thông báo mới.')),
                )
              else
                ...settingsVm.notifications
                    .take(5)
                    .map(
                      (notification) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppSemanticColors.of(context)
                              .primaryContainer,
                          child: Icon(
                            Icons.notifications_active_outlined,
                            color: AppSemanticColors.of(context)
                                .onPrimaryContainer,
                          ),
                        ),
                        title: Text(
                          notification.title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(notification.body),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          openFromNotification(notification.data);
                        },
                      ),
                    ),
              if (settingsVm.asksNotificationPermissionInApp &&
                  !settingsVm.notificationsEnabled)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final ok = await settingsVm.enableNotifications();
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                      // Denied before: Android shows no dialog, so say so and offer settings
                      if (!ok) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Thông báo đang bị chặn cho Why I Buy.',
                            ),
                            behavior: SnackBarBehavior.floating,
                            action: SnackBarAction(
                              label: 'Mở cài đặt',
                              onPressed: () =>
                                  settingsVm.openNotificationSettings(),
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.notifications_outlined),
                    label: const Text('Bật thông báo'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WishlistButton extends StatelessWidget {
  final Color color;
  final int count;
  final VoidCallback onPressed;

  const _WishlistButton({
    required this.color,
    required this.count,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(Icons.bookmark_outline_rounded, color: color, size: 24),
          tooltip: 'Danh sách mong muốn',
          onPressed: onPressed,
        ),
        if (count > 0)
          Positioned(
            right: 7,
            top: 7,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(AppDimens.space4),
                decoration: BoxDecoration(
                  color: AppSemanticColors.of(context).notificationBadge,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: AppTextStyles.caption.withInheritedColor.copyWith(
                    color: AppSemanticColors.of(context).onNotificationBadge,

                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
