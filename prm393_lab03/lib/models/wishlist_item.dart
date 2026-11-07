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

  /// The user confirmed this is the same as something owned or bought in the last
  /// 30 days (Decision Card label 5, spec 7.4)
  final bool confirmedDuplicate;

  /// Written by the Chrome extension: `shopee:<shopId>:<itemId>`, the chosen variant,
  /// Shopee's model id and product image
  final String? productKey;
  final String? variantLabel;
  final String? modelId;
  final String? imageUrl;
  final String? shopName;

  /// Read from the Shopee page by the extension: product stars (0–5], number of
  /// reviews and the shop's stars
  final double? productRating;
  final int? productRatingCount;
  final double? shopRating;

  /// The user pressed "Mua" in the extension; only the app records the purchase
  final DateTime? buyIntentAt;

  /// G2c: a sample item an admin added from the Firebase Demo Area to try the price
  /// features. Shown with "Dữ liệu mẫu", left out of the stats, never shared (G7).
  final bool isDemo;

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
    this.confirmedDuplicate = false,
    this.productKey,
    this.variantLabel,
    this.modelId,
    this.imageUrl,
    this.shopName,
    this.productRating,
    this.productRatingCount,
    this.shopRating,
    this.buyIntentAt,
    this.isDemo = false,
  });

  bool get hasPrice => latestPriceVnd != null;

  bool get isFromExtension => saveChannel == SaveChannel.extension;

  /// Still undecided and marked "Mua" in the extension: waiting for the purchase form
  bool get hasBuyIntent =>
      status == WishlistStatus.considering && buyIntentAt != null;

  /// Motive for display; items saved without one show as "Khác"
  BuyingMotive get displayMotive => motive ?? BuyingMotive.other;

  bool get isInCooldown =>
      status == WishlistStatus.considering &&
      cooldownUntil != null &&
      DateTime.now().isBefore(cooldownUntil!);

  Duration get remainingCooldown =>
      isInCooldown ? cooldownUntil!.difference(DateTime.now()) : Duration.zero;

  /// Short countdown, rounded up: a 3-day item saved a minute ago reads "3 ngày", not "2 ngày"
  String get remainingCooldownLabel {
    final minutes = remainingCooldown.inMinutes;
    if (minutes >= Duration.minutesPerDay) {
      return '${(minutes / Duration.minutesPerDay).ceil()} ngày';
    }
    final hours = (minutes / Duration.minutesPerHour).ceil();
    return '${hours < 1 ? 1 : hours} giờ';
  }

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
      confirmedDuplicate: data['confirmedDuplicate'] == true,
      productKey: readText(data['productKey']),
      variantLabel: readText(data['variantLabel']),
      modelId: readText(data['modelId']),
      imageUrl: readText(data['imageUrl']),
      shopName: readText(data['shopName']),
      productRating: readRating(data['productRating']),
      productRatingCount: readCount(data['productRatingCount']),
      shopRating: readRating(data['shopRating']),
      buyIntentAt: readDate(data['buyIntentAt']),
      isDemo: data['isDemo'] == true,
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
      'confirmedDuplicate': confirmedDuplicate,
      // Extension fields are only written when known, so an app edit never wipes them.
      // buyIntentAt is cleared by its own write (clearBuyIntent, buyFromWishlist).
      if (productKey != null) 'productKey': productKey,
      if (variantLabel != null) 'variantLabel': variantLabel,
      if (modelId != null) 'modelId': modelId,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (shopName != null) 'shopName': shopName,
      if (productRating != null) 'productRating': productRating,
      if (productRatingCount != null) 'productRatingCount': productRatingCount,
      if (shopRating != null) 'shopRating': shopRating,
      if (buyIntentAt != null) 'buyIntentAt': toTimestamp(buyIntentAt),
      if (isDemo) 'isDemo': true,
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
    bool? confirmedDuplicate,
    String? productKey,
    String? variantLabel,
    String? modelId,
    String? imageUrl,
    String? shopName,
    double? productRating,
    int? productRatingCount,
    double? shopRating,
    DateTime? buyIntentAt,
    bool clearBuyIntent = false,
    bool? isDemo,
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
      confirmedDuplicate: confirmedDuplicate ?? this.confirmedDuplicate,
      productKey: productKey ?? this.productKey,
      variantLabel: variantLabel ?? this.variantLabel,
      modelId: modelId ?? this.modelId,
      imageUrl: imageUrl ?? this.imageUrl,
      shopName: shopName ?? this.shopName,
      productRating: productRating ?? this.productRating,
      productRatingCount: productRatingCount ?? this.productRatingCount,
      shopRating: shopRating ?? this.shopRating,
      buyIntentAt: clearBuyIntent ? null : buyIntentAt ?? this.buyIntentAt,
      isDemo: isDemo ?? this.isDemo,
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
          other.decidedAt == decidedAt &&
          other.confirmedDuplicate == confirmedDuplicate &&
          other.productKey == productKey &&
          other.variantLabel == variantLabel &&
          other.modelId == modelId &&
          other.imageUrl == imageUrl &&
          other.shopName == shopName &&
          other.productRating == productRating &&
          other.productRatingCount == productRatingCount &&
          other.shopRating == shopRating &&
          other.buyIntentAt == buyIntentAt &&
          other.isDemo == isDemo;

  @override
  int get hashCode => Object.hashAll([
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
    confirmedDuplicate,
    productKey,
    variantLabel,
    modelId,
    imageUrl,
    shopName,
    productRating,
    productRatingCount,
    shopRating,
    buyIntentAt,
    isDemo,
  ]);
}
