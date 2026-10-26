import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/buying_motive.dart';
import '../models/wishlist_item.dart';
import '../models/wishlist_status.dart';

/// Service abstraction for Wishlist & Decisions using Cloud Firestore
class WishlistService {
  final FirebaseFirestore _firestore;

  WishlistService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _wishlistRef => _firestore.collection('wishlist');

  /// Stream of all wishlist items belonging to a user
  Stream<List<WishlistItem>> streamUserItems(String userId) {
    if (userId.isEmpty) {
      return Stream.value([]);
    }

    return _wishlistRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => WishlistItem.fromFirestore(doc))
              .toList();
        });
  }

  /// Add a new item to Wishlist
  Future<WishlistItem> addItem({
    required String userId,
    required String title,
    required int? priceVnd,
    required BuyingMotive motive,
    String? url,
    int coolingOffDays = 3,
  }) async {
    final now = DateTime.now();
    final item = WishlistItem(
      id: '',
      title: title,
      url: url,
      motive: motive,
      cooldownUntil: motive.skipsCooldown
          ? null
          : now.add(Duration(days: coolingOffDays)),
      latestPriceVnd: priceVnd,
      latestPriceAt: priceVnd == null ? null : now,
      createdAt: now,
    );

    // TODO(B6): move to users/{uid}/wishlistItems; userId stays only for the current top-level query
    final docRef = await _wishlistRef.add({...item.toMap(), 'userId': userId});
    return item.copyWith(id: docRef.id);
  }

  /// Update item status (Decide: Buy / Wait / Drop)
  Future<void> updateItemStatus({
    required String itemId,
    required WishlistStatus newStatus,
    String? note,
  }) async {
    await _wishlistRef.doc(itemId).update({
      'status': newStatus.key,
      'note': note,
      'decidedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Delete an item
  Future<void> deleteItem(String itemId) async {
    await _wishlistRef.doc(itemId).delete();
  }
}
