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

/// Announcement form + list. An announcement is a Firestore document the app
/// listens to, so it reaches every inbox in real time without any server.
class AnnouncementsViewModel extends ChangeNotifier with SafeNotifier {
  static const int maxTitle = Announcement.maxTitle;
  static const int maxBody = Announcement.maxBody;

  final AnnouncementService _service;
  final PushService _push;
  final String adminUid;
  StreamSubscription<List<Announcement>>? _subscription;

  List<Announcement>? _items;
  String? _error;
  bool _publishing = false;
  final Set<String> _busy = {};

  AnnouncementsViewModel(this._service, this._push, {required this.adminUid}) {
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
        await _service.publish(adminUid: adminUid, title: title, body: body);
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

  /// Archive (hide from the app) or restore. Returns an error message, or null.
  Future<String?> setStatus(
    Announcement item,
    AnnouncementStatus status,
  ) async {
    _busy.add(item.id);
    notifySafely();
    try {
      await _service.setStatus(item.id, status);
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
