import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service interfacing with native Android [FloatingBubbleService] via MethodChannel.
class FloatingBubbleService {
  static const MethodChannel _channel = MethodChannel(
    'com.group07.whyibuy/floating_bubble',
  );

  /// Checks if the app has `SYSTEM_ALERT_WINDOW` (display over other apps) permission.
  static Future<bool> checkOverlayPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final bool? hasPerm = await _channel.invokeMethod<bool>(
        'checkOverlayPermission',
      );
      return hasPerm ?? false;
    } on PlatformException catch (e) {
      debugPrint('FloatingBubbleService.checkOverlayPermission error: $e');
      return false;
    }
  }

  /// Opens Android System Settings to grant "Display over other apps" permission.
  static Future<bool> requestOverlayPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final bool? ok = await _channel.invokeMethod<bool>(
        'requestOverlayPermission',
      );
      return ok ?? false;
    } on PlatformException catch (e) {
      debugPrint('FloatingBubbleService.requestOverlayPermission error: $e');
      return false;
    }
  }

  /// Starts the floating bubble overlay service.
  static Future<bool> startFloatingBubble() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final bool? started = await _channel.invokeMethod<bool>(
        'startFloatingBubble',
      );
      return started ?? false;
    } on PlatformException catch (e) {
      debugPrint('FloatingBubbleService.startFloatingBubble error: $e');
      return false;
    }
  }

  /// Stops the floating bubble overlay service.
  static Future<bool> stopFloatingBubble() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final bool? stopped = await _channel.invokeMethod<bool>(
        'stopFloatingBubble',
      );
      return stopped ?? false;
    } on PlatformException catch (e) {
      debugPrint('FloatingBubbleService.stopFloatingBubble error: $e');
      return false;
    }
  }

  /// Checks if the native bubble service is currently active.
  static Future<bool> isBubbleRunning() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final bool? running = await _channel.invokeMethod<bool>(
        'isBubbleRunning',
      );
      return running ?? false;
    } on PlatformException catch (e) {
      debugPrint('FloatingBubbleService.isBubbleRunning error: $e');
      return false;
    }
  }

  /// Triggers a test alert banner on the floating bubble (for demo/testing).
  static Future<bool> showTestAlert({
    String url = 'https://shopee.vn/product/demo-sale-1111',
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final bool? ok = await _channel.invokeMethod<bool>('showTestAlert', {
        'url': url,
      });
      return ok ?? false;
    } on PlatformException catch (e) {
      debugPrint('FloatingBubbleService.showTestAlert error: $e');
      return false;
    }
  }

  /// Checks if the Accessibility Service for lingering/hesitation detection is turned on.
  static Future<bool> isAccessibilityServiceEnabled() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final bool? enabled = await _channel.invokeMethod<bool>(
        'isAccessibilityServiceEnabled',
      );
      return enabled ?? false;
    } on PlatformException catch (e) {
      debugPrint('FloatingBubbleService.isAccessibilityServiceEnabled error: $e');
      return false;
    }
  }

  /// Opens Android Accessibility Settings page so user can turn on the Why I Buy service.
  static Future<bool> openAccessibilitySettings() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final bool? ok = await _channel.invokeMethod<bool>(
        'openAccessibilitySettings',
      );
      return ok ?? false;
    } on PlatformException catch (e) {
      debugPrint('FloatingBubbleService.openAccessibilitySettings error: $e');
      return false;
    }
  }

  /// Triggers a test lingering alert with pulse breathing animation and wake-up prompt.
  static Future<bool> showTestLingeringAlert({
    String title = 'Tai nghe không dây Bluetooth chống ồn',
    String price = '120.000 đ',
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final bool? ok = await _channel.invokeMethod<bool>(
        'showTestLingeringAlert',
        {
          'title': title,
          'price': price,
        },
      );
      return ok ?? false;
    } on PlatformException catch (e) {
      debugPrint('FloatingBubbleService.showTestLingeringAlert error: $e');
      return false;
    }
  }
}

