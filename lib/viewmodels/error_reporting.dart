import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../core/errors/describe_error.dart';
import '../services/crashlytics_service.dart';

/// Turns any error caught in a ViewModel into a message for the UI.
/// AppException (already mapped by the services) → its Vietnamese message;
/// one with a cause (unknown or unmapped) is also recorded in Crashlytics.
/// Anything else is unexpected → recorded in Crashlytics + generic message.
mixin ErrorReporting {
  static const String genericMessage = 'Đã có lỗi, vui lòng thử lại.';

  CrashlyticsService? get crashlyticsService;

  String messageFor(
    Object error,
    StackTrace? stack, {
    required String reason,
    Map<String, Object>? customKeys,
  }) {
    if (error is AppException && error.cause == null) return error.messageVi;
    final crashlytics = crashlyticsService;
    if (crashlytics != null) {
      unawaited(
        recordError(
          crashlytics,
          error,
          stack,
          reason: reason,
          customKeys: customKeys,
        ),
      );
    } else if (kDebugMode) {
      debugPrint('$reason: ${describeError(error)}');
    }
    return error is AppException ? error.messageVi : genericMessage;
  }
}

/// Records [error] as non-fatal; an AppException with a cause records the cause
/// plus custom key 'error_code'
Future<void> recordError(
  CrashlyticsService crashlytics,
  Object error,
  StackTrace? stack, {
  required String reason,
  Map<String, Object>? customKeys,
}) {
  if (error is AppException && error.cause != null) {
    return crashlytics.recordHandledError(
      error.cause,
      stack,
      reason: reason,
      customKeys: {...?customKeys, 'error_code': error.code},
    );
  }
  return crashlytics.recordHandledError(
    error,
    stack,
    reason: reason,
    customKeys: customKeys,
  );
}
