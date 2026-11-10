import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../core/errors/describe_error.dart';
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
    if (!PlatformSupport.supportsCrashlytics) return;
    FlutterError.onError = (details) {
      FlutterError.dumpErrorToConsole(details);
      _crashlytics.recordFlutterFatalError(details);
    };
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
    if (!PlatformSupport.supportsCrashlytics) return;
    try {
      await _crashlytics.setUserIdentifier(userId);
    } catch (e) {
      debugPrint('Crashlytics setUserId error: ${describeError(e)}');
    }
  }

  /// Attach a custom key-value pair to crash reports
  Future<void> setCustomKey(String key, Object value) async {
    if (!PlatformSupport.supportsCrashlytics) return;
    try {
      await _crashlytics.setCustomKey(key, value);
    } catch (e) {
      debugPrint('Crashlytics setCustomKey error: ${describeError(e)}');
    }
  }

  /// Report a handled (non-fatal) error with custom keys
  Future<void> recordHandledError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, Object>? customKeys,
  }) async {
    if (!PlatformSupport.supportsCrashlytics) {
      if (kDebugMode) {
        debugPrint(
          'Handled error (Crashlytics unavailable on this platform): '
          '${describeError(error)}',
        );
      }
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
      debugPrint('Crashlytics recordHandledError error: ${describeError(e)}');
    }
  }

  /// Trigger a test crash for verification per Lab 3 requirement
  void forceCrashForTesting() {
    if (!PlatformSupport.supportsCrashlytics) {
      debugPrint(
        'forceCrashForTesting skipped: Crashlytics has no SDK on this platform',
      );
      return;
    }
    _crashlytics.setCustomKey(
      'test_scenario',
      'lab3_verification_forced_crash',
    );
    _crashlytics.crash();
  }

  /// Log a crash or error event to Firestore so Admin Web dashboard can monitor it in real time
  Future<void> logCrashToFirestore({
    required String feature,
    required String errorCode,
    required String errorMessage,
    String? stackTrace,
    String severity = 'fatal',
    String? userId,
  }) async {
    try {
      final now = DateTime.now();
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final dateStr =
          '${now.year}-${twoDigits(now.month)}-${twoDigits(now.day)} '
          '${twoDigits(now.hour)}:${twoDigits(now.minute)}:${twoDigits(now.second)}';

      final docRef = FirebaseFirestore.instance.collection('crashes').doc();
      await docRef.set({
        'id': docRef.id,
        'feature': feature,
        'errorCode': errorCode,
        'errorMessage': errorMessage,
        'stackTrace': stackTrace ?? '',
        'severity': severity,
        'affectedUsers': 1,
        'occurrences': 1,
        'lastOccurred': dateStr,
        'appVersion': '1.0.0+3',
        'platform': defaultTargetPlatform.name,
        'userId': userId ?? 'anonymous',
        'isResolved': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Logged crash report to Firestore: ${docRef.id}');
    } catch (e) {
      debugPrint('Failed to log crash to Firestore: $e');
    }
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
