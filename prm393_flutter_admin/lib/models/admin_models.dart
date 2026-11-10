class UserAnalytics {
  final String uid;
  final String displayName;
  final String email;
  final String createdAt;
  final String lastActiveAt;
  final bool isNewToday;
  final bool isActiveToday;
  final bool isDormant; // Tải app nhưng chưa dùng
  final int totalSpending;
  final int wishlistCount;
  final int purchaseCount;
  final int monthlyBudget;
  final String device;

  const UserAnalytics({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.createdAt,
    required this.lastActiveAt,
    required this.isNewToday,
    required this.isActiveToday,
    required this.isDormant,
    required this.totalSpending,
    required this.wishlistCount,
    required this.purchaseCount,
    required this.monthlyBudget,
    required this.device,
  });
}

enum CrashSeverity { fatal, high, warning }

class CrashReport {
  final String id;
  final String feature; // Tên tính năng bị crash (e.g. "ShareIntentService")
  final String errorCode;
  final String errorMessage;
  final String stackTrace;
  final CrashSeverity severity;
  final int affectedUsers;
  final int occurrences;
  final String lastOccurred;
  final String appVersion;
  final String platform;
  final bool isResolved;

  const CrashReport({
    required this.id,
    required this.feature,
    required this.errorCode,
    required this.errorMessage,
    required this.stackTrace,
    required this.severity,
    required this.affectedUsers,
    required this.occurrences,
    required this.lastOccurred,
    required this.appVersion,
    required this.platform,
    required this.isResolved,
  });

  CrashReport copyWith({bool? isResolved}) {
    return CrashReport(
      id: id,
      feature: feature,
      errorCode: errorCode,
      errorMessage: errorMessage,
      stackTrace: stackTrace,
      severity: severity,
      affectedUsers: affectedUsers,
      occurrences: occurrences,
      lastOccurred: lastOccurred,
      appVersion: appVersion,
      platform: platform,
      isResolved: isResolved ?? this.isResolved,
    );
  }

  factory CrashReport.fromMap(Map<String, dynamic> map, String docId) {
    CrashSeverity parseSeverity(dynamic val) {
      if (val == 'fatal') return CrashSeverity.fatal;
      if (val == 'high') return CrashSeverity.high;
      return CrashSeverity.warning;
    }

    return CrashReport(
      id: docId,
      feature: map['feature'] as String? ?? 'General',
      errorCode: map['errorCode'] as String? ?? 'ERR_UNKNOWN',
      errorMessage: map['errorMessage'] as String? ?? '',
      stackTrace: map['stackTrace'] as String? ?? '',
      severity: parseSeverity(map['severity']),
      affectedUsers: (map['affectedUsers'] as num?)?.toInt() ?? 1,
      occurrences: (map['occurrences'] as num?)?.toInt() ?? 1,
      lastOccurred: map['lastOccurred'] as String? ?? 'Vừa xong',
      appVersion: map['appVersion'] as String? ?? '1.0.0',
      platform: map['platform'] as String? ?? 'Android',
      isResolved: map['isResolved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'feature': feature,
      'errorCode': errorCode,
      'errorMessage': errorMessage,
      'stackTrace': stackTrace,
      'severity': severity.name,
      'affectedUsers': affectedUsers,
      'occurrences': occurrences,
      'lastOccurred': lastOccurred,
      'appVersion': appVersion,
      'platform': platform,
      'isResolved': isResolved,
    };
  }
}

class PushBroadcast {
  final String id;
  final String title;
  final String body;
  final String targetAudience;
  final String? targetUserId;
  final String targetScreen;
  final String sentAt;
  final int deliveredCount;
  final String openRate;

  const PushBroadcast({
    required this.id,
    required this.title,
    required this.body,
    required this.targetAudience,
    this.targetUserId,
    required this.targetScreen,
    required this.sentAt,
    required this.deliveredCount,
    required this.openRate,
  });
}

class AiSuggestion {
  final String id;
  final String category;
  final String categoryLabel;
  final String question;
  final String psychologyInsight;
  final String suggestedTitle;
  final String suggestedBody;
  final String targetScreen;

  const AiSuggestion({
    required this.id,
    required this.category,
    required this.categoryLabel,
    required this.question,
    required this.psychologyInsight,
    required this.suggestedTitle,
    required this.suggestedBody,
    required this.targetScreen,
  });
}

class DashboardMetrics {
  final int totalUsers;
  final int newUsersToday;
  final int activeUsersToday;
  final int dormantUsers;
  final int totalSpendingVnd;
  final int totalWishlistItems;
  final int activeCrashesCount;
  final double crashFreeUsersRate;

  const DashboardMetrics({
    required this.totalUsers,
    required this.newUsersToday,
    required this.activeUsersToday,
    required this.dormantUsers,
    required this.totalSpendingVnd,
    required this.totalWishlistItems,
    required this.activeCrashesCount,
    required this.crashFreeUsersRate,
  });

  DashboardMetrics copyWith({
    int? totalUsers,
    int? newUsersToday,
    int? activeUsersToday,
    int? dormantUsers,
    int? totalSpendingVnd,
    int? totalWishlistItems,
    int? activeCrashesCount,
    double? crashFreeUsersRate,
  }) {
    return DashboardMetrics(
      totalUsers: totalUsers ?? this.totalUsers,
      newUsersToday: newUsersToday ?? this.newUsersToday,
      activeUsersToday: activeUsersToday ?? this.activeUsersToday,
      dormantUsers: dormantUsers ?? this.dormantUsers,
      totalSpendingVnd: totalSpendingVnd ?? this.totalSpendingVnd,
      totalWishlistItems: totalWishlistItems ?? this.totalWishlistItems,
      activeCrashesCount: activeCrashesCount ?? this.activeCrashesCount,
      crashFreeUsersRate: crashFreeUsersRate ?? this.crashFreeUsersRate,
    );
  }
}

class VoucherItem {
  final String id;
  final String code;
  final String title;
  final String platform; // 'Shopee', 'Lazada', 'Tất cả'
  final int discountAmount; // VND (e.g. 30000)
  final int minOrder; // VND (e.g. 150000)
  final String validUntil; // formatted or ISO (e.g. '2026-11-15')
  final String affiliateUrl;
  final bool isActive;
  final String category; // 'Tất cả', 'Thời trang', 'Công nghệ', v.v.

  const VoucherItem({
    required this.id,
    required this.code,
    required this.title,
    required this.platform,
    required this.discountAmount,
    required this.minOrder,
    required this.validUntil,
    this.affiliateUrl = '',
    this.isActive = true,
    this.category = 'Tất cả',
  });

  VoucherItem copyWith({
    String? id,
    String? code,
    String? title,
    String? platform,
    int? discountAmount,
    int? minOrder,
    String? validUntil,
    String? affiliateUrl,
    bool? isActive,
    String? category,
  }) {
    return VoucherItem(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      platform: platform ?? this.platform,
      discountAmount: discountAmount ?? this.discountAmount,
      minOrder: minOrder ?? this.minOrder,
      validUntil: validUntil ?? this.validUntil,
      affiliateUrl: affiliateUrl ?? this.affiliateUrl,
      isActive: isActive ?? this.isActive,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'platform': platform,
      'discountAmount': discountAmount,
      'minOrder': minOrder,
      'validUntil': validUntil,
      'affiliateUrl': affiliateUrl,
      'isActive': isActive,
      'category': category,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  factory VoucherItem.fromMap(Map<String, dynamic> map, [String? docId]) {
    return VoucherItem(
      id: docId ?? map['id']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      platform: map['platform']?.toString() ?? 'Shopee',
      discountAmount: (map['discountAmount'] as num?)?.toInt() ?? 0,
      minOrder: (map['minOrder'] as num?)?.toInt() ?? 0,
      validUntil: map['validUntil']?.toString() ?? '',
      affiliateUrl: map['affiliateUrl']?.toString() ?? '',
      isActive: map['isActive'] == true || map['isActive'] == null,
      category: map['category']?.toString() ?? 'Tất cả',
    );
  }
}

class AdminSaleEvent {
  final String id;
  final String name;
  final String date;
  final String type; // 'double_day', 'mid_month', 'payday', 'other'
  final bool confirmed;
  final String highlight;

  const AdminSaleEvent({
    required this.id,
    required this.name,
    required this.date,
    required this.type,
    this.confirmed = true,
    this.highlight = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date,
      'type': type,
      'confirmed': confirmed,
      'highlight': highlight,
    };
  }

  factory AdminSaleEvent.fromMap(Map<String, dynamic> map) {
    return AdminSaleEvent(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      type: map['type']?.toString() ?? 'other',
      confirmed: map['confirmed'] == true,
      highlight: map['highlight']?.toString() ?? '',
    );
  }
}


