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
  List<VoucherItem> _vouchers = List.from(MockAdminData.defaultVouchers);
  final List<AdminSaleEvent> _saleEvents = List.from(
    MockAdminData.defaultSaleEvents,
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
  List<VoucherItem> get vouchers => _vouchers;
  List<AdminSaleEvent> get saleEvents => _saleEvents;
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

  Future<void> addVoucher(VoucherItem item) async {
    _vouchers.removeWhere((v) => v.id == item.id || v.code.toUpperCase() == item.code.toUpperCase());
    _vouchers.insert(0, item);
    notifyListeners();
    if (_isLiveFirebase) {
      try {
        await FirebaseFirestore.instance.collection('vouchers').doc(item.id).set(item.toMap());
      } catch (e) {
        debugPrint('Lỗi lưu voucher Firestore: $e');
      }
    }
  }

  Future<void> toggleVoucherActive(String id) async {
    final idx = _vouchers.indexWhere((v) => v.id == id);
    if (idx != -1) {
      final updated = _vouchers[idx].copyWith(isActive: !_vouchers[idx].isActive);
      _vouchers[idx] = updated;
      notifyListeners();
      if (_isLiveFirebase) {
        try {
          await FirebaseFirestore.instance.collection('vouchers').doc(id).update({'isActive': updated.isActive});
        } catch (e) {
          debugPrint('Lỗi cập nhật voucher: $e');
        }
      }
    }
  }

  Future<void> deleteVoucher(String id) async {
    _vouchers.removeWhere((v) => v.id == id);
    notifyListeners();
    if (_isLiveFirebase) {
      try {
        await FirebaseFirestore.instance.collection('vouchers').doc(id).delete();
      } catch (e) {
        debugPrint('Lỗi xóa voucher: $e');
      }
    }
  }

  void applyVoucherToPush(VoucherItem voucher) {
    final moneyStr = voucher.discountAmount >= 1000
        ? '${(voucher.discountAmount / 1000).toStringAsFixed(0)}K'
        : '${voucher.discountAmount}đ';
    draftTitle = '🎟️ Có Voucher ${voucher.platform} Giảm $moneyStr!';
    draftBody = 'Mã "${voucher.code}": Giảm $moneyStr cho đơn từ ${voucher.minOrder ~/ 1000}K. Kiểm tra giỏ hàng Why I Buy ngay!';
    draftScreen = 'wishlist';
    draftTarget = 'all';
    _selectedTabIndex = 2; // Chuyển sang Tab Gửi Push
    notifyListeners();
  }

  Future<void> sendVoucherPushDirect(VoucherItem voucher) async {
    final moneyStr = voucher.discountAmount >= 1000
        ? '${(voucher.discountAmount / 1000).toStringAsFixed(0)}K'
        : '${voucher.discountAmount}đ';
    final title = '🎟️ Có Voucher ${voucher.platform} Giảm $moneyStr!';
    final body =
        'Mã "${voucher.code}": Giảm $moneyStr cho đơn từ ${voucher.minOrder ~/ 1000}K. Kiểm tra giỏ hàng Why I Buy ngay!';
    await sendBroadcast(
      title: title,
      body: body,
      targetAudience: 'all',
      targetScreen: 'wishlist',
    );
  }

  Future<void> sendSaleEventPushDirect(AdminSaleEvent event) async {
    final title = '🔥 Sắp tới ngày ${event.name}!';
    final body =
        'Đợt sale lớn nhất đang đến gần: ${event.highlight}. Hãy kiểm tra các món trong Wishlist của bạn để chuẩn bị săn deal nhé!';
    await sendBroadcast(
      title: title,
      body: body,
      targetAudience: 'all',
      targetScreen: 'wishlist',
    );
  }

  Future<void> syncStandardSalesCalendar() async {
    final now = DateTime.now();
    final m = now.month;
    final nextM = (m % 12) + 1;
    final year = now.year;
    final nextYear = m == 12 ? year + 1 : year;

    final standardSales = [
      AdminSaleEvent(
        id: 'sale_${m}_$m',
        name: '$m.$m Siêu Sale Ngày Đôi',
        date: '$year-${m.toString().padLeft(2, '0')}-${m.toString().padLeft(2, '0')}',
        type: 'double_day',
        confirmed: true,
        highlight: 'Freeship 0Đ, Voucher mở lúc 0h - 9h - 12h - 21h',
      ),
      AdminSaleEvent(
        id: 'sale_15_$m',
        name: '15.$m Sale Giữa Tháng',
        date: '$year-${m.toString().padLeft(2, '0')}-15',
        type: 'mid_month',
        confirmed: true,
        highlight: 'Đại tiệc voucher nửa tháng, hoàn xu xtra lên đến 50%',
      ),
      AdminSaleEvent(
        id: 'sale_25_$m',
        name: '25.$m Lương Về Sale Đậm',
        date: '$year-${m.toString().padLeft(2, '0')}-25',
        type: 'payday',
        confirmed: true,
        highlight: 'Ưu đãi ngày lương, trợ giá đơn hàng lớn từ 500k',
      ),
      AdminSaleEvent(
        id: 'sale_${nextM}_$nextM',
        name: '$nextM.$nextM Siêu Sale Kế Tiếp',
        date: '$nextYear-${nextM.toString().padLeft(2, '0')}-${nextM.toString().padLeft(2, '0')}',
        type: 'double_day',
        confirmed: true,
        highlight: 'Đại tiệc ngày đôi kế tiếp, chuẩn bị săn mã sớm',
      ),
    ];

    for (final s in standardSales) {
      if (!_saleEvents.any((e) => e.id == s.id)) {
        _saleEvents.add(s);
      }
    }
    notifyListeners();
  }

  Future<int> autoGenerateSampleShopeePromotions() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sampleList = [
      VoucherItem(
        id: 'vouch_${timestamp}_1',
        code: 'SHOPEE50K',
        title: 'Mã Giảm 50.000đ Toàn Sàn Shopee Đơn Từ 250K',
        platform: 'Shopee',
        discountAmount: 50000,
        minOrder: 250000,
        validUntil: '2026-11-15',
        affiliateUrl: 'https://shopee.vn/m/ma-giam-gia',
        isActive: true,
        category: 'Tất cả',
      ),
      VoucherItem(
        id: 'vouch_${timestamp}_2',
        code: 'FREESHIPEXTRA',
        title: 'Freeship Xtra Giảm 30K Phí Ship Mọi Đơn Hàng',
        platform: 'Shopee',
        discountAmount: 30000,
        minOrder: 50000,
        validUntil: '2026-11-30',
        affiliateUrl: 'https://shopee.vn/m/mien-phi-van-chuyen',
        isActive: true,
        category: 'Tất cả',
      ),
      VoucherItem(
        id: 'vouch_${timestamp}_3',
        code: 'TECH100K',
        title: 'Mã Hoàn Xu Điện Tử 10% Tối Đa 100K',
        platform: 'Shopee',
        discountAmount: 100000,
        minOrder: 500000,
        validUntil: '2026-11-20',
        affiliateUrl: 'https://shopee.vn/m/tech-zone',
        isActive: true,
        category: 'Công nghệ',
      ),
    ];

    var count = 0;
    for (final v in sampleList) {
      await addVoucher(v);
      count++;
    }
    return count;
  }

  Future<void> sendBroadcast({
    required String title,
    required String body,
    required String targetAudience,
    required String targetScreen,
  }) async {
    final newBc = PushBroadcast(
      id: 'bc_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      targetAudience: targetAudience,
      targetUserId: _preselectedUser?.uid,
      targetScreen: targetScreen,
      sentAt: _isLiveFirebase ? 'Vừa xong' : 'Vừa xong (Demo)',
      deliveredCount: targetAudience == 'dormant'
          ? _metrics.dormantUsers
          : _metrics.activeUsersToday,
      openRate: '0.0%',
    );

    if (_isLiveFirebase) {
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
      _vouchers = List.from(MockAdminData.defaultVouchers);
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

      // Fetch live vouchers if collection exists
      try {
        final voucherSnap = await FirebaseFirestore.instance.collection('vouchers').get();
        if (voucherSnap.docs.isNotEmpty) {
          _vouchers = voucherSnap.docs.map((d) => VoucherItem.fromMap(d.data(), d.id)).toList();
        }
      } catch (err) {
        debugPrint('Tải vouchers Firebase: $err');
      }
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
