import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import 'budget_group.dart';
import 'buying_motive.dart';
import 'firestore_fields.dart';

/// users/{uid}/purchases/{purchaseId}
class PurchaseItem {
  final String id;
  final String title;
  final int amountVnd;
  final BuyingMotive motive;
  final DateTime occurredAt;
  final String? note;
  final String budgetGroupId;
  final String? wishlistItemId;
  final bool usedDiscountCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Spec A-16: 1–5 stars, asked 7 days after the purchase; null = not answered
  final int? satisfaction;

  /// The user chose "Bỏ qua" on the satisfaction question; it is not asked again
  final bool satisfactionSkipped;

  const PurchaseItem({
    required this.id,
    required this.title,
    required this.amountVnd,
    required this.motive,
    required this.occurredAt,
    this.note,
    this.budgetGroupId = BudgetGroup.otherId,
    this.wishlistItemId,
    this.usedDiscountCode = false,
    this.createdAt,
    this.updatedAt,
    this.satisfaction,
    this.satisfactionSkipped = false,
  });

  /// Asked once a purchase is a week old; very old purchases (e.g. imported or demo
  /// data) are not asked about, since memory of them is no longer reliable
  static const int satisfactionAfterDays = 7;
  static const int satisfactionUntilDays = 30;

  bool isSatisfactionDue(DateTime now) {
    if (satisfaction != null || satisfactionSkipped) return false;
    final days = now.difference(occurredAt).inDays;
    return days >= satisfactionAfterDays && days <= satisfactionUntilDays;
  }

  String get formattedAmount => formatVnd(amountVnd);

  String get formattedTime => formatRelativeDateTime(occurredAt);

  /// Legacy documents used `amount` (double) and `dateTime`
  factory PurchaseItem.fromFirestore(DocumentSnapshot doc) {
    final data = docData(doc);
    return PurchaseItem(
      id: doc.id,
      title: readText(data['title']) ?? 'Khoản chi không tên',
      amountVnd: readInt(data['amountVnd'] ?? data['amount']) ?? 0,
      motive: BuyingMotive.fromKey(readString(data['motive'])),
      occurredAt:
          readDate(data['occurredAt'] ?? data['dateTime']) ?? DateTime.now(),
      note: readText(data['note']),
      budgetGroupId: readText(data['budgetGroupId']) ?? BudgetGroup.otherId,
      wishlistItemId: readText(data['wishlistItemId']),
      usedDiscountCode: data['usedDiscountCode'] == true,
      createdAt: readDate(data['createdAt']),
      updatedAt: readDate(data['updatedAt']),
      satisfaction: switch (readInt(data['satisfaction'])) {
        final int v when v >= 1 && v <= 5 => v,
        _ => null,
      },
      satisfactionSkipped: data['satisfactionSkipped'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amountVnd': amountVnd,
      'motive': motive.key,
      'occurredAt': Timestamp.fromDate(occurredAt),
      'note': note,
      'budgetGroupId': budgetGroupId,
      'wishlistItemId': wishlistItemId,
      'usedDiscountCode': usedDiscountCode,
      if (createdAt != null) 'createdAt': toTimestamp(createdAt),
      if (updatedAt != null) 'updatedAt': toTimestamp(updatedAt),
      'satisfaction': satisfaction,
      'satisfactionSkipped': satisfactionSkipped,
    };
  }

  PurchaseItem copyWith({
    String? id,
    String? title,
    int? amountVnd,
    BuyingMotive? motive,
    DateTime? occurredAt,
    String? note,
    bool clearNote = false,
    String? budgetGroupId,
    String? wishlistItemId,
    bool? usedDiscountCode,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? satisfaction,
    bool? satisfactionSkipped,
  }) {
    return PurchaseItem(
      id: id ?? this.id,
      title: title ?? this.title,
      amountVnd: amountVnd ?? this.amountVnd,
      motive: motive ?? this.motive,
      occurredAt: occurredAt ?? this.occurredAt,
      note: clearNote ? null : note ?? this.note,
      budgetGroupId: budgetGroupId ?? this.budgetGroupId,
      wishlistItemId: wishlistItemId ?? this.wishlistItemId,
      usedDiscountCode: usedDiscountCode ?? this.usedDiscountCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      satisfaction: satisfaction ?? this.satisfaction,
      satisfactionSkipped: satisfactionSkipped ?? this.satisfactionSkipped,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseItem &&
          other.id == id &&
          other.title == title &&
          other.amountVnd == amountVnd &&
          other.motive == motive &&
          other.occurredAt == occurredAt &&
          other.note == note &&
          other.budgetGroupId == budgetGroupId &&
          other.wishlistItemId == wishlistItemId &&
          other.usedDiscountCode == usedDiscountCode &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.satisfaction == satisfaction &&
          other.satisfactionSkipped == satisfactionSkipped;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    amountVnd,
    motive,
    occurredAt,
    note,
    budgetGroupId,
    wishlistItemId,
    usedDiscountCode,
    createdAt,
    updatedAt,
    satisfaction,
    satisfactionSkipped,
  );
}
