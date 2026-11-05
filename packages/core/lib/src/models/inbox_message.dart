import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_fields.dart';

enum InboxMessageType {
  suggestionApproved('suggestion_approved'),
  suggestionRejected('suggestion_rejected');

  final String key;

  const InboxMessageType(this.key);

  static InboxMessageType fromKey(Object? key) =>
      InboxMessageType.values.firstWhere(
        (t) => t.key == key,
        orElse: () => InboxMessageType.suggestionApproved,
      );
}

/// `users/{uid}/inbox/{id}`: written by an admin when one of the user's sale
/// suggestions is reviewed. The owner only flips [read].
class InboxMessage {
  static const int maxTitle = 80;
  static const int maxBody = 500;

  final String id;
  final InboxMessageType type;
  final String title;
  final String body;
  final String suggestionId;
  final bool read;
  final DateTime? createdAt;

  const InboxMessage({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.suggestionId,
    this.read = false,
    this.createdAt,
  });

  factory InboxMessage.fromFirestore(DocumentSnapshot doc) {
    final data = docData(doc);
    return InboxMessage(
      id: doc.id,
      type: InboxMessageType.fromKey(data['type']),
      title: readText(data['title']) ?? '',
      body: readText(data['body']) ?? '',
      suggestionId: readString(data['suggestionId']) ?? '',
      read: data['read'] == true,
      createdAt: readDate(data['createdAt']),
    );
  }
}
