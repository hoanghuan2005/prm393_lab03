import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/errors/app_exception.dart';
import '../core/validators/validators.dart';
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

  /// A purchase linked to a wishlist item also returns that item to "Đang cân nhắc"
  /// (same batch, decision "undo"), so the item can be bought again later.
  Future<void> delete(String uid, String purchaseId);

  /// One batch: new purchase linked to [item], item marked purchased, decision "buy".
  /// Stable ids make a retry refer to the same purchase and decision.
  Future<PurchaseItem> buyFromWishlist(
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
        _validate(purchase);
        // The form retains its operation id on retry, including a lost acknowledgement.
        final ref = _paths
            .purchases(uid)
            .doc(purchase.id.isEmpty ? null : purchase.id);
        await awaitWrite(
          ref.set({
            ...purchase.toMap(),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }),
        );
        return purchase.copyWith(id: ref.id);
      });

  @override
  Future<void> update(String uid, PurchaseItem purchase) => guard(() {
    _validate(purchase);
    final data = purchase.toMap()..remove('createdAt');
    return awaitWrite(
      _paths.purchase(uid, purchase.id).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      }),
    );
  });

  @override
  Future<void> delete(String uid, String purchaseId) => guard(() async {
    final purchaseRef = _paths.purchase(uid, purchaseId);
    final snapshot = await _readOfflineSafe(purchaseRef);
    final itemId = snapshot != null && snapshot.exists
        ? PurchaseItem.fromFirestore(snapshot).wishlistItemId
        : null;
    final batch = _paths.db.batch()..delete(purchaseRef);

    if (itemId != null) {
      final itemRef = _paths.wishlistItem(uid, itemId);
      final itemSnapshot = await _readOfflineSafe(itemRef);
      // Only unlink when the item still points at this purchase (it may be deleted or re-bought)
      if (itemSnapshot != null &&
          itemSnapshot.exists &&
          WishlistItem.fromFirestore(itemSnapshot).purchaseId == purchaseId) {
        batch
          ..update(itemRef, {
            'status': WishlistStatus.considering.key,
            'purchaseId': null,
            'decidedAt': null,
            'updatedAt': FieldValue.serverTimestamp(),
          })
          // buy_{itemId} is the create-only lock of buyFromWishlist; removing it lets the
          // item be bought again. The undo decision keeps the reversal in the history.
          ..delete(_paths.decisions(uid).doc('buy_$itemId'))
          ..set(_paths.decisions(uid).doc(), {
            ...Decision(
              id: '',
              itemId: itemId,
              choice: DecisionChoice.undo,
              at: DateTime.now(),
            ).toMap(),
            'at': FieldValue.serverTimestamp(),
          });
      }
    }
    await awaitWrite(batch.commit());
  });

  @override
  Future<PurchaseItem> buyFromWishlist(
    String uid,
    WishlistItem item,
    PurchaseDraft draft,
  ) => guard(() async {
    if (draft.fromWishlistId != null && draft.fromWishlistId != item.id) {
      throw const AppException(
        'invalid-wishlist',
        'Món cần ghi khoản mua không khớp. Vui lòng mở lại món.',
      );
    }
    final amount = draft.amountVnd;
    if (amount == null || amount <= 0) {
      throw const AppException(
        'missing-amount',
        'Vui lòng nhập số tiền thực chi trước khi lưu.',
      );
    }
    final itemRef = _paths.wishlistItem(uid, item.id);
    final snapshot = await _readOfflineSafe(itemRef);
    if (snapshot != null && !snapshot.exists) {
      throw const AppException(
        'not-found',
        'Món này đã bị xoá. Vui lòng quay lại danh sách.',
      );
    }
    // Offline and not cached: the screen's copy of the item is the best we know
    final current = snapshot == null
        ? item
        : WishlistItem.fromFirestore(snapshot);
    final purchaseRef = _paths.purchase(
      uid,
      current.purchaseId ?? 'wishlist_${item.id}',
    );
    final existing = await _readOfflineSafe(purchaseRef);
    if (existing != null && existing.exists) {
      return _readLinkedPurchase(existing, item.id);
    }
    if (current.purchaseId != null) {
      throw const AppException(
        'missing-purchase',
        'Không tìm thấy khoản mua đã liên kết với món này. Vui lòng tải lại danh sách.',
      );
    }
    if (current.status == WishlistStatus.skipped) {
      throw const AppException(
        'item-skipped',
        'Món này đã được bỏ qua. Vui lòng quay lại danh sách.',
      );
    }
    // Older app versions could mark a wishlist item as purchased without a
    // purchaseId. An explicit confirmation in this form can repair that state.
    final now = DateTime.now();
    final purchase = PurchaseItem(
      id: purchaseRef.id,
      title: draft.title.trim().isNotEmpty ? draft.title.trim() : current.title,
      amountVnd: amount,
      motive: draft.motive ?? current.displayMotive,
      occurredAt: draft.occurredAt ?? now,
      budgetGroupId:
          draft.budgetGroupId ?? current.budgetGroupId ?? BudgetGroup.otherId,
      wishlistItemId: item.id,
      note: draft.note,
      usedDiscountCode: draft.usedDiscountCode,
      createdAt: now,
    );
    _validate(purchase);
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
      ..update(itemRef, {
        'status': WishlistStatus.purchased.key,
        'purchaseId': purchaseRef.id,
        'decidedAt': FieldValue.serverTimestamp(),
        'reviewAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      })
      // Decisions are create-only in firestore.rules. A competing batch for
      // this same item cannot overwrite the first completed purchase.
      ..set(_paths.decisions(uid).doc('buy_${item.id}'), {
        ...decision.toMap(),
        'at': FieldValue.serverTimestamp(),
      });
    try {
      await awaitWrite(batch.commit());
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied' && error.code != 'already-exists') {
        rethrow;
      }
      // Another client may have completed this item after our initial read.
      // Accept only a server-confirmed linked purchase; do not mask a failed write.
      try {
        final committed = await purchaseRef.get(
          const GetOptions(source: Source.server),
        );
        if (committed.exists) return _readLinkedPurchase(committed, item.id);
      } catch (_) {
        // Preserve the original write error when recovery cannot be confirmed.
      }
      rethrow;
    }
    return purchase;
  });

  /// `get()` fails offline for a document that is not in the local cache (e.g. the
  /// `wishlist_{itemId}` purchase that does not exist yet). Falls back to the cache and
  /// returns null when this device does not know the document.
  static Future<DocumentSnapshot<JsonMap>?> _readOfflineSafe(
    DocumentReference<JsonMap> ref,
  ) async {
    try {
      return await ref.get();
    } on FirebaseException catch (e) {
      if (e.code != 'unavailable') rethrow;
      try {
        return await ref.get(const GetOptions(source: Source.cache));
      } on FirebaseException {
        return null;
      }
    }
  }

  static PurchaseItem _readLinkedPurchase(
    DocumentSnapshot snapshot,
    String itemId,
  ) {
    final purchase = PurchaseItem.fromFirestore(snapshot);
    if (purchase.wishlistItemId != itemId) {
      throw const AppException(
        'invalid-link',
        'Khoản mua liên kết không khớp với món. Vui lòng tải lại danh sách.',
      );
    }
    return purchase;
  }

  static void _validate(PurchaseItem purchase) {
    final message = Validators.validatePurchase(
      title: purchase.title,
      amountVnd: purchase.amountVnd,
      budgetGroupId: purchase.budgetGroupId,
      note: purchase.note,
    );
    if (message != null) throw AppException('invalid-purchase', message);
  }
}
