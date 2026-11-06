import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_fields.dart';

/// pending → approved | rejected, by an admin only (firestore.rules).
enum SuggestionStatus {
  pending('pending', 'Chờ duyệt'),
  approved('approved', 'Đã duyệt'),
  rejected('rejected', 'Đã từ chối');

  final String key;
  final String label;

  const SuggestionStatus(this.key, this.label);

  static SuggestionStatus fromKey(Object? key) => SuggestionStatus.values
      .firstWhere((s) => s.key == key, orElse: () => SuggestionStatus.pending);
}

/// `saleSuggestions/{id}`: a sale a user proposes on the app. Holds the uid
/// only, never a name or e-mail.
class SaleSuggestion {
  final String id;
  final String uid;
  final String name;
  final DateTime date;
  final String? note;
  final SuggestionStatus status;
  final String? reason;
  final String? saleEventId;
  final DateTime? createdAt;
  final DateTime? reviewedAt;

  const SaleSuggestion({
    required this.id,
    required this.uid,
    required this.name,
    required this.date,
    this.note,
    this.status = SuggestionStatus.pending,
    this.reason,
    this.saleEventId,
    this.createdAt,
    this.reviewedAt,
  });

  factory SaleSuggestion.fromFirestore(DocumentSnapshot doc) {
    final data = docData(doc);
    final date =
        readDate(data['date']) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return SaleSuggestion(
      id: doc.id,
      uid: readString(data['uid']) ?? '',
      name: readText(data['name']) ?? '',
      date: DateTime(date.year, date.month, date.day),
      note: readText(data['note']),
      status: SuggestionStatus.fromKey(data['status']),
      reason: readText(data['reason']),
      saleEventId: readText(data['saleEventId']),
      createdAt: readDate(data['createdAt']),
      reviewedAt: readDate(data['reviewedAt']),
    );
  }
}
