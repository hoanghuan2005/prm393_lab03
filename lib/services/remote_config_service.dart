import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Service abstraction for Firebase Remote Config
class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;

  RemoteConfigService({FirebaseRemoteConfig? remoteConfig})
      : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  /// Keys matching firebase/remote-config-defaults.json
  static const String keyCoolingOffDays = 'cooling_off_days';
  static const String keyEnableAiInsight = 'enable_ai_insight';
  static const String keyMaxWishlistItems = 'max_wishlist_items_shown';
  static const String keySaleReminderEnabled = 'sale_reminder_enabled';

  /// Initialize and fetch Remote Config
  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          // Set minimumFetchInterval to 0 in development for real-time live changes
          minimumFetchInterval: const Duration(seconds: 0),
        ),
      );

      // In-app default values matching firebase/remote-config-defaults.json
      await _remoteConfig.setDefaults(const {
        keyCoolingOffDays: 3,
        keyEnableAiInsight: true,
        keyMaxWishlistItems: 20,
        keySaleReminderEnabled: true,
      });

      // Fetch and activate
      await _remoteConfig.fetchAndActivate();
      debugPrint('RemoteConfig initialized successfully. cooling_off_days: $coolingOffDays, ai_enabled: $enableAiInsight');
    } catch (e) {
      debugPrint('RemoteConfig initialize error: $e');
    }
  }

  /// Cooling off duration in days (changes cooldown timer calculation)
  int get coolingOffDays => _remoteConfig.getInt(keyCoolingOffDays);

  /// Feature flag for AI Insights screen / card
  bool get enableAiInsight => _remoteConfig.getBool(keyEnableAiInsight);

  /// Maximum wishlist items to show
  int get maxWishlistItems => _remoteConfig.getInt(keyMaxWishlistItems);

  /// Whether sale reminders are enabled
  bool get saleReminderEnabled => _remoteConfig.getBool(keySaleReminderEnabled);

  /// Force fetch to test live changes without rebuild
  Future<bool> fetchAndActivate() async {
    return await _remoteConfig.fetchAndActivate();
  }
}
