import 'buying_motive.dart';

/// In-memory prefill for the "Ghi khoản mua" flow (e.g. coming from a wishlist item).
/// Not stored in Firestore, so it has map helpers instead of fromFirestore.
class PurchaseDraft {
  final String title;
  final int? amountVnd;
  final BuyingMotive? motive;
  final String? budgetGroupId;
  final String? fromWishlistId;

  const PurchaseDraft({
    this.title = '',
    this.amountVnd,
    this.motive,
    this.budgetGroupId,
    this.fromWishlistId,
  });

  factory PurchaseDraft.fromMap(Map<String, dynamic> data) {
    final motiveKey = data['motive'];
    return PurchaseDraft(
      title: data['title'] is String ? data['title'] as String : '',
      amountVnd: (data['amountVnd'] as num?)?.toInt(),
      motive: motiveKey is String ? BuyingMotive.fromKey(motiveKey) : null,
      budgetGroupId: data['budgetGroupId'] as String?,
      fromWishlistId: data['fromWishlistId'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'amountVnd': amountVnd,
    'motive': motive?.key,
    'budgetGroupId': budgetGroupId,
    'fromWishlistId': fromWishlistId,
  };

  PurchaseDraft copyWith({
    String? title,
    int? amountVnd,
    BuyingMotive? motive,
    String? budgetGroupId,
    String? fromWishlistId,
  }) {
    return PurchaseDraft(
      title: title ?? this.title,
      amountVnd: amountVnd ?? this.amountVnd,
      motive: motive ?? this.motive,
      budgetGroupId: budgetGroupId ?? this.budgetGroupId,
      fromWishlistId: fromWishlistId ?? this.fromWishlistId,
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
          other.fromWishlistId == fromWishlistId;

  @override
  int get hashCode =>
      Object.hash(title, amountVnd, motive, budgetGroupId, fromWishlistId);
}
