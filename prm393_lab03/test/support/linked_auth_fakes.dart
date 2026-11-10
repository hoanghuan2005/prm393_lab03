import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/services/auth_service.dart';
import 'package:prm393_lab03/services/crashlytics_service.dart';
import 'package:prm393_lab03/services/user_service.dart';

class FakeUserInfo extends Fake implements UserInfo {
  @override
  final String providerId;
  @override
  final String? email;
  @override
  final String? displayName;

  FakeUserInfo(this.providerId, {this.email, this.displayName});
}

/// User with fixed providers; a guest when [providerData] is empty
class FakeLinkUser extends Fake implements User {
  @override
  final List<UserInfo> providerData;
  @override
  final String? email;

  FakeLinkUser(this.providerData, {this.email});

  /// Top-level name stays empty, as for a guest who just linked
  @override
  String? get displayName => null;

  @override
  bool get isAnonymous => providerData.isEmpty;
}

class _FakeCredential extends Fake implements UserCredential {}

/// AuthService whose link / unlink swap the current user, or fail with [error].
/// While [gate] is set, link and unlink wait for it, to test the busy state.
class FakeLinkAuthService extends Fake implements AuthService {
  final _changes = StreamController<User?>.broadcast();
  User? user;
  Object? error;
  bool cancelLink = false;
  Completer<void>? gate;
  final List<String> unlinked = [];

  /// User returned after a successful link
  User? Function()? afterLink;

  FakeLinkAuthService(this.user);

  @override
  Stream<User?> get userChanges => _changes.stream;

  @override
  User? get currentUser => user;

  @override
  String? get currentUserId => user == null ? null : 'uid-1';

  @override
  Set<String> get linkedProviderIds => {
    for (final info in user?.providerData ?? const <UserInfo>[])
      info.providerId,
  };

  Future<UserCredential?> _link() async {
    await gate?.future;
    if (error != null) throw error!;
    if (cancelLink) return null;
    user = afterLink?.call();
    _changes.add(user);
    return _FakeCredential();
  }

  @override
  Future<UserCredential?> linkGoogle() => _link();

  @override
  Future<UserCredential?> linkGithub() => _link();

  @override
  Future<UserCredential?> linkFacebook() => _link();

  @override
  Future<void> unlink(String providerId) async {
    await gate?.future;
    if (error != null) throw error!;
    unlinked.add(providerId);
  }
}

class RecordingUserService extends Fake implements UserService {
  final List<({String uid, String? displayName, bool isAnonymous})> calls = [];

  @override
  Future<void> ensureUserDocument(
    String uid, {
    String? displayName,
    String? email,
    required bool isAnonymous,
  }) async {
    calls.add((uid: uid, displayName: displayName, isAnonymous: isAnonymous));
  }
}

class CountingCrashlytics extends Fake implements CrashlyticsService {
  int handledErrors = 0;
  Map<String, Object>? lastKeys;

  @override
  Future<void> recordHandledError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, Object>? customKeys,
  }) async {
    handledErrors++;
    lastKeys = customKeys;
  }
}
