import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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

  String get formattedAmount {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    return formatter.format(amount).trim();
  }

  String get formattedTime {
    final now = DateTime.now();
    final isToday = now.year == dateTime.year && now.month == dateTime.month && now.day == dateTime.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = yesterday.year == dateTime.year && yesterday.month == dateTime.month && yesterday.day == dateTime.day;

    final timeStr = DateFormat('HH:mm').format(dateTime);

    if (isToday) {
      return 'Hôm nay $timeStr';
    } else if (isYesterday) {
      return 'Hôm qua $timeStr';
    } else {
      return '${DateFormat('dd/MM').format(dateTime)} $timeStr';
    }
  }

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
