import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../services/notification_service.dart';

/// App-wide lifecycle hooks. Sits below the providers.
/// On resume, reloads the notification history, since the background isolate may
/// have saved messages while the app was not in front.
class AppLifecycleBridge extends StatefulWidget {
  const AppLifecycleBridge({super.key, required this.child});

  final Widget child;

  @override
  State<AppLifecycleBridge> createState() => _AppLifecycleBridgeState();
}

class _AppLifecycleBridgeState extends State<AppLifecycleBridge> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
  }

  void _onResume() {
    unawaited(context.read<NotificationService>().reload());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
