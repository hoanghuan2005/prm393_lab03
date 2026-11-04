import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../services/crashlytics_service.dart';

/// Turns any error caught in a ViewModel into a message for the UI.
/// AppException (already mapped by the services) → its Vietnamese message;
/// anything else is unexpected → recorded in Crashlytics + generic message.
mixin ErrorReporting {
  static const String genericMessage = 'Đã có lỗi, vui lòng thử lại.';

  CrashlyticsService? get crashlyticsService;

  String messageFor(Object error, StackTrace? stack, {required String reason}) {
    if (error is AppException) return error.messageVi;
    final crashlytics = crashlyticsService;
    if (crashlytics != null) {
      unawaited(crashlytics.recordHandledError(error, stack, reason: reason));
    } else {
      debugPrint('$reason: $error');
    }
    return genericMessage;
  }
}
