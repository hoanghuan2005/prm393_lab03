import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/inbox_message.dart';
import 'shared_paths.dart';

/// The app side of the inbox: personal messages under users/{uid}/inbox.
/// Announcements come from [AnnouncementService.watchPublished].
abstract class InboxService {
  Stream<List<InboxMessage>> watch(String uid);

  Future<void> markRead(String uid, String messageId);
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
  Future<void> markRead(String uid, String messageId) =>
      _paths.inbox(uid).doc(messageId).update({'read': true});
}
