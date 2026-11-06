import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_fields.dart';

/// What a personal message is about (firestore.rules lists the allowed kinds)
enum InboxKind {
  /// Written by staff from the web user list
  message('message'),

  /// Answer to a "Gửi góp ý" message
  feedbackReply('feedback_reply'),

  /// Result of a sale suggestion review (approved or rejected, with the reason)
  suggestionReply('suggestion_reply');

  final String key;

  const InboxKind(this.key);

  static InboxKind fromKey(Object? key) => InboxKind.values.firstWhere(
    (k) => k.key == key,
    orElse: () => InboxKind.message,
  );
}

/// `users/{uid}/inbox/{id}`: written by staff or an admin; the owner only sets [readAt].
class InboxMessage {
  static const int maxTitle = 80;
  static const int maxBody = 500;

  final String id;
  final InboxKind kind;
  final String title;
  final String body;

  /// The feedback or suggestion the message answers
  final String? refId;
  final DateTime? createdAt;
  final DateTime? readAt;

  const InboxMessage({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    this.refId,
    this.createdAt,
    this.readAt,
  });

  bool get isRead => readAt != null;

  factory InboxMessage.fromFirestore(DocumentSnapshot doc) {
    final data = docData(doc);
    return InboxMessage(
      id: doc.id,
      kind: InboxKind.fromKey(data['kind']),
      title: readText(data['title']) ?? '',
      body: readText(data['body']) ?? '',
      refId: readText(data['refId']),
      createdAt: readDate(data['createdAt']),
      readAt: readDate(data['readAt']),
    );
  }
}
