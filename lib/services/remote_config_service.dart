import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import '../firebase/platform_support.dart';

/// Service abstraction for Firebase Remote Config
class RemoteConfigService {
  /// Provided via constructor for testing, otherwise assigned lazily in [initialize].
  final FirebaseRemoteConfig? _injectedConfig;
  FirebaseRemoteConfig get _remoteConfig => _injectedConfig ?? FirebaseRemoteConfig.instance;

  RemoteConfigService({FirebaseRemoteConfig? remoteConfig})
      : _injectedConfig = remoteConfig;

  /// Keys matching firebase/remote-config-defaults.json
  static const String keyCoolingOffDays = 'cooling_off_days';
  static const String keyEnableAiInsight = 'enable_ai_insight';
  static const String keyMaxWishlistItems = 'max_wishlist_items_shown';
  static const String keySaleReminderEnabled = 'sale_reminder_enabled';

  /// In-app default values matching firebase/remote-config-defaults.json.
  /// Also served directly on platforms without Remote Config (web/Windows).
  static const Map<String, Object> defaults = {
    keyCoolingOffDays: 3,
    keyEnableAiInsight: true,
    keyMaxWishlistItems: 20,
    keySaleReminderEnabled: true,
  };

  bool get _isSupported => _injectedConfig != null || PlatformSupport.isMobile;

  /// Initialize and fetch Remote Config
  Future<void> initialize() async {
    if (!_isSupported) {
      debugPrint('RemoteConfig skipped (only available on Android/iOS), using local defaults');
      return;
    }
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          // Set minimumFetchInterval to 0 in development for real-time live changes
          minimumFetchInterval: const Duration(seconds: 0),
        ),
      );

      await _remoteConfig.setDefaults(defaults);

      // Fetch and activate
      await _remoteConfig.fetchAndActivate();
      debugPrint('RemoteConfig initialized successfully. cooling_off_days: $coolingOffDays, ai_enabled: $enableAiInsight');
    } catch (e) {
      debugPrint('RemoteConfig initialize error: $e');
    }
  }

  /// Cooling off duration in days (changes cooldown timer calculation)
  int get coolingOffDays => _getInt(keyCoolingOffDays);

  /// Feature flag for AI Insights screen / card
  bool get enableAiInsight => _getBool(keyEnableAiInsight);

  /// Maximum wishlist items to show
  int get maxWishlistItems => _getInt(keyMaxWishlistItems);

  /// Whether sale reminders are enabled
  bool get saleReminderEnabled => _getBool(keySaleReminderEnabled);

  int _getInt(String key) =>
      _isSupported ? _remoteConfig.getInt(key) : defaults[key] as int;

  bool _getBool(String key) =>
      _isSupported ? _remoteConfig.getBool(key) : defaults[key] as bool;

  /// Force fetch to test live changes without rebuild
  Future<bool> fetchAndActivate() async {
    if (!_isSupported) return false;
    return await _remoteConfig.fetchAndActivate();
  }
}
