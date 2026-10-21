import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/buying_motive.dart';
import '../models/item_status.dart';
import '../models/wishlist_item.dart';

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
      return snapshot.docs.map((doc) => WishlistItem.fromFirestore(doc)).toList();
    });
  }

  /// Add a new item to Wishlist
  Future<WishlistItem> addItem({
    required String userId,
    required String title,
    required double price,
    required BuyingMotive motive,
    String? productUrl,
    String? imageUrl,
    int coolingOffDays = 3,
  }) async {
    final now = DateTime.now();
    DateTime? coolingOffUntil;
    if (motive.triggersCooldown) {
      coolingOffUntil = now.add(Duration(days: coolingOffDays));
    }

    final data = {
      'userId': userId,
      'title': title,
      'price': price,
      'motive': motive.key,
      'status': ItemStatus.considering.key,
      'productUrl': productUrl,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(now),
      'coolingOffUntil': coolingOffUntil != null ? Timestamp.fromDate(coolingOffUntil) : null,
      'note': null,
      'decidedAt': null,
    };

    final docRef = await _wishlistRef.add(data);
    return WishlistItem(
      id: docRef.id,
      userId: userId,
      title: title,
      price: price,
      motive: motive,
      status: ItemStatus.considering,
      productUrl: productUrl,
      imageUrl: imageUrl,
      createdAt: now,
      coolingOffUntil: coolingOffUntil,
    );
  }

  /// Update item status (Decide: Buy / Wait / Drop)
  Future<void> updateItemStatus({
    required String itemId,
    required ItemStatus newStatus,
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
