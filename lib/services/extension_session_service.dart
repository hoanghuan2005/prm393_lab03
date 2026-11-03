import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/extension_session.dart';
import 'firestore_paths.dart';
import 'service_guard.dart';

/// Linking the Chrome extension: users/{uid}/extensionSessions. The extension signs in
/// with the same Google account and creates a pending session; the phone decides.
abstract interface class ExtensionSessionService {
  /// Newest first
  Stream<List<ExtensionSession>> watchSessions(String uid);

  Future<void> approve(String uid, String sessionId);

  Future<void> reject(String uid, String sessionId);

  /// "Huỷ liên kết": the extension sees revoked and goes back to unlinked
  Future<void> revoke(String uid, String sessionId);
}

class FirestoreExtensionSessionService implements ExtensionSessionService {
  final FirestorePaths _paths;

  FirestoreExtensionSessionService([FirebaseFirestore? firestore])
    : _paths = FirestorePaths(firestore ?? FirebaseFirestore.instance);

  @override
  Stream<List<ExtensionSession>> watchSessions(String uid) => guardStream(
    _paths
        .extensionSessions(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ExtensionSession.fromFirestore).toList()),
  );

  @override
  Future<void> approve(String uid, String sessionId) => _setStatus(
    uid,
    sessionId,
    ExtensionSessionStatus.approved,
    extra: {'approvedAt': FieldValue.serverTimestamp()},
  );

  @override
  Future<void> reject(String uid, String sessionId) =>
      _setStatus(uid, sessionId, ExtensionSessionStatus.rejected);

  @override
  Future<void> revoke(String uid, String sessionId) =>
      _setStatus(uid, sessionId, ExtensionSessionStatus.revoked);

  Future<void> _setStatus(
    String uid,
    String sessionId,
    ExtensionSessionStatus status, {
    Map<String, dynamic> extra = const {},
  }) => guard(
    () => awaitWrite(
      _paths.extensionSession(uid, sessionId).update({
        'status': status.key,
        ...extra,
        'updatedAt': FieldValue.serverTimestamp(),
      }),
    ),
  );
}
