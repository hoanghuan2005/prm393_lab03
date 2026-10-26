import 'package:cloud_firestore/cloud_firestore.dart';

/// Null-safe readers shared by every model's `fromFirestore`.
/// Missing or wrongly typed fields fall back to null instead of throwing.

Map<String, dynamic> docData(DocumentSnapshot doc) =>
    doc.data() as Map<String, dynamic>? ?? const {};

/// Reads `int` from int or legacy double values
int? readInt(Object? value) => (value as num?)?.toInt();

/// Money: like [readInt] but 0 or negative means "no amount" (never stored as 0)
int? readVnd(Object? value) {
  final v = readInt(value);
  return v == null || v <= 0 ? null : v;
}

DateTime? readDate(Object? value) =>
    value is Timestamp ? value.toDate() : (value is DateTime ? value : null);

String? readString(Object? value) => value is String ? value : null;

/// Trimmed text, null when empty
String? readText(Object? value) {
  final s = readString(value)?.trim();
  return s == null || s.isEmpty ? null : s;
}

Timestamp? toTimestamp(DateTime? value) =>
    value == null ? null : Timestamp.fromDate(value);
