import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app.dart';
import '../app/routes.dart';
import '../theme/app_colors.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../viewmodels/wishlist_viewmodel.dart';

class AppHeaderActions extends StatelessWidget {
  final VoidCallback? onProfileTap;

  const AppHeaderActions({super.key, this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Always provided in the app; a screen tested on its own may leave them out
    final settingsVm = context.watch<SettingsViewModel?>();
    final wishlistVm = context.watch<WishlistViewModel?>();
    final iconColor = isDark ? AppColors.primary : AppColors.onPrimary;

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
          padding: const EdgeInsets.only(right: 12, left: 2),
          child: InkWell(
            onTap: onProfileTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 34,
              height: 34,
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
      ],
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final Color color;
  final SettingsViewModel settingsVm;

  const _NotificationButton({
    required this.color,
    required this.settingsVm,
  });

  @override
  Widget build(BuildContext context) {
    final count = settingsVm.notifications.length;
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
          onPressed: () => _showNotifications(context),
        ),
        if (count > 0)
          Positioned(
            right: 7,
            top: 7,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thông báo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (settingsVm.notifications.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('Chưa có thông báo mới.')),
                )
              else
                ...settingsVm.notifications.take(5).map(
                  (notification) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primaryContainer,
                      child: Icon(
                        Icons.notifications_active_outlined,
                        color: AppColors.onPrimary,
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
                      await settingsVm.enableNotifications();
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
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
          icon: Icon(
            Icons.bookmark_outline_rounded,
            color: color,
            size: 24,
          ),
          tooltip: 'Danh sách mong muốn',
          onPressed: onPressed,
        ),
        if (count > 0)
          Positioned(
            right: 7,
            top: 7,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
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
