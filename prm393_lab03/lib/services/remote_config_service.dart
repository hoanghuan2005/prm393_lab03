import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import '../core/errors/describe_error.dart';
import '../firebase/platform_support.dart';

/// Service abstraction for Firebase Remote Config
class RemoteConfigService {
  /// Provided via constructor for testing, otherwise assigned lazily in [initialize].
  final FirebaseRemoteConfig? _injectedConfig;
  FirebaseRemoteConfig get _remoteConfig =>
      _injectedConfig ?? FirebaseRemoteConfig.instance;

  RemoteConfigService({FirebaseRemoteConfig? remoteConfig})
    : _injectedConfig = remoteConfig;

  /// Keys matching firebase/remote-config-defaults.json
  static const String keyCoolingOffDays = 'cooling_off_days';
  static const String keyEnableAiInsight = 'enable_ai_insight';
  static const String keyMaxWishlistItems = 'max_wishlist_items_shown';
  static const String keySaleReminderEnabled = 'sale_reminder_enabled';
  static const String keyAiInsightModel = 'ai_insight_model';

  /// "Chụp để tìm" needs a stronger model than the Lite one used for wording: it
  /// must read logos and model numbers. Empty in the console = the default below.
  static const String keyAiPhotoSearchModel = 'ai_photo_search_model';
  static const String keyEnableAiSuggestions = 'enable_ai_suggestions';
  static const String keySaleCalendar = 'sale_calendar';

  /// "Chụp để tìm" → AI looks up shop prices with Google Search. Off by default:
  /// grounding is not in the free Gemini tier, so turn it on only after billing is set up.
  static const String keyEnableAiPriceSearch = 'enable_ai_price_search';

  /// JSON object {feature: system instruction} (feature names: AiFeatures). A feature
  /// left out, or `{}`, keeps the instruction built into the app. The app still checks
  /// every reply (numbers, banned words, length), whatever the prompt says.
  static const String keyAiPrompts = 'ai_prompts';

  /// Announced sales (spec 8.2); the team keeps this list in the console. 11.11 is the
  /// spec's confirmed example; other days of the public pattern appear as "dự kiến".
  static const String defaultSaleCalendar =
      '[{"date":"2026-11-11","name":"11.11","type":"double_day","confirmed":true}]';

  /// In-app default values matching firebase/remote-config-defaults.json.
  /// Also served directly on platforms without Remote Config (web/Windows).
  static const Map<String, Object> defaults = {
    keyCoolingOffDays: 3,
    keyEnableAiInsight: true,
    keyMaxWishlistItems: 20,
    keySaleReminderEnabled: true,
    keyAiInsightModel: 'gemini-3.5-flash-lite',
    keyAiPhotoSearchModel: 'gemini-3.5-flash',
    keyEnableAiSuggestions: true,
    keySaleCalendar: defaultSaleCalendar,
    keyEnableAiPriceSearch: false,
    keyAiPrompts: '{}',
  };

  bool get _isSupported =>
      _injectedConfig != null || PlatformSupport.supportsRemoteConfig;

  /// Initialize and fetch Remote Config
  Future<void> initialize() async {
    if (!_isSupported) {
      debugPrint(
        'RemoteConfig skipped (no Remote Config plugin on this platform), using local defaults',
      );
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
      debugPrint(
        'RemoteConfig initialized successfully. cooling_off_days: $coolingOffDays, ai_enabled: $enableAiInsight',
      );
    } catch (e) {
      debugPrint('RemoteConfig initialize error: ${describeError(e)}');
    }
  }

  /// Cooling off duration in days (changes cooldown timer calculation)
  int get coolingOffDays => _getInt(keyCoolingOffDays);

  /// Feature flag for AI Insights screen / card
  bool get enableAiInsight => _getBool(keyEnableAiInsight);

  /// AI help when adding an item (budget group, possible duplicates)
  bool get enableAiSuggestions => _getBool(keyEnableAiSuggestions);

  /// AI shop-price lookup in "Chụp để tìm" (needs paid Gemini grounding)
  bool get enableAiPriceSearch => _getBool(keyEnableAiPriceSearch);

  /// JSON list of sales for Lịch sale (see SaleCalendar.parse)
  String get saleCalendarJson {
    final value = _isSupported ? _remoteConfig.getString(keySaleCalendar) : '';
    return value.trim().isNotEmpty ? value : defaultSaleCalendar;
  }

  /// Maximum wishlist items to show
  int get maxWishlistItems => _getInt(keyMaxWishlistItems);

  /// Whether sale reminders are enabled
  bool get saleReminderEnabled => _getBool(keySaleReminderEnabled);

  /// Gemini model used for Góc nhìn wording; switchable from the console when a model is retired
  String get aiInsightModel {
    final value = _isSupported
        ? _remoteConfig.getString(keyAiInsightModel)
        : '';
    return value.isNotEmpty ? value : defaults[keyAiInsightModel] as String;
  }

  /// Gemini model for "Chụp để tìm" (photo recognition)
  String get aiPhotoSearchModel {
    final value = _isSupported
        ? _remoteConfig.getString(keyAiPhotoSearchModel)
        : '';
    return value.isNotEmpty ? value : defaults[keyAiPhotoSearchModel] as String;
  }

  String? _promptsRaw;
  Map<String, String> _prompts = const {};

  /// System instruction for an AI feature set in the console; null = built-in one
  String? aiPromptFor(String feature) {
    final raw = _isSupported ? _remoteConfig.getString(keyAiPrompts) : '';
    if (raw != _promptsRaw) {
      _promptsRaw = raw;
      _prompts = _parsePrompts(raw);
    }
    return _prompts[feature];
  }

  static Map<String, String> _parsePrompts(String raw) {
    if (raw.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      return {
        for (final e in decoded.entries)
          if (e.key is String &&
              e.value is String &&
              (e.value as String).trim().isNotEmpty)
            e.key as String: (e.value as String).trim(),
      };
    } on FormatException catch (e) {
      debugPrint('ai_prompts is not valid JSON: $e');
      return const {};
    }
  }

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
