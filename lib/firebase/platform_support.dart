import 'package:flutter/foundation.dart';

/// Which Firebase features are available on the current platform.
///
/// Crashlytics, Messaging, Analytics and Remote Config only ship native
/// implementations for Android/iOS. On web and Windows the services fall back
/// to no-ops / local defaults so every screen behaves the same everywhere.
class PlatformSupport {
  PlatformSupport._();

  static bool get isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Google Sign-In: native SDK on mobile, Firebase popup on web.
  /// Not available on Windows desktop.
  static bool get supportsGoogleSignIn => isMobile || kIsWeb;
}
