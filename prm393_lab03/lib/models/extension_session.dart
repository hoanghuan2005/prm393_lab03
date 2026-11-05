import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_fields.dart';

enum ExtensionSessionStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected'),
  revoked('revoked');

  final String key;

  const ExtensionSessionStatus(this.key);

  /// Unknown values read as revoked so they never count as linked
  static ExtensionSessionStatus fromKey(String? key) =>
      ExtensionSessionStatus.values.firstWhere(
        (s) => s.key == key,
        orElse: () => ExtensionSessionStatus.revoked,
      );
}

/// users/{uid}/extensionSessions/{sessionId} — one Chrome extension signed in with this
/// account. Created as pending by the extension; the phone approves, rejects or revokes it.
class ExtensionSession {
  /// A pending request older than this is expired (the extension stops waiting too)
  static const Duration pendingTtl = Duration(minutes: 5);

  final String id;
  final String deviceLabel;
  final ExtensionSessionStatus status;
  final DateTime createdAt;
  final DateTime? approvedAt;

  const ExtensionSession({
    required this.id,
    required this.deviceLabel,
    required this.status,
    required this.createdAt,
    this.approvedAt,
  });

  bool get isApproved => status == ExtensionSessionStatus.approved;

  /// Pending and still within [pendingTtl] of [now]
  bool isFreshPending(DateTime now) =>
      status == ExtensionSessionStatus.pending &&
      now.difference(createdAt) < pendingTtl;

  factory ExtensionSession.fromFirestore(DocumentSnapshot doc) {
    final data = docData(doc);
    return ExtensionSession(
      id: doc.id,
      deviceLabel: readText(data['deviceLabel']) ?? 'Trình duyệt máy tính',
      status: ExtensionSessionStatus.fromKey(readString(data['status'])),
      // A just-created session can still carry a pending server timestamp
      createdAt: readDate(data['createdAt']) ?? DateTime.now(),
      approvedAt: readDate(data['approvedAt']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtensionSession &&
          other.id == id &&
          other.deviceLabel == deviceLabel &&
          other.status == status &&
          other.createdAt == createdAt &&
          other.approvedAt == approvedAt;

  @override
  int get hashCode =>
      Object.hash(id, deviceLabel, status, createdAt, approvedAt);
}

/// extensionPairings/{pairingId} — a QR linking request shown by the extension.
/// [anonUid] is the extension's anonymous sign-in; approving makes it a session.
class ExtensionPairingRequest {
  /// Text inside the QR the extension shows (components/PairForm.tsx → QR_PREFIX)
  static const String qrPrefix = 'whyibuy-link:';

  final String id;
  final String anonUid;
  final String deviceLabel;
  final ExtensionSessionStatus status;
  final DateTime createdAt;

  const ExtensionPairingRequest({
    required this.id,
    required this.anonUid,
    required this.deviceLabel,
    required this.status,
    required this.createdAt,
  });

  /// Pairing id inside a scanned QR, or null when it is not a Why I Buy? link code
  static String? idFromQr(String? raw) {
    final text = raw?.trim() ?? '';
    if (!text.startsWith(qrPrefix)) return null;
    final id = text.substring(qrPrefix.length);
    return RegExp(r'^[A-Za-z0-9]{10,40}$').hasMatch(id) ? id : null;
  }

  bool isFreshPending(DateTime now) =>
      status == ExtensionSessionStatus.pending &&
      now.difference(createdAt) < ExtensionSession.pendingTtl;

  static ExtensionPairingRequest? fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) return null;
    final data = docData(doc);
    final anonUid = readString(data['anonUid']);
    if (anonUid == null || anonUid.isEmpty) return null;
    return ExtensionPairingRequest(
      id: doc.id,
      anonUid: anonUid,
      deviceLabel: readText(data['deviceLabel']) ?? 'Trình duyệt máy tính',
      status: ExtensionSessionStatus.fromKey(readString(data['status'])),
      createdAt: readDate(data['createdAt']) ?? DateTime.now(),
    );
  }
}
