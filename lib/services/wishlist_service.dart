import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/buying_motive.dart';
import '../models/decision.dart';
import '../models/price_snapshot.dart';
import '../models/wishlist_item.dart';
import '../models/wishlist_status.dart';
import 'firestore_paths.dart';
import 'service_guard.dart';

/// users/{uid}/wishlistItems (+ priceSnapshots) and the decisions made on them
abstract interface class WishlistService {
  /// Newest first
  Stream<List<WishlistItem>> watchItems(String uid);

  /// [priceVnd] may be null (price not known yet). A price also writes the first snapshot.
  /// Cooling-off starts at creation unless the motive is "Nhu cầu".
  Future<WishlistItem> add(
    String uid, {
    required String title,
    BuyingMotive? motive,
    int? priceVnd,
    String? url,
    String? note,
    String? budgetGroupId,
    int priority = WishlistItem.defaultPriority,
    SaveChannel saveChannel = SaveChannel.manual,
    required int coolingOffDays,
  });

  Future<void> update(String uid, WishlistItem item);

  /// New price snapshot + latestPriceVnd/latestPriceAt
  Future<void> addPrice(String uid, String itemId, int amountVnd);

  /// "Giá lúc lưu": the first recorded price snapshot; null when there is none
  Future<int?> firstPrice(String uid, String itemId);

  /// "Chờ": reviewAt + decision wait
  Future<void> setReview(String uid, String itemId, DateTime reviewAt);

  /// "Bỏ qua": status skipped + decision skip
  Future<void> skip(String uid, String itemId);

  /// Back to considering + decision undo
  Future<void> undoSkip(String uid, String itemId);

  /// Deletes the item and its price snapshots (decisions stay as history)
  Future<void> delete(String uid, String itemId);
}

class FirestoreWishlistService implements WishlistService {
  final FirestorePaths _paths;

  FirestoreWishlistService([FirebaseFirestore? firestore])
    : _paths = FirestorePaths(firestore ?? FirebaseFirestore.instance);

  @override
  Stream<List<WishlistItem>> watchItems(String uid) => guardStream(
    _paths
        .wishlistItems(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(WishlistItem.fromFirestore).toList()),
  );

  @override
  Future<WishlistItem> add(
    String uid, {
    required String title,
    BuyingMotive? motive,
    int? priceVnd,
    String? url,
    String? note,
    String? budgetGroupId,
    int priority = WishlistItem.defaultPriority,
    SaveChannel saveChannel = SaveChannel.manual,
    required int coolingOffDays,
  }) => guard(() async {
    final createdAt = DateTime.now();
    final price = priceVnd != null && priceVnd > 0 ? priceVnd : null;
    final itemRef = _paths.wishlistItems(uid).doc();
    final item = WishlistItem(
      id: itemRef.id,
      title: title,
      url: url,
      motive: motive,
      priority: priority,
      cooldownUntil: motive == BuyingMotive.need
          ? null
          : createdAt.add(Duration(days: coolingOffDays)),
      budgetGroupId: budgetGroupId,
      latestPriceVnd: price,
      latestPriceAt: price == null ? null : createdAt,
      saveChannel: saveChannel,
      note: note,
      createdAt: createdAt,
    );

    final batch = _paths.db.batch()
      ..set(itemRef, {
        ...item.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    if (price != null) {
      batch.set(
        _paths.priceSnapshots(uid, itemRef.id).doc(),
        PriceSnapshot(id: '', amountVnd: price, observedAt: createdAt).toMap(),
      );
    }
    await awaitWrite(batch.commit());
    return item;
  });

  @override
  Future<int?> firstPrice(String uid, String itemId) => guard(() async {
    final snapshots = await _paths
        .priceSnapshots(uid, itemId)
        .orderBy('observedAt')
        .limit(1)
        .get();
    if (snapshots.docs.isEmpty) return null;
    return PriceSnapshot.fromFirestore(snapshots.docs.first).amountVnd;
  });

  @override
  Future<void> update(String uid, WishlistItem item) => guard(() {
    final data = item.toMap()..remove('createdAt');
    return awaitWrite(
      _paths.wishlistItem(uid, item.id).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      }),
    );
  });

  @override
  Future<void> addPrice(String uid, String itemId, int amountVnd) => guard(
    () async {
      final now = DateTime.now();
      final batch = _paths.db.batch()
        ..set(
          _paths.priceSnapshots(uid, itemId).doc(),
          PriceSnapshot(id: '', amountVnd: amountVnd, observedAt: now).toMap(),
        )
        ..update(_paths.wishlistItem(uid, itemId), {
          'latestPriceVnd': amountVnd,
          'latestPriceAt': Timestamp.fromDate(now),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      await awaitWrite(batch.commit());
    },
  );

  @override
  Future<void> setReview(String uid, String itemId, DateTime reviewAt) =>
      guard(() async {
        final batch = _paths.db.batch()
          ..update(_paths.wishlistItem(uid, itemId), {
            'reviewAt': Timestamp.fromDate(reviewAt),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        _addDecision(batch, uid, itemId, DecisionChoice.wait, reviewAt);
        await awaitWrite(batch.commit());
      });

  @override
  Future<void> skip(String uid, String itemId) => guard(() async {
    final batch = _paths.db.batch()
      ..update(_paths.wishlistItem(uid, itemId), {
        'status': WishlistStatus.skipped.key,
        'decidedAt': FieldValue.serverTimestamp(),
        'reviewAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    _addDecision(batch, uid, itemId, DecisionChoice.skip, null);
    await awaitWrite(batch.commit());
  });

  @override
  Future<void> undoSkip(String uid, String itemId) => guard(() async {
    final batch = _paths.db.batch()
      ..update(_paths.wishlistItem(uid, itemId), {
        'status': WishlistStatus.considering.key,
        'decidedAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    _addDecision(batch, uid, itemId, DecisionChoice.undo, null);
    await awaitWrite(batch.commit());
  });

  @override
  Future<void> delete(String uid, String itemId) => guard(() async {
    final snapshots = await _paths.priceSnapshots(uid, itemId).get();
    final batch = _paths.db.batch();
    for (final doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_paths.wishlistItem(uid, itemId));
    await awaitWrite(batch.commit());
  });

  void _addDecision(
    WriteBatch batch,
    String uid,
    String itemId,
    DecisionChoice choice,
    DateTime? reviewAt,
  ) {
    final decision = Decision(
      id: '',
      itemId: itemId,
      choice: choice,
      at: DateTime.now(),
      reviewAt: reviewAt,
    );
    batch.set(_paths.decisions(uid).doc(), {
      ...decision.toMap(),
      'at': FieldValue.serverTimestamp(),
    });
  }
}
