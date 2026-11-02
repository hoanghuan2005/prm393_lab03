import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-device user settings stored locally
class PreferencesService {
  static const String _keyAiInsightEnabled = 'ai_insight_enabled';
  static const String _keyDailyReminderEnabled = 'daily_reminder_enabled';
  static const String _keyDailyReminderMinutes = 'daily_reminder_minutes';
  static const String _keyDailyReminderOffered = 'daily_reminder_offered';
  static const String _keySaleReminderLevel = 'sale_reminder_level';

  /// 21:00, the time shown on screen 05a
  static const int defaultDailyReminderMinutes = 21 * 60;

  /// Whether the user allows AI-written insights (spec 7.6: user can turn AI on/off). Defaults to on.
  Future<bool> getAiInsightEnabled() =>
      _read((p) => p.getBool(_keyAiInsightEnabled) ?? true, true);

  Future<void> setAiInsightEnabled(bool enabled) =>
      _write((p) => p.setBool(_keyAiInsightEnabled, enabled));

  /// "Nhắc ghi khoản mua" (screen 05a, Cá nhân). Local notifications live on this
  /// device, so the choice is stored here rather than on the account. Off by default.
  Future<bool> getDailyReminderEnabled() =>
      _read((p) => p.getBool(_keyDailyReminderEnabled) ?? false, false);

  Future<void> setDailyReminderEnabled(bool enabled) =>
      _write((p) => p.setBool(_keyDailyReminderEnabled, enabled));

  /// Minutes after midnight (0–1439)
  Future<int> getDailyReminderMinutes() => _read(
    (p) => (p.getInt(_keyDailyReminderMinutes) ?? defaultDailyReminderMinutes)
        .clamp(0, 24 * 60 - 1),
    defaultDailyReminderMinutes,
  );

  Future<void> setDailyReminderMinutes(int minutes) =>
      _write((p) => p.setInt(_keyDailyReminderMinutes, minutes));

  /// Screen 05a has been shown once on this device
  Future<bool> getDailyReminderOffered() =>
      _read((p) => p.getBool(_keyDailyReminderOffered) ?? false, false);

  Future<void> setDailyReminderOffered() =>
      _write((p) => p.setBool(_keyDailyReminderOffered, true));

  /// "Nhắc đợt sale" (spec 8.2): `off` · `big_only` (default) · `all`. Stored on this
  /// device, like every local notification setting.
  Future<String> getSaleReminderLevel() => _read(
    (p) => p.getString(_keySaleReminderLevel) ?? 'big_only',
    'big_only',
  );

  Future<void> setSaleReminderLevel(String level) =>
      _write((p) => p.setString(_keySaleReminderLevel, level));

  Future<T> _read<T>(T Function(SharedPreferences) read, T fallback) async {
    try {
      return read(await SharedPreferences.getInstance());
    } catch (e) {
      debugPrint('PreferencesService read error: $e');
      return fallback;
    }
  }

  Future<void> _write(Future<bool> Function(SharedPreferences) write) async {
    try {
      await write(await SharedPreferences.getInstance());
    } catch (e) {
      debugPrint('PreferencesService write error: $e');
    }
  }
}
