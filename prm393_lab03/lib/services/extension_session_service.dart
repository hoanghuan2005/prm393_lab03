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

  /// QR linking: the request whose id was scanned, or null when it does not exist
  Future<ExtensionPairingRequest?> fetchPairing(String pairingId);

  /// QR linking "Đồng ý": the extension's anonymous uid becomes a linked session of [uid]
  Future<void> approvePairing(
    String uid,
    ExtensionPairingRequest request, {
    String? accountName,
  });

  /// QR linking "Từ chối"
  Future<void> rejectPairing(String pairingId);
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

  @override
  Future<ExtensionPairingRequest?> fetchPairing(String pairingId) => guard(
    () async => ExtensionPairingRequest.fromFirestore(
      // Always the server copy: the extension may have just created or cancelled it
      await _paths
          .extensionPairing(pairingId)
          .get(const GetOptions(source: Source.server)),
    ),
  );

  @override
  Future<void> approvePairing(
    String uid,
    ExtensionPairingRequest request, {
    String? accountName,
  }) => guard(() {
    final batch = _paths.db.batch()
      ..set(_paths.extensionSession(uid, request.anonUid), {
        'deviceLabel': request.deviceLabel,
        'status': ExtensionSessionStatus.approved.key,
        'pairingId': request.id,
        'createdAt': FieldValue.serverTimestamp(),
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..update(_paths.extensionPairing(request.id), {
        'status': ExtensionSessionStatus.approved.key,
        'ownerUid': uid,
        if (accountName != null && accountName.isNotEmpty)
          'ownerName': accountName,
        'approvedAt': FieldValue.serverTimestamp(),
      });
    return awaitWrite(batch.commit());
  });

  @override
  Future<void> rejectPairing(String pairingId) => guard(
    () => awaitWrite(
      _paths.extensionPairing(pairingId).update({
        'status': ExtensionSessionStatus.rejected.key,
      }),
    ),
  );

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
