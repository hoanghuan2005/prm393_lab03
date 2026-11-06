import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/admin_models.dart';
import '../data/mock_admin_data.dart';
import '../theme/admin_colors.dart';

class AdminService extends ChangeNotifier {
  static const adminEmail = 'admin@gmail.com';
  static const pushApiBaseUrl = String.fromEnvironment(
    'PUSH_API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
  int _selectedTabIndex = 0;
  bool _isLiveFirebase = false;
  bool _isLoading = false;
  bool _isDarkMode = true;
  String? _liveDataError;

  DashboardMetrics _metrics = MockAdminData.defaultMetrics;
  List<UserAnalytics> _users = List.from(MockAdminData.defaultUsers);
  final List<CrashReport> _crashes = List.from(MockAdminData.defaultCrashes);
  final List<PushBroadcast> _broadcasts = List.from(
    MockAdminData.defaultBroadcasts,
  );
  final List<AiSuggestion> _aiSuggestions = List.from(
    MockAdminData.defaultAiSuggestions,
  );

  UserAnalytics? _preselectedUser;

  // Pre-filled broadcast draft (from AI or preselection)
  String draftTitle = '';
  String draftBody = '';
  String draftScreen = 'wishlist_add';
  String draftTarget = 'dormant';

  int get selectedTabIndex => _selectedTabIndex;
  bool get isLiveFirebase => _isLiveFirebase;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;
  String? get liveDataError => _liveDataError;
  User? get adminUser => FirebaseAuth.instance.currentUser;
  DashboardMetrics get metrics => _metrics;
  List<UserAnalytics> get users => _users;
  List<CrashReport> get crashes => _crashes;
  List<PushBroadcast> get broadcasts => _broadcasts;
  List<AiSuggestion> get aiSuggestions => _aiSuggestions;
  UserAnalytics? get preselectedUser => _preselectedUser;

  int get activeCrashesCount => _crashes.where((c) => !c.isResolved).length;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    AdminColors.isDark = _isDarkMode;
    notifyListeners();
  }

  void selectTab(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  void selectUserForPush(UserAnalytics user) {
    _preselectedUser = user;
    draftTitle =
        'Chào ${user.displayName}, bạn có món đồ nào đang cân nhắc không?';
    draftBody = 'Đừng quên chia sẻ link Shopee/Lazada vào Why I Buy để kích hoạt thời gian 48 giờ suy nghĩ nhé!';
    draftTarget = 'specific';
    draftScreen = 'wishlist_add';
    _selectedTabIndex = 2; // Jump to Push tab
    notifyListeners();
  }

  void clearPreselectedUser() {
    _preselectedUser = null;
    notifyListeners();
  }

  void applyAiSuggestionToPush(AiSuggestion item) {
    draftTitle = item.suggestedTitle;
    draftBody = item.suggestedBody;
    draftScreen = item.targetScreen;
    draftTarget = item.category == 'dormant' ? 'dormant' : 'all';
    _selectedTabIndex = 2; // Jump to Push tab
    notifyListeners();
  }

  void resolveCrash(String id) {
    final index = _crashes.indexWhere((c) => c.id == id);
    if (index != -1) {
      _crashes[index] = _crashes[index].copyWith(isResolved: true);
      _metrics = _metrics.copyWith(
        activeCrashesCount: (_metrics.activeCrashesCount - 1).clamp(0, 999),
      );
      notifyListeners();
    }
  }

  Future<void> sendBroadcast({
    required String title,
    required String body,
    required String targetAudience,
    required String targetScreen,
  }) async {
    if (!_isLiveFirebase) {
      throw StateError('Hãy bật Firebase Live trước khi gửi thông báo.');
    }

    final newBc = PushBroadcast(
      id: 'bc_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      targetAudience: targetAudience,
      targetUserId: _preselectedUser?.uid,
      targetScreen: targetScreen,
      sentAt: 'Vừa xong',
      deliveredCount: targetAudience == 'dormant'
          ? _metrics.dormantUsers
          : _metrics.activeUsersToday,
      openRate: '0.0%',
    );

    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) {
        throw StateError('Phiên Admin đã hết hạn, hãy đăng nhập lại.');
      }
      final response = await http.post(
        Uri.parse('$pushApiBaseUrl/api/notifications/send'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': title,
          'body': body,
          'targetAudience': targetAudience,
          'targetUserId': newBc.targetUserId,
          'targetScreen': targetScreen,
        }),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(
          'Push service lỗi ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Push service error: $e');
      rethrow;
    }

    _broadcasts.insert(0, newBc);
    _preselectedUser = null;
    notifyListeners();
  }

  Future<void> toggleLiveFirebase() async {
    _isLiveFirebase = !_isLiveFirebase;
    notifyListeners();

    if (_isLiveFirebase) {
      await fetchFirebaseData();
    } else {
      _liveDataError = null;
      _users = List.from(MockAdminData.defaultUsers);
      _metrics = MockAdminData.defaultMetrics;
      notifyListeners();
    }
  }

  Future<void> fetchFirebaseData() async {
    if (!_isLiveFirebase) return;
    _isLoading = true;
    _liveDataError = null;
    _users = [];
    _metrics = const DashboardMetrics(
      totalUsers: 0,
      newUsersToday: 0,
      activeUsersToday: 0,
      dormantUsers: 0,
      totalSpendingVnd: 0,
      totalWishlistItems: 0,
      activeCrashesCount: 0,
      crashFreeUsersRate: 0,
    );
    notifyListeners();

    var readStage = 'xác thực Admin';
    try {
      final admin = FirebaseAuth.instance.currentUser;
      if (admin == null || admin.email != adminEmail) {
        throw StateError(
          'Phiên Admin không hợp lệ (${admin?.email ?? 'chưa đăng nhập'}).',
        );
      }
      await admin.getIdToken(true);

      readStage = 'đọc users';
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      final liveUsers = await Future.wait(
        snapshot.docs.map((doc) async {
          final data = doc.data();
          readStage = 'đọc purchases của ${doc.id}';
          final purchases = await doc.reference.collection('purchases').get();
          readStage = 'đọc wishlistItems của ${doc.id}';
          final wishlist = await doc.reference
              .collection('wishlistItems')
              .get();
          var totalSpending = 0;
          DateTime? latestActivity;
          for (final purchase in purchases.docs) {
            final purchaseData = purchase.data();
            totalSpending +=
                (purchaseData['amountVnd'] as num?)?.toInt() ??
                (purchaseData['amount'] as num?)?.toInt() ??
                0;
            final occurredAt = _readDate(
              purchaseData['occurredAt'] ?? purchaseData['dateTime'],
            );
            if (occurredAt != null &&
                (latestActivity == null ||
                    occurredAt.isAfter(latestActivity))) {
              latestActivity = occurredAt;
            }
          }
          final createdAt = _readDate(data['createdAt']);
          latestActivity ??= createdAt;
          final isActiveToday =
              latestActivity != null &&
              _sameDay(latestActivity, DateTime.now());
          return UserAnalytics(
            uid: doc.id,
            displayName:
                data['displayName'] ??
                data['name'] ??
                'User ${doc.id.substring(0, 4)}',
            email: data['email'] ?? '',
            createdAt: _formatDateTime(createdAt),
            lastActiveAt: _formatDateTime(latestActivity),
            isNewToday:
                createdAt != null && _sameDay(createdAt, DateTime.now()),
            isActiveToday: isActiveToday,
            isDormant: purchases.docs.isEmpty && wishlist.docs.isEmpty,
            totalSpending: totalSpending,
            wishlistCount: wishlist.docs.length,
            purchaseCount: purchases.docs.length,
            monthlyBudget: (data['monthlyBudget'] as num?)?.toInt() ?? 0,
            device: data['device'] as String? ?? 'Chưa xác định',
          );
        }),
      );

      _users = liveUsers;
      _metrics = _metrics.copyWith(
        totalUsers: liveUsers.length,
        newUsersToday: liveUsers.where((u) => u.isNewToday).length,
        activeUsersToday: liveUsers.where((u) => u.isActiveToday).length,
        dormantUsers: liveUsers.where((u) => u.isDormant).length,
        totalSpendingVnd: liveUsers.fold<int>(
          0,
          (total, user) => total + user.totalSpending,
        ),
        totalWishlistItems: liveUsers.fold<int>(
          0,
          (total, user) => total + user.wishlistCount,
        ),
      );
    } catch (e) {
      _liveDataError = 'Không thể tải dữ liệu Firebase ($readStage): $e';
      debugPrint('Firestore fetch error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  static DateTime? _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  static String _formatDateTime(DateTime? value) {
    if (value == null) return 'Chưa có hoạt động';
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${value.year}-${twoDigits(value.month)}-${twoDigits(value.day)} '
        '${twoDigits(value.hour)}:${twoDigits(value.minute)}';
  }
}
