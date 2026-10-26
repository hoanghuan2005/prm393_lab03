import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import '../firebase/platform_support.dart';

/// Service abstraction for Firebase Crashlytics
class CrashlyticsService {
  final FirebaseCrashlytics? _providedCrashlytics;

  CrashlyticsService({FirebaseCrashlytics? crashlytics})
      : _providedCrashlytics = crashlytics;

  FirebaseCrashlytics get _crashlytics =>
      _providedCrashlytics ?? FirebaseCrashlytics.instance;

  /// Initialize Crashlytics handlers
  void initCrashlyticsHandlers() {
    // Crashlytics is mobile-only; accessing it on web/Windows throws and aborts main().
    if (!PlatformSupport.isMobile) return;
    FlutterError.onError = _crashlytics.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }

  /// Set User ID for crash reporting
  Future<void> setUserId(String userId) async {
    if (!PlatformSupport.isMobile) return;
    try {
      await _crashlytics.setUserIdentifier(userId);
    } catch (e) {
      debugPrint('Crashlytics setUserId error: $e');
    }
  }

  /// Attach a custom key-value pair to crash reports
  Future<void> setCustomKey(String key, Object value) async {
    if (!PlatformSupport.isMobile) return;
    try {
      await _crashlytics.setCustomKey(key, value);
    } catch (e) {
      debugPrint('Crashlytics setCustomKey error: $e');
    }
  }

  /// Report a handled (non-fatal) error with custom keys
  Future<void> recordHandledError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, Object>? customKeys,
  }) async {
    if (!PlatformSupport.isMobile) {
      debugPrint('Handled error (Crashlytics unavailable on this platform): $error');
      return;
    }
    try {
      if (customKeys != null) {
        for (final entry in customKeys.entries) {
          await _crashlytics.setCustomKey(entry.key, entry.value);
        }
      }
      await _crashlytics.recordError(
        error,
        stackTrace,
        reason: reason ?? 'Handled non-fatal error in app workflow',
        fatal: false,
      );
      debugPrint('Crashlytics logged non-fatal error: $reason');
    } catch (e) {
      debugPrint('Crashlytics recordHandledError error: $e');
    }
  }

  /// Trigger a test crash for verification per Lab 3 requirement
  void forceCrashForTesting() {
    if (!PlatformSupport.isMobile) {
      debugPrint('forceCrashForTesting skipped: Crashlytics is only available on Android/iOS');
      return;
    }
    _crashlytics.setCustomKey('test_scenario', 'lab3_verification_forced_crash');
    _crashlytics.crash();
  }
}
