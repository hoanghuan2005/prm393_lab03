import 'package:flutter/foundation.dart';

import 'app_check_setup.dart';

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

  /// Analytics, Remote Config and Cloud Messaging have web SDKs and the web app is
  /// registered in Firebase, so web behaves like Android. Windows has no plugins for them.
  static bool get supportsAnalytics => isMobile || kIsWeb;
  static bool get supportsRemoteConfig => isMobile || kIsWeb;
  static bool get supportsMessaging => isMobile || kIsWeb;

  /// Crashlytics has no web or Windows SDK
  static bool get supportsCrashlytics => isMobile;

  /// Google Sign-In: native SDK on mobile, Firebase popup on web.
  /// Not available on Windows desktop.
  static bool get supportsGoogleSignIn => isMobile || kIsWeb;

  /// Firebase AI Logic (Gemini) requires an App Check token. Windows has no attestation
  /// provider, so it only works with a registered debug token (not officially supported).
  static bool get supportsFirebaseAi =>
      isMobile ||
      kIsWeb ||
      (defaultTargetPlatform == TargetPlatform.windows &&
          AppCheckSetup.hasDebugToken);
}
