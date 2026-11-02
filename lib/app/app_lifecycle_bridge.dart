import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_notification_item.dart';
import '../models/notification_target.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app.dart';

/// App-wide lifecycle hooks. Sits below the providers.
/// - On resume, reloads the notification history, since the background isolate may
///   have saved messages while the app was not in front.
/// - Shows a SnackBar for FCM messages received while the app is open.
class AppLifecycleBridge extends StatefulWidget {
  const AppLifecycleBridge({super.key, required this.child});

  final Widget child;

  @override
  State<AppLifecycleBridge> createState() => _AppLifecycleBridgeState();
}

class _AppLifecycleBridgeState extends State<AppLifecycleBridge> {
  late final AppLifecycleListener _lifecycle;
  late final NotificationService _notifications;
  StreamSubscription<AppNotificationItem>? _foregroundSubscription;

  @override
  void initState() {
    super.initState();
    _notifications = context.read<NotificationService>();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
    _foregroundSubscription = _notifications.foregroundMessages.listen(
      _showMessage,
    );
  }

  void _onResume() {
    unawaited(_notifications.reload());
  }

  void _showMessage(AppNotificationItem item) {
    final target = NotificationRoute.targetFor(
      item.data,
      saleRemindersEnabled: _notifications.saleRemindersEnabled,
    );
    appScaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textOnDark,
                ),
              ),
              if (item.body.isNotEmpty)
                Text(
                  item.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textOnDark,
                  ),
                ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          // With an action, SnackBars otherwise stay until dismissed
          persist: false,
          action: target == NotificationTarget.none
              ? null
              : SnackBarAction(
                  label: 'Xem',
                  onPressed: () => openFromNotification(item.data),
                ),
        ),
      );
  }

  @override
  void dispose() {
    _foregroundSubscription?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
