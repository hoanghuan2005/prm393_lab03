import 'buying_motive.dart';

/// In-memory prefill for the "Ghi khoản mua" flow (e.g. coming from a wishlist item).
/// Not stored in Firestore, so it has map helpers instead of fromFirestore.
class PurchaseDraft {
  final String title;
  final int? amountVnd;
  final BuyingMotive? motive;
  final String? budgetGroupId;
  final String? fromWishlistId;
  final DateTime? occurredAt;
  final String? note;
  final bool usedDiscountCode;

  const PurchaseDraft({
    this.title = '',
    this.amountVnd,
    this.motive,
    this.budgetGroupId,
    this.fromWishlistId,
    this.occurredAt,
    this.note,
    this.usedDiscountCode = false,
  });

  factory PurchaseDraft.fromMap(Map<String, dynamic> data) {
    final motiveKey = data['motive'];
    return PurchaseDraft(
      title: data['title'] is String ? data['title'] as String : '',
      amountVnd: (data['amountVnd'] as num?)?.toInt(),
      motive: motiveKey is String ? BuyingMotive.fromKey(motiveKey) : null,
      budgetGroupId: data['budgetGroupId'] as String?,
      fromWishlistId: data['fromWishlistId'] as String?,
      occurredAt: data['occurredAt'] is DateTime
          ? data['occurredAt'] as DateTime
          : DateTime.tryParse(data['occurredAt']?.toString() ?? ''),
      note: data['note'] as String?,
      usedDiscountCode: data['usedDiscountCode'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'amountVnd': amountVnd,
    'motive': motive?.key,
    'budgetGroupId': budgetGroupId,
    'fromWishlistId': fromWishlistId,
    'occurredAt': occurredAt?.toIso8601String(),
    'note': note,
    'usedDiscountCode': usedDiscountCode,
  };

  PurchaseDraft copyWith({
    String? title,
    int? amountVnd,
    BuyingMotive? motive,
    String? budgetGroupId,
    String? fromWishlistId,
    DateTime? occurredAt,
    String? note,
    bool? usedDiscountCode,
  }) {
    return PurchaseDraft(
      title: title ?? this.title,
      amountVnd: amountVnd ?? this.amountVnd,
      motive: motive ?? this.motive,
      budgetGroupId: budgetGroupId ?? this.budgetGroupId,
      fromWishlistId: fromWishlistId ?? this.fromWishlistId,
      occurredAt: occurredAt ?? this.occurredAt,
      note: note ?? this.note,
      usedDiscountCode: usedDiscountCode ?? this.usedDiscountCode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseDraft &&
          other.title == title &&
          other.amountVnd == amountVnd &&
          other.motive == motive &&
          other.budgetGroupId == budgetGroupId &&
          other.fromWishlistId == fromWishlistId &&
          other.occurredAt == occurredAt &&
          other.note == note &&
          other.usedDiscountCode == usedDiscountCode;

  @override
  int get hashCode => Object.hash(
    title,
    amountVnd,
    motive,
    budgetGroupId,
    fromWishlistId,
    occurredAt,
    note,
    usedDiscountCode,
  );
}
