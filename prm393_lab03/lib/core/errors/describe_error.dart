import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

import 'app_exception.dart';

/// Type and code only, never the message: messages can carry emails or user data
String describeError(Object? error) {
  if (error is AppException) {
    final cause = error.cause;
    final base = 'AppException(${error.code})';
    return cause == null ? base : '$base <- ${describeError(cause)}';
  }
  if (error is FirebaseException) return '${error.runtimeType}(${error.code})';
  if (error is PlatformException) return 'PlatformException(${error.code})';
  return '${error.runtimeType}';
}
