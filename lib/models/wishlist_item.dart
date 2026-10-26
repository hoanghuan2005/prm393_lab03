import 'package:cloud_firestore/cloud_firestore.dart';

import 'buying_motive.dart';
import 'item_status.dart';

/// Wishlist Item Data Model for Why I Buy
class WishlistItem {
  final String id;
  final String userId;
  final String title;
  final double price;
  final BuyingMotive motive;
  final ItemStatus status;
  final String? productUrl;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? coolingOffUntil;
  final String? note;
  final DateTime? decidedAt;

  const WishlistItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.price,
    required this.motive,
    this.status = ItemStatus.considering,
    this.productUrl,
    this.imageUrl,
    required this.createdAt,
    this.coolingOffUntil,
    this.note,
    this.decidedAt,
  });

  /// Check whether the item is still in psychological cooldown
  bool get isInCooldown {
    if (status != ItemStatus.considering || coolingOffUntil == null) {
      return false;
    }
    return DateTime.now().isBefore(coolingOffUntil!);
  }

  /// Remaining cooldown duration
  Duration get remainingCooldown {
    if (!isInCooldown || coolingOffUntil == null) return Duration.zero;
    return coolingOffUntil!.difference(DateTime.now());
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'price': price,
      'motive': motive.key,
      'status': status.key,
      'productUrl': productUrl,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'coolingOffUntil': coolingOffUntil != null
          ? Timestamp.fromDate(coolingOffUntil!)
          : null,
      'note': note,
      'decidedAt': decidedAt != null ? Timestamp.fromDate(decidedAt!) : null,
    };
  }

  factory WishlistItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return WishlistItem(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? 'Sản phẩm chưa đặt tên',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      motive: BuyingMotive.fromKey(data['motive'] as String?),
      status: ItemStatus.fromKey(data['status'] as String?),
      productUrl: data['productUrl'] as String?,
      imageUrl: data['imageUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      coolingOffUntil: (data['coolingOffUntil'] as Timestamp?)?.toDate(),
      note: data['note'] as String?,
      decidedAt: (data['decidedAt'] as Timestamp?)?.toDate(),
    );
  }

  WishlistItem copyWith({
    String? id,
    String? userId,
    String? title,
    double? price,
    BuyingMotive? motive,
    ItemStatus? status,
    String? productUrl,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? coolingOffUntil,
    String? note,
    DateTime? decidedAt,
  }) {
    return WishlistItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      price: price ?? this.price,
      motive: motive ?? this.motive,
      status: status ?? this.status,
      productUrl: productUrl ?? this.productUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      coolingOffUntil: coolingOffUntil ?? this.coolingOffUntil,
      note: note ?? this.note,
      decidedAt: decidedAt ?? this.decidedAt,
    );
  }
}
