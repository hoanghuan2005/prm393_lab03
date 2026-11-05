import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/inbox_message.dart';
import '../models/sale_event.dart';
import '../models/sale_suggestion.dart';
import 'firestore_errors.dart';
import 'shared_paths.dart';

abstract class SaleSuggestionService {
  /// Admin review queue: pending oldest first, reviewed ones latest first
  Stream<List<SaleSuggestion>> watchByStatus(SuggestionStatus status);

  /// The signed-in user's own suggestions (app), latest first
  Stream<List<SaleSuggestion>> watchMine(String uid);

  /// App: a new suggestion is always pending
  Future<void> submit({
    required String uid,
    required String name,
    required DateTime date,
    String? note,
  });

  /// One batch: publish the sale event, mark the suggestion approved and tell
  /// the user in their inbox. Returns the new event id.
  Future<String> approve({
    required SaleSuggestion suggestion,
    required String adminUid,
    required SaleEventDraft event,
  });

  /// One batch: mark the suggestion rejected with [reason] and tell the user.
  Future<void> reject({
    required SaleSuggestion suggestion,
    required String adminUid,
    required String reason,
  });
}

class FirestoreSaleSuggestionService implements SaleSuggestionService {
  static const int maxReason = 200;

  final FirebaseFirestore _db;
  final SharedPaths _paths;

  FirestoreSaleSuggestionService([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance,
      _paths = SharedPaths(db ?? FirebaseFirestore.instance);

  @override
  Stream<List<SaleSuggestion>> watchByStatus(SuggestionStatus status) => _paths
      .saleSuggestions()
      .where('status', isEqualTo: status.key)
      .orderBy('createdAt', descending: status != SuggestionStatus.pending)
      .snapshots()
      .map((s) => s.docs.map(SaleSuggestion.fromFirestore).toList());

  @override
  Stream<List<SaleSuggestion>> watchMine(String uid) => _paths
      .saleSuggestions()
      .where('uid', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(SaleSuggestion.fromFirestore).toList());

  @override
  Future<void> submit({
    required String uid,
    required String name,
    required DateTime date,
    String? note,
  }) {
    final trimmedNote = note?.trim();
    return _paths.saleSuggestions().add({
      'uid': uid,
      'name': name.trim(),
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      if (trimmedNote != null && trimmedNote.isNotEmpty) 'note': trimmedNote,
      'status': SuggestionStatus.pending.key,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<String> approve({
    required SaleSuggestion suggestion,
    required String adminUid,
    required SaleEventDraft event,
  }) async {
    final eventRef = _paths.saleEvents().doc();
    final batch = _db.batch()
      ..set(eventRef, {
        ...event.toMap(),
        'status': SaleEventStatus.published.key,
        'source': SaleEventSource.suggestion.key,
        'suggestionId': suggestion.id,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': adminUid,
      })
      ..update(_paths.saleSuggestion(suggestion.id), {
        'status': SuggestionStatus.approved.key,
        'saleEventId': eventRef.id,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': adminUid,
      })
      ..set(
        _paths.inbox(suggestion.uid).doc(),
        _inboxMessage(
          type: InboxMessageType.suggestionApproved,
          suggestionId: suggestion.id,
          title: 'Đề xuất sale đã được duyệt',
          body:
              '"${event.name.trim()}" ngày ${formatDay(event.day)} đã có trong '
              'Lịch sale. Cảm ơn bạn đã đề xuất!',
        ),
      );
    await batch.commit();
    return eventRef.id;
  }

  @override
  Future<void> reject({
    required SaleSuggestion suggestion,
    required String adminUid,
    required String reason,
  }) {
    final trimmed = reason.trim();
    final batch = _db.batch()
      ..update(_paths.saleSuggestion(suggestion.id), {
        'status': SuggestionStatus.rejected.key,
        'reason': trimmed,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': adminUid,
      })
      ..set(
        _paths.inbox(suggestion.uid).doc(),
        _inboxMessage(
          type: InboxMessageType.suggestionRejected,
          suggestionId: suggestion.id,
          title: 'Đề xuất sale chưa được duyệt',
          body: 'Đề xuất "${suggestion.name}" chưa được duyệt. Lý do: $trimmed',
        ),
      );
    return batch.commit();
  }

  static Map<String, dynamic> _inboxMessage({
    required InboxMessageType type,
    required String suggestionId,
    required String title,
    required String body,
  }) => {
    'type': type.key,
    'title': title,
    'body': body.length > InboxMessage.maxBody
        ? body.substring(0, InboxMessage.maxBody)
        : body,
    'suggestionId': suggestionId,
    'createdAt': FieldValue.serverTimestamp(),
    'read': false,
  };
}
