import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/inbox_message.dart';
import 'shared_paths.dart';

/// Personal messages under users/{uid}/inbox. Staff write them; the owner reads
/// them and only sets `readAt`. Announcements come from [AnnouncementService].
abstract class InboxService {
  Stream<List<InboxMessage>> watch(String uid);

  Future<void> markRead(String uid, String messageId);

  /// Staff → one user (web user list)
  Future<void> send({
    required String toUid,
    required String byUid,
    required String title,
    required String body,
  });
}

class FirestoreInboxService implements InboxService {
  final SharedPaths _paths;

  FirestoreInboxService([FirebaseFirestore? db])
    : _paths = SharedPaths(db ?? FirebaseFirestore.instance);

  @override
  Stream<List<InboxMessage>> watch(String uid) => _paths
      .inbox(uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(InboxMessage.fromFirestore).toList());

  @override
  Future<void> markRead(String uid, String messageId) => _paths
      .inbox(uid)
      .doc(messageId)
      .update({'readAt': FieldValue.serverTimestamp()});

  @override
  Future<void> send({
    required String toUid,
    required String byUid,
    required String title,
    required String body,
  }) => _paths
      .inbox(toUid)
      .add(
        inboxMessageData(
          kind: InboxKind.message,
          byUid: byUid,
          title: title,
          body: body,
        ),
      );
}

/// Fields of a new inbox message, as firestore.rules expects them
Map<String, dynamic> inboxMessageData({
  required InboxKind kind,
  required String byUid,
  required String title,
  required String body,
  String? refId,
}) {
  String cut(String s, int max) {
    final t = s.trim();
    return t.length > max ? t.substring(0, max) : t;
  }

  return {
    'title': cut(title, InboxMessage.maxTitle),
    'body': cut(body, InboxMessage.maxBody),
    'kind': kind.key,
    'refId': ?refId,
    'createdAt': FieldValue.serverTimestamp(),
    'createdBy': byUid,
  };
}
