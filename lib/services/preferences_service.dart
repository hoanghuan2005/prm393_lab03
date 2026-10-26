import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-device user settings stored locally
class PreferencesService {
  static const String _keyAiInsightEnabled = 'ai_insight_enabled';

  /// Whether the user allows AI-written insights (spec 7.6: user can turn AI on/off). Defaults to on.
  Future<bool> getAiInsightEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyAiInsightEnabled) ?? true;
    } catch (e) {
      debugPrint('PreferencesService getAiInsightEnabled error: $e');
      return true;
    }
  }

  Future<void> setAiInsightEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAiInsightEnabled, enabled);
    } catch (e) {
      debugPrint('PreferencesService setAiInsightEnabled error: $e');
    }
  }
}
