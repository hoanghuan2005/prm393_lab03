import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

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

  /// Custom key holding the route the user was on when an error happened
  static const String screenKey = 'screen';

  /// Keeps [screenKey] in sync with the current named route
  NavigatorObserver get screenObserver => _ScreenKeyObserver(this);

  /// Crash reports are tied to the Firebase uid only (never email); '' clears it on sign-out
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
      debugPrint(
        'Handled error (Crashlytics unavailable on this platform): $error',
      );
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
      debugPrint(
        'forceCrashForTesting skipped: Crashlytics is only available on Android/iOS',
      );
      return;
    }
    _crashlytics.setCustomKey(
      'test_scenario',
      'lab3_verification_forced_crash',
    );
    _crashlytics.crash();
  }
}

class _ScreenKeyObserver extends NavigatorObserver {
  final CrashlyticsService _service;

  _ScreenKeyObserver(this._service);

  void _report(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name == null) return; // dialogs and sheets keep the screen underneath
    unawaited(_service.setCustomKey(CrashlyticsService.screenKey, name));
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _report(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _report(previousRoute);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _report(newRoute);
}
