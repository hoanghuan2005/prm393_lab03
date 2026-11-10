import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../core/errors/firebase_error_mapper.dart' show signInCancelled;
import '../core/formatters/email_format.dart';
import '../firebase/platform_support.dart';
import '../services/auth_service.dart';
import '../services/crashlytics_service.dart';
import '../services/user_service.dart';
import 'deferred_notify.dart';
import 'error_reporting.dart';

enum LinkState { notLinked, linked, busy }

/// One row of "Tài khoản liên kết": Google, Facebook or GitHub.
class LinkedAccountRow {
  final String providerId;
  final LinkState state;

  /// Masked email or provider name; null when not linked.
  final String? label;

  final bool canUnlink;

  const LinkedAccountRow({
    required this.providerId,
    required this.state,
    this.label,
    this.canUnlink = false,
  });
}

/// "Tài khoản liên kết": link / unlink Google, Facebook and GitHub.
class LinkedAccountsViewModel extends ChangeNotifier
    with DeferredNotify, ErrorReporting {
  static const googleId = 'google.com';
  static const facebookId = 'facebook.com';
  static const githubId = 'github.com';

  final AuthService authService;
  final UserService userService;
  @override
  final CrashlyticsService? crashlyticsService;

  /// False where Google / GitHub sign-in has no plugin (Windows): the section is hidden
  final bool isAvailable;

  StreamSubscription<User?>? _subscription;
  String? _uid;
  String? _busyProviderId;
  String? _errorMessage;
  String? _successMessage;

  LinkedAccountsViewModel({
    required this.authService,
    required this.userService,
    this.crashlyticsService,
    bool? isAvailable,
  }) : isAvailable = isAvailable ?? PlatformSupport.supportsGoogleSignIn {
    // userChanges also fires on link / unlink, authStateChanges does not
    _subscription = authService.userChanges.listen((_) {
      if (!isDisposed) notifyListeners();
    });
  }

  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get isBusy => _busyProviderId != null;

  bool get isGuest => authService.currentUser?.isAnonymous ?? false;

  /// Display names of linked providers, in row order.
  List<String> get linkedProviderNames => [
    for (final id in const [googleId, facebookId, githubId])
      if (_info(id) != null) _providerName(id),
  ];

  List<LinkedAccountRow> get rows => [
    rowFor(googleId),
    if (PlatformSupport.supportsFacebookSignIn) rowFor(facebookId),
    rowFor(githubId),
  ];

  LinkedAccountRow rowFor(String providerId) {
    if (_busyProviderId == providerId) {
      return LinkedAccountRow(providerId: providerId, state: LinkState.busy);
    }
    final info = _info(providerId);
    if (info == null) {
      return LinkedAccountRow(
        providerId: providerId,
        state: LinkState.notLinked,
      );
    }
    return LinkedAccountRow(
      providerId: providerId,
      state: LinkState.linked,
      label: _labelFor(providerId, info),
      canUnlink: canUnlink(providerId),
    );
  }

  /// Counts every provider (password, phone, ...), including those not shown.
  bool canUnlink(String providerId) {
    final user = authService.currentUser;
    if (user == null || isGuest) return false;
    final linked = authService.linkedProviderIds;
    return linked.contains(providerId) && linked.length > 1;
  }

  void updateUid(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _busyProviderId = null;
    _errorMessage = null;
    _successMessage = null;
    notifyLater();
  }

  /// Called by the screen after showing a message
  void clearMessages() {
    if (_errorMessage == null && _successMessage == null) return;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<bool> linkGoogle() => _run(
    googleId,
    'link_google',
    authService.linkGoogle,
    success: 'Đã liên kết Google.',
    isLink: true,
  );

  Future<bool> linkGithub() => _run(
    githubId,
    'link_github',
    authService.linkGithub,
    success: 'Đã liên kết GitHub.',
    isLink: true,
  );

  Future<bool> linkFacebook() => _run(
    facebookId,
    'link_facebook',
    authService.linkFacebook,
    success: 'Đã liên kết Facebook.',
    isLink: true,
  );

  Future<bool> unlink(String providerId) => _run(
    providerId,
    'unlink',
    () async {
      await authService.unlink(providerId);
      return true;
    },
    success: 'Đã huỷ liên kết ${_providerName(providerId)}.',
    isLink: false,
  );

  /// Runs one action at a time; a cancelled link (null or sign-in-cancelled) is not an error
  Future<bool> _run(
    String providerId,
    String authMethod,
    Future<Object?> Function() action, {
    required String success,
    required bool isLink,
  }) async {
    if (isBusy) return false;
    _busyProviderId = providerId;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      final result = await action();
      if (result == null) return false;
      if (isLink) await _syncUserDocument(providerId);
      _successMessage = success;
      return true;
    } on UnsupportedError {
      _errorMessage =
          'Liên kết ${_providerName(providerId)} chưa hỗ trợ trên Windows.';
      return false;
    } catch (e, stack) {
      if (e is AppException && e.code == signInCancelled.code) return false;
      _errorMessage = messageFor(
        e,
        stack,
        reason: '$authMethod error',
        customKeys: {'auth_method': authMethod},
      );
      return false;
    } finally {
      _busyProviderId = null;
      if (!isDisposed) notifyListeners();
    }
  }

  /// A guest who links becomes a full account; fill the name from the provider if empty.
  /// The link itself already succeeded, so a failure here is only reported.
  Future<void> _syncUserDocument(String providerId) async {
    final uid = _uid ?? authService.currentUserId;
    final user = authService.currentUser;
    if (uid == null || user == null) return;
    final info = _info(providerId);
    try {
      await userService.ensureUserDocument(
        uid,
        displayName: user.displayName ?? info?.displayName,
        email: user.email ?? info?.email,
        isAnonymous: false,
      );
    } catch (e, stack) {
      messageFor(e, stack, reason: 'ensureUserDocument after link');
    }
  }

  UserInfo? _info(String providerId) {
    for (final info
        in authService.currentUser?.providerData ?? const <UserInfo>[]) {
      if (info.providerId == providerId) return info;
    }
    return null;
  }

  String? _labelFor(String providerId, UserInfo info) {
    if (providerId == facebookId) {
      final name = info.displayName?.trim();
      if (name != null && name.isNotEmpty) return name;
      final email = info.email;
      return email == null || email.isEmpty
          ? 'Chưa có email'
          : maskEmail(email);
    }
    if (providerId == googleId) {
      final email = info.email;
      return email == null || email.isEmpty ? null : maskEmail(email);
    }
    final name = info.displayName;
    return name == null || name.isEmpty ? null : name;
  }

  String _providerName(String providerId) => switch (providerId) {
    facebookId => 'Facebook',
    githubId => 'GitHub',
    _ => 'Google',
  };

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
