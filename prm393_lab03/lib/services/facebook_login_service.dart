import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import '../core/errors/app_exception.dart';
import '../core/errors/firebase_error_mapper.dart';

/// Native Facebook SDK only. Web uses Firebase popup in AuthService.
/// Injectable so tests never open a provider or use real access tokens.
class FacebookLoginService {
  final FacebookAuth? _injectedFacebook;
  final Future<bool> Function()? configured;
  late final FacebookAuth _facebook =
      _injectedFacebook ?? FacebookAuth.instance;

  FacebookLoginService({FacebookAuth? facebook, this.configured})
    : _injectedFacebook = facebook;

  static const _configChannel = MethodChannel(
    'com.group07.whyibuy/facebook_config',
  );
  static const notConfigured = AppException(
    'facebook-not-configured',
    'Đăng nhập Facebook chưa được cấu hình. Bạn có thể dùng cách đăng nhập khác.',
  );
  static const _failed = AppException(
    'facebook-sign-in-failed',
    'Chưa đăng nhập được Facebook. Kiểm tra kết nối mạng rồi thử lại.',
  );

  Future<bool> _isConfigured() async {
    if (configured != null) return configured!();
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      return await _configChannel.invokeMethod<bool>('isConfigured') ?? false;
    } on MissingPluginException {
      return false; // Native configuration needs a rebuild, not just hot reload.
    }
  }

  Future<OAuthCredential?> credential() async {
    if (!await _isConfigured()) throw notConfigured;
    // Limited Login is the default on iOS. Firebase verifies SHA256(rawNonce).
    final random = Random.secure();
    final rawNonce = defaultTargetPlatform == TargetPlatform.iOS
        ? base64UrlEncode(List.generate(32, (_) => random.nextInt(256)))
        : null;
    final LoginResult result;
    try {
      result = await _facebook.login(
        permissions: const ['public_profile', 'email'],
        loginTracking: LoginTracking.limited,
        nonce: rawNonce == null
            ? null
            : sha256.convert(utf8.encode(rawNonce)).toString(),
      );
    } on PlatformException catch (e) {
      if (['CANCELLED', 'CANCELED'].contains(e.code.toUpperCase())) return null;
      if ('${e.code} ${e.message}'.toLowerCase().contains('network')) {
        throw mapFirebaseError(StateError('network'));
      }
      throw _failed;
    }
    if (result.status == LoginStatus.cancelled) return null;
    if (result.status != LoginStatus.success) {
      if ((result.message ?? '').toLowerCase().contains('network')) {
        throw mapFirebaseError(StateError('network'));
      }
      throw _failed;
    }
    final token = result.accessToken;
    if (token == null || token.tokenString.isEmpty) throw _failed;
    if (token is LimitedToken) {
      if (rawNonce == null) throw _failed;
      return OAuthProvider('facebook.com')
          .credential(idToken: token.tokenString, rawNonce: rawNonce);
    }
    return FacebookAuthProvider.credential(token.tokenString);
  }

  Future<void> logOut() => _facebook.logOut();
}
