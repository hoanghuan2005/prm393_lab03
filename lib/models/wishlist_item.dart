import 'package:cloud_firestore/cloud_firestore.dart';

import 'buying_motive.dart';
import 'firestore_fields.dart';
import 'wishlist_status.dart';

/// How the item reached the wishlist
enum SaveChannel {
  manual('manual'),
  share('share'),
  extension('extension');

  final String key;

  const SaveChannel(this.key);

  static SaveChannel fromKey(String? key) => SaveChannel.values.firstWhere(
    (c) => c.key == key,
    orElse: () => SaveChannel.manual,
  );
}

/// users/{uid}/wishlistItems/{itemId}
class WishlistItem {
  static const int defaultPriority = 3;

  final String id;
  final String title;
  final String? url;
  final BuyingMotive? motive;
  final int priority;
  final WishlistStatus status;
  final DateTime? cooldownUntil;
  final DateTime? reviewAt;
  final String? budgetGroupId;

  /// null = price not known yet (never stored as 0)
  final int? latestPriceVnd;
  final DateTime? latestPriceAt;
  final SaveChannel saveChannel;
  final String? purchaseId;
  final String? note;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? decidedAt;

  const WishlistItem({
    required this.id,
    required this.title,
    this.url,
    this.motive,
    this.priority = defaultPriority,
    this.status = WishlistStatus.considering,
    this.cooldownUntil,
    this.reviewAt,
    this.budgetGroupId,
    this.latestPriceVnd,
    this.latestPriceAt,
    this.saveChannel = SaveChannel.manual,
    this.purchaseId,
    this.note,
    required this.createdAt,
    this.updatedAt,
    this.decidedAt,
  });

  bool get hasPrice => latestPriceVnd != null;

  /// Motive for display; items saved without one show as "Khác"
  BuyingMotive get displayMotive => motive ?? BuyingMotive.other;

  bool get isInCooldown =>
      status == WishlistStatus.considering &&
      cooldownUntil != null &&
      DateTime.now().isBefore(cooldownUntil!);

  Duration get remainingCooldown =>
      isInCooldown ? cooldownUntil!.difference(DateTime.now()) : Duration.zero;

  /// User chose "Chờ" and the review date has not come yet
  bool get isWaiting =>
      status == WishlistStatus.considering &&
      reviewAt != null &&
      reviewAt!.isAfter(DateTime.now());

  /// The review date chosen with "Chờ" has arrived and the item is still undecided
  bool get isReviewDue =>
      status == WishlistStatus.considering &&
      reviewAt != null &&
      !reviewAt!.isAfter(DateTime.now());

  int get daysSinceCreated => DateTime.now().difference(createdAt).inDays;

  /// Whole days left until [reviewAt] (0 when due), null when no review is scheduled
  int? get daysUntilReview {
    if (reviewAt == null) return null;
    final hours = reviewAt!.difference(DateTime.now()).inHours;
    return hours <= 0 ? 0 : (hours / 24).ceil();
  }

  /// Legacy documents used `price` (double, 0 = no price), `productUrl`, `coolingOffUntil`
  factory WishlistItem.fromFirestore(DocumentSnapshot doc) {
    final data = docData(doc);
    final motiveKey = readString(data['motive']);
    return WishlistItem(
      id: doc.id,
      title: readText(data['title']) ?? 'Sản phẩm chưa đặt tên',
      url: readText(data['url'] ?? data['productUrl']),
      motive: motiveKey == null ? null : BuyingMotive.fromKey(motiveKey),
      priority: (readInt(data['priority']) ?? defaultPriority).clamp(1, 5),
      status: WishlistStatus.fromKey(readString(data['status'])),
      cooldownUntil: readDate(data['cooldownUntil'] ?? data['coolingOffUntil']),
      reviewAt: readDate(data['reviewAt']),
      budgetGroupId: readText(data['budgetGroupId']),
      latestPriceVnd: readVnd(data['latestPriceVnd'] ?? data['price']),
      latestPriceAt: readDate(data['latestPriceAt']),
      saveChannel: SaveChannel.fromKey(readString(data['saveChannel'])),
      purchaseId: readText(data['purchaseId']),
      note: readText(data['note']),
      createdAt: readDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: readDate(data['updatedAt']),
      decidedAt: readDate(data['decidedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'url': url,
      'motive': motive?.key,
      'priority': priority,
      'status': status.key,
      'cooldownUntil': toTimestamp(cooldownUntil),
      'reviewAt': toTimestamp(reviewAt),
      'budgetGroupId': budgetGroupId,
      'latestPriceVnd': latestPriceVnd,
      'latestPriceAt': toTimestamp(latestPriceAt),
      'saveChannel': saveChannel.key,
      'purchaseId': purchaseId,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': toTimestamp(updatedAt),
      'decidedAt': toTimestamp(decidedAt),
    };
  }

  WishlistItem copyWith({
    String? id,
    String? title,
    String? url,
    BuyingMotive? motive,
    int? priority,
    WishlistStatus? status,
    DateTime? cooldownUntil,
    DateTime? reviewAt,
    String? budgetGroupId,
    int? latestPriceVnd,
    DateTime? latestPriceAt,
    SaveChannel? saveChannel,
    String? purchaseId,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? decidedAt,
  }) {
    return WishlistItem(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      motive: motive ?? this.motive,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      cooldownUntil: cooldownUntil ?? this.cooldownUntil,
      reviewAt: reviewAt ?? this.reviewAt,
      budgetGroupId: budgetGroupId ?? this.budgetGroupId,
      latestPriceVnd: latestPriceVnd ?? this.latestPriceVnd,
      latestPriceAt: latestPriceAt ?? this.latestPriceAt,
      saveChannel: saveChannel ?? this.saveChannel,
      purchaseId: purchaseId ?? this.purchaseId,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      decidedAt: decidedAt ?? this.decidedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WishlistItem &&
          other.id == id &&
          other.title == title &&
          other.url == url &&
          other.motive == motive &&
          other.priority == priority &&
          other.status == status &&
          other.cooldownUntil == cooldownUntil &&
          other.reviewAt == reviewAt &&
          other.budgetGroupId == budgetGroupId &&
          other.latestPriceVnd == latestPriceVnd &&
          other.latestPriceAt == latestPriceAt &&
          other.saveChannel == saveChannel &&
          other.purchaseId == purchaseId &&
          other.note == note &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.decidedAt == decidedAt;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    url,
    motive,
    priority,
    status,
    cooldownUntil,
    reviewAt,
    budgetGroupId,
    latestPriceVnd,
    latestPriceAt,
    saveChannel,
    purchaseId,
    note,
    createdAt,
    updatedAt,
    decidedAt,
  );
}
