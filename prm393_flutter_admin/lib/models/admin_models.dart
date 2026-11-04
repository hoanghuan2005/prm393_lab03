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

