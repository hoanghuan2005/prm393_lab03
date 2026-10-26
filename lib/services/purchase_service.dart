import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/errors/app_exception.dart';
import '../models/budget_group.dart';
import '../models/decision.dart';
import '../models/purchase_draft.dart';
import '../models/purchase_item.dart';
import '../models/wishlist_item.dart';
import '../models/wishlist_status.dart';
import 'firestore_paths.dart';
import 'service_guard.dart';

/// users/{uid}/purchases
abstract interface class PurchaseService {
  /// Newest first; [from] inclusive, [to] exclusive, both filtered on the server
  Stream<List<PurchaseItem>> watchPurchases(
    String uid, {
    DateTime? from,
    DateTime? to,
  });

  /// Returns the stored item with its new id
  Future<PurchaseItem> add(String uid, PurchaseItem purchase);

  Future<void> update(String uid, PurchaseItem purchase);

  Future<void> delete(String uid, String purchaseId);

  /// One batch: new purchase linked to [item], item marked purchased, decision "buy".
  /// Returns the new purchase id.
  Future<String> buyFromWishlist(
    String uid,
    WishlistItem item,
    PurchaseDraft draft,
  );
}

class FirestorePurchaseService implements PurchaseService {
  final FirestorePaths _paths;

  FirestorePurchaseService([FirebaseFirestore? firestore])
    : _paths = FirestorePaths(firestore ?? FirebaseFirestore.instance);

  @override
  Stream<List<PurchaseItem>> watchPurchases(
    String uid, {
    DateTime? from,
    DateTime? to,
  }) {
    Query<JsonMap> query = _paths.purchases(uid);
    if (from != null) {
      query = query.where(
        'occurredAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(from),
      );
    }
    if (to != null) {
      query = query.where('occurredAt', isLessThan: Timestamp.fromDate(to));
    }
    return guardStream(
      query
          .orderBy('occurredAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map(PurchaseItem.fromFirestore).toList()),
    );
  }

  @override
  Future<PurchaseItem> add(String uid, PurchaseItem purchase) =>
      guard(() async {
        final ref = _paths.purchases(uid).doc();
        await ref.set({
          ...purchase.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return purchase.copyWith(id: ref.id);
      });

  @override
  Future<void> update(String uid, PurchaseItem purchase) => guard(() {
    final data = purchase.toMap()..remove('createdAt');
    return _paths.purchase(uid, purchase.id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  });

  @override
  Future<void> delete(String uid, String purchaseId) =>
      guard(() => _paths.purchase(uid, purchaseId).delete());

  @override
  Future<String> buyFromWishlist(
    String uid,
    WishlistItem item,
    PurchaseDraft draft,
  ) => guard(() async {
    final amount = draft.amountVnd ?? item.latestPriceVnd;
    if (amount == null || amount <= 0) {
      throw const AppException(
        'missing-amount',
        'Vui lòng nhập số tiền thực chi trước khi lưu.',
      );
    }
    final now = DateTime.now();
    final purchaseRef = _paths.purchases(uid).doc();
    final purchase = PurchaseItem(
      id: purchaseRef.id,
      title: draft.title.trim().isNotEmpty ? draft.title.trim() : item.title,
      amountVnd: amount,
      motive: draft.motive ?? item.displayMotive,
      occurredAt: now,
      budgetGroupId:
          draft.budgetGroupId ?? item.budgetGroupId ?? BudgetGroup.otherId,
      wishlistItemId: item.id,
    );
    final decision = Decision(
      id: '',
      itemId: item.id,
      choice: DecisionChoice.buy,
      at: now,
    );

    final batch = _paths.db.batch()
      ..set(purchaseRef, {
        ...purchase.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..update(_paths.wishlistItem(uid, item.id), {
        'status': WishlistStatus.purchased.key,
        'purchaseId': purchaseRef.id,
        'decidedAt': FieldValue.serverTimestamp(),
        'reviewAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..set(_paths.decisions(uid).doc(), {
        ...decision.toMap(),
        'at': FieldValue.serverTimestamp(),
      });
    await batch.commit();
    return purchaseRef.id;
  });
}
