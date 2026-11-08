import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import '../services/push_service.dart';
import 'safe_notifier.dart';

class PublishResult {
  final bool published;
  final String message;

  const PublishResult({required this.published, required this.message});
}

/// A ready-made announcement: one tap fills the form, then staff edit it
class AnnouncementTemplate {
  final String label;
  final String title;
  final String body;

  const AnnouncementTemplate(this.label, this.title, this.body);
}

/// A draft handed to the form by another page (the AI assistant)
class AnnouncementDraft {
  final String title;
  final String body;

  /// "AI gợi ý" or "Câu mẫu": shown above the form until it is edited or sent
  final String source;

  const AnnouncementDraft({
    required this.title,
    required this.body,
    required this.source,
  });
}

/// Announcement form + list. An announcement is a Firestore document the app
/// listens to, so it reaches every inbox in real time without any server.
class AnnouncementsViewModel extends ChangeNotifier with SafeNotifier {
  static const int maxTitle = Announcement.maxTitle;
  static const int maxBody = Announcement.maxBody;

  static const List<AnnouncementTemplate> templates = [
    AnnouncementTemplate(
      'Mời bắt đầu',
      'Bạn đang phân vân món nào?',
      'Chia sẻ link món đồ từ Shopee hoặc Lazada vào Why I Buy để có vài ngày '
          'cân nhắc trước khi quyết định.',
    ),
    AnnouncementTemplate(
      'Lịch sale mới',
      'Lịch sale tháng này đã cập nhật',
      'Mở mục Lịch sale để xem những ngày sale sắp tới và tự hỏi món trong '
          'danh sách có cần ngay không.',
    ),
    AnnouncementTemplate(
      'Tổng kết tuần',
      'Nhìn lại một tuần mua sắm',
      'Mở Góc nhìn để xem tuần này bạn mua vì điều gì nhiều nhất.',
    ),
  ];

  final AnnouncementService _service;
  final PushService _push;
  final String byUid;
  StreamSubscription<List<Announcement>>? _subscription;

  List<Announcement>? _items;
  String? _error;
  bool _publishing = false;
  final Set<String> _busy = {};
  AnnouncementDraft? _pendingDraft;

  AnnouncementsViewModel(this._service, this._push, {required this.byUid}) {
    _subscribe();
  }

  void _subscribe() {
    _subscription?.cancel();
    _items = null;
    _error = null;
    _subscription = _service.watchAll().listen(
      (items) {
        _items = items;
        _error = null;
        notifySafely();
      },
      onError: (Object e) {
        _error = describeFirestoreError(e);
        notifySafely();
      },
    );
  }

  void retry() {
    _subscribe();
    notifySafely();
  }

  bool get publishing => _publishing;
  bool get pushAvailable => _push.isConfigured;
  bool isBusy(String id) => _busy.contains(id);

  /// Set by the AI assistant; the form takes it once with [takeDraft]
  AnnouncementDraft? get pendingDraft => _pendingDraft;

  void prefill(AnnouncementDraft draft) {
    _pendingDraft = draft;
    notifySafely();
  }

  AnnouncementDraft? takeDraft() {
    final draft = _pendingDraft;
    _pendingDraft = null;
    return draft;
  }

  UiState<List<Announcement>> get state {
    final error = _error;
    if (error != null) return UiError(message: error, onRetry: retry);
    final items = _items;
    if (items == null) return const UiLoading();
    if (items.isEmpty) {
      return const UiEmpty(
        message: 'Chưa có thông báo nào. Soạn thông báo đầu tiên ở khung "Soạn thông báo".',
      );
    }
    return UiSuccess(items);
  }

  static String? validateTitle(String? value) {
    final title = value?.trim() ?? '';
    if (title.isEmpty) return 'Nhập tiêu đề';
    if (title.length > maxTitle) return 'Tối đa $maxTitle ký tự';
    return null;
  }

  static String? validateBody(String? value) {
    final body = value?.trim() ?? '';
    if (body.isEmpty) return 'Nhập nội dung';
    if (body.length > maxBody) return 'Tối đa $maxBody ký tự';
    return null;
  }

  Future<PublishResult> publish({
    required String title,
    required String body,
    bool alsoPush = false,
  }) async {
    final invalid = validateTitle(title) ?? validateBody(body);
    if (invalid != null) {
      return PublishResult(published: false, message: invalid);
    }
    if (_publishing) {
      return const PublishResult(
        published: false,
        message: 'Đang đăng, vui lòng chờ.',
      );
    }
    _publishing = true;
    notifySafely();
    try {
      try {
        await _service.publish(byUid: byUid, title: title, body: body);
      } catch (e) {
        return PublishResult(
          published: false,
          message: describeFirestoreError(e),
        );
      }
      if (!alsoPush || !pushAvailable) {
        return const PublishResult(
          published: true,
          message: 'Đã đăng. Thông báo hiện ngay trong hộp thư của app.',
        );
      }
      try {
        final sent = await _push.broadcast(
          title: title.trim(),
          body: body.trim(),
        );
        return PublishResult(
          published: true,
          message: 'Đã đăng và gửi thông báo đẩy tới $sent thiết bị.',
        );
      } on PushException catch (e) {
        return PublishResult(
          published: true,
          message: 'Đã đăng, nhưng gửi thông báo đẩy thất bại: ${e.message}',
        );
      }
    } finally {
      _publishing = false;
      notifySafely();
    }
  }

  /// Hide an announcement from the app. Final (firestore.rules): returns an
  /// error message, or null.
  Future<String?> archive(Announcement item) async {
    if (item.status != AnnouncementStatus.published) {
      return 'Thông báo này đã được lưu trữ.';
    }
    _busy.add(item.id);
    notifySafely();
    try {
      await _service.setStatus(item.id, AnnouncementStatus.archived);
      return null;
    } catch (e) {
      return describeFirestoreError(e);
    } finally {
      _busy.remove(item.id);
      notifySafely();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
