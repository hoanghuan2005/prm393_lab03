import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_fields.dart';

enum SaleType {
  doubleDay('double_day', 'Ngày đôi'),
  midMonth('mid_month', 'Giữa tháng'),
  payday('payday', 'Ngày lương'),
  other('other', 'Khác');

  final String key;
  final String label;

  const SaleType(this.key, this.label);

  static SaleType fromKey(Object? key) => SaleType.values.firstWhere(
    (t) => t.key == key,
    orElse: () => SaleType.other,
  );
}

/// draft → draft / published / archived; published → published / archived;
/// archived is final (firestore.rules). Only `published` events reach the app.
enum SaleEventStatus {
  draft('draft', 'Nháp'),
  published('published', 'Đang hiển thị'),
  archived('archived', 'Đã lưu trữ');

  final String key;
  final String label;

  const SaleEventStatus(this.key, this.label);

  static SaleEventStatus fromKey(Object? key) => SaleEventStatus.values
      .firstWhere((s) => s.key == key, orElse: () => SaleEventStatus.archived);

  /// Statuses this one may move to
  List<SaleEventStatus> get next => switch (this) {
    draft => const [draft, published, archived],
    published => const [published, archived],
    archived => const [],
  };
}

/// What staff type in the sale event form.
class SaleEventDraft {
  static const int maxName = 40;

  final String name;
  final DateTime date;
  final SaleType type;
  final bool confirmed;

  const SaleEventDraft({
    required this.name,
    required this.date,
    required this.type,
    required this.confirmed,
  });

  /// Day only: the calendar has no time of day.
  DateTime get day => DateTime(date.year, date.month, date.day);

  Map<String, dynamic> toMap() => {
    'name': name.trim(),
    'date': Timestamp.fromDate(day),
    'type': type.key,
    'confirmed': confirmed,
  };
}

/// A public sale day: `saleEvents/{id}` on Firestore (managed on the web admin)
/// or a day generated from the public pattern on the app (not stored).
class SaleEvent {
  final String id;
  final String name;
  final DateTime date;
  final SaleType type;

  /// The shop announced it. Only confirmed sales count in the Decision Card.
  final bool confirmed;
  final SaleEventStatus status;

  /// Set when the event comes from an approved user suggestion
  final String? suggestionId;
  final DateTime? updatedAt;

  const SaleEvent({
    required this.id,
    required this.name,
    required this.date,
    required this.type,
    required this.confirmed,
    this.status = SaleEventStatus.published,
    this.suggestionId,
    this.updatedAt,
  });

  factory SaleEvent.fromFirestore(DocumentSnapshot doc) {
    final data = docData(doc);
    final date =
        readDate(data['date']) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return SaleEvent(
      id: doc.id,
      name: readText(data['name']) ?? '',
      date: DateTime(date.year, date.month, date.day),
      type: SaleType.fromKey(data['type']),
      confirmed: data['confirmed'] == true,
      status: SaleEventStatus.fromKey(data['status']),
      suggestionId: readText(data['suggestionId']),
      updatedAt: readDate(data['updatedAt']),
    );
  }

  bool get fromSuggestion => suggestionId != null;

  SaleEventDraft toDraft() =>
      SaleEventDraft(name: name, date: date, type: type, confirmed: confirmed);

  /// 0 on the sale day itself
  int daysUntil(DateTime now) => DateTime(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime(now.year, now.month, now.day)).inDays;

  static String dayId(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
