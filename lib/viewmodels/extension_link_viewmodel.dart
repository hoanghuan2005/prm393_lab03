import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/extension_session.dart';
import '../services/crashlytics_service.dart';
import '../services/extension_session_service.dart';
import 'deferred_notify.dart';
import 'error_reporting.dart';

/// Linking the Chrome extension: approve a new browser on the phone ("Cho phép … liên kết?")
/// and list / revoke linked browsers in Cá nhân → "Thiết bị đã liên kết".
class ExtensionLinkViewModel extends ChangeNotifier
    with DeferredNotify, ErrorReporting {
  final ExtensionSessionService service;
  @override
  final CrashlyticsService? crashlyticsService;

  /// Injectable clock for the pending-request expiry
  final DateTime Function() _now;

  String? _uid;
  StreamSubscription<List<ExtensionSession>>? _subscription;
  List<ExtensionSession> _sessions = const [];
  bool _loaded = false;
  String? _actionError;

  /// Pending requests already shown in a dialog, so each asks only once
  final Set<String> _prompted = {};

  ExtensionLinkViewModel({
    required this.service,
    this.crashlyticsService,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  bool get isLoaded => _loaded;
  String? get actionError => _actionError;

  /// Newest fresh pending request (< 5 minutes old), if any
  ExtensionSession? get pendingSession {
    final now = _now();
    for (final s in _sessions) {
      if (s.isFreshPending(now)) return s;
    }
    return null;
  }

  /// Pending request that has not been shown in a dialog yet
  ExtensionSession? get unpromptedPending {
    final pending = pendingSession;
    return pending == null || _prompted.contains(pending.id) ? null : pending;
  }

  List<ExtensionSession> get linkedSessions =>
      _sessions.where((s) => s.isApproved).toList();

  void markPrompted(String sessionId) => _prompted.add(sessionId);

  void updateUid(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _subscription?.cancel();
    _subscription = null;
    _sessions = const [];
    _loaded = false;
    _prompted.clear();
    notifyLater();
    if (uid == null) return;
    _subscription = service
        .watchSessions(uid)
        .listen(
          (sessions) {
            _sessions = sessions;
            _loaded = true;
            notifyListeners();
          },
          // Linking is optional: the rest of the app keeps working without it
          onError: (Object e, StackTrace stack) {
            _loaded = true;
            _actionError = messageFor(e, stack, reason: 'watchSessions');
            notifyListeners();
          },
        );
  }

  Future<bool> approve(ExtensionSession session) =>
      _write((uid) => service.approve(uid, session.id), 'approveExtension');

  Future<bool> reject(ExtensionSession session) =>
      _write((uid) => service.reject(uid, session.id), 'rejectExtension');

  Future<bool> revoke(ExtensionSession session) =>
      _write((uid) => service.revoke(uid, session.id), 'revokeExtension');

  Future<bool> _write(
    Future<void> Function(String uid) write,
    String reason,
  ) async {
    final uid = _uid;
    if (uid == null) {
      _actionError = 'Vui lòng đăng nhập để liên kết extension.';
      return false;
    }
    try {
      await write(uid);
      _actionError = null;
      return true;
    } catch (e, stack) {
      _actionError = messageFor(e, stack, reason: reason);
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
