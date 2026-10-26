import 'dart:convert';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// App Check attests requests to Firebase AI Logic, which is enforced in the console.
class AppCheckSetup {
  AppCheckSetup._();

  /// Fraud Defense (reCAPTCHA Enterprise) site key registered for the web app. Public by design.
  static const String webSiteKey = '6LfqQQEuAAAAABRHj6KthKFR3Zf7zqV3u3z4h4YO';

  /// Git-ignored file holding the team debug token registered in
  /// App Check → Manage debug tokens (Android and Web app): {"APP_CHECK_DEBUG_TOKEN": "uuid"}
  static const String tokenAsset = 'assets/local/app_check.json';

  /// Optional override: flutter run --dart-define-from-file=app_check.local.json
  static const String _definedToken = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN');

  static String _debugToken = _definedToken;

  static bool get hasDebugToken => _debugToken.isNotEmpty;

  /// Play Integrity only accepts apps installed from Google Play, so sideloaded
  /// APKs (QR install) need the debug provider plus a registered token.
  static bool get _useAndroidDebugProvider => kDebugMode || hasDebugToken;

  static Future<String> _loadTokenFromAsset() async {
    try {
      final json = jsonDecode(await rootBundle.loadString(tokenAsset)) as Map<String, dynamic>;
      return (json['APP_CHECK_DEBUG_TOKEN'] as String?)?.trim() ?? '';
    } catch (_) {
      // File not copied on this machine: AI falls back to template sentences
      return '';
    }
  }

  static Future<void> activate() async {
    if (_debugToken.isEmpty) _debugToken = await _loadTokenFromAsset();
    debugPrint('AppCheck debug token: ${hasDebugToken ? 'found' : 'not found ($tokenAsset)'}');

    // Windows has no attestation provider; without a token App Check cannot issue tokens there
    final isWindows = !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
    if (isWindows && !hasDebugToken) return;

    final token = hasDebugToken ? _debugToken : null;
    await FirebaseAppCheck.instance.activate(
      providerAndroid: _useAndroidDebugProvider
          ? AndroidDebugProvider(debugToken: token)
          : const AndroidPlayIntegrityProvider(),
      providerWeb: hasDebugToken ? WebDebugProvider(debugToken: token) : ReCaptchaEnterpriseProvider(webSiteKey),
      providerWindows: WindowsDebugProvider(debugToken: token),
    );
  }
}
