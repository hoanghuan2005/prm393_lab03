import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import 'buying_motive.dart';

/// Purchase Item Data Model for Why I Buy
class PurchaseItem {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final BuyingMotive motive;
  final DateTime dateTime;
  final String? note;

  const PurchaseItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.motive,
    required this.dateTime,
    this.note,
  });

  String get formattedAmount => formatVnd(amount.round());

  String get formattedTime => formatRelativeDateTime(dateTime);

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'amount': amount,
      'motive': motive.key,
      'dateTime': Timestamp.fromDate(dateTime),
      'note': note,
    };
  }

  factory PurchaseItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PurchaseItem(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? 'Khoản chi không tên',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      motive: BuyingMotive.fromKey(data['motive'] as String?),
      dateTime: (data['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: data['note'] as String?,
    );
  }

  PurchaseItem copyWith({
    String? id,
    String? userId,
    String? title,
    double? amount,
    BuyingMotive? motive,
    DateTime? dateTime,
    String? note,
  }) {
    return PurchaseItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      motive: motive ?? this.motive,
      dateTime: dateTime ?? this.dateTime,
      note: note ?? this.note,
    );
  }
}
