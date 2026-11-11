import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart'
    show
        Announcement,
        AnnouncementService,
        InboxKind,
        InboxMessage,
        InboxService,
        describeFirestoreError;

import '../models/ui_state.dart';
import '../services/preferences_service.dart';
import 'deferred_notify.dart';

/// One row of Hộp thư: an announcement for everyone, or a message to this user
class InboxEntry {
  final String id;
  final String title;
  final String body;
  final DateTime? createdAt;

  /// From `announcements` (null [kind]) or from `users/{uid}/inbox`
  final bool isAnnouncement;
  final InboxKind? kind;

  /// The suggestion or feedback a personal message answers
  final String? refId;
  final bool isRead;

  const InboxEntry({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isAnnouncement,
    required this.isRead,
    this.kind,
    this.refId,
  });

  factory InboxEntry.announcement(Announcement a, {required bool isRead}) =>
      InboxEntry(
        id: a.id,
        title: a.title,
        body: a.body,
        createdAt: a.createdAt,
        isAnnouncement: true,
        isRead: isRead,
      );

  factory InboxEntry.message(InboxMessage m) => InboxEntry(
    id: m.id,
    title: m.title,
    body: m.body,
    createdAt: m.createdAt,
    isAnnouncement: false,
    kind: m.kind,
    refId: m.refId,
    isRead: m.isRead,
  );

  /// The answer to a "Báo đợt sale" report: opens that screen
  bool get isSuggestionReply => kind == InboxKind.suggestionReply;
}

/// Hộp thư (cross-role flow): announcements published on the web admin plus the
/// personal messages staff send (suggestion results, replies to feedback).
/// Both lists are live; services come from `packages/core`.
class InboxViewModel extends ChangeNotifier with DeferredNotify {
  final AnnouncementService announcementService;
  final InboxService inboxService;
  final PreferencesService preferencesService;

  StreamSubscription<List<Announcement>>? _announcementSub;
  StreamSubscription<List<InboxMessage>>? _messageSub;
  String? _uid;
  List<Announcement>? _announcements;
  List<InboxMessage>? _messages;
  Set<String> _readAnnouncements = {};
  Object? _error;

  InboxViewModel({
    required this.announcementService,
    required this.inboxService,
    required this.preferencesService,
  });

  void updateUid(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _subscribe();
  }

  Future<void> _subscribe() async {
    await _announcementSub?.cancel();
    await _messageSub?.cancel();
    _announcementSub = null;
    _messageSub = null;
    _announcements = null;
    _messages = null;
    _error = null;
    final uid = _uid;
    notifyLater();
    if (uid == null) return;
    _readAnnouncements = await preferencesService.getReadAnnouncements();
    if (isDisposed || uid != _uid) return;
    void onError(Object e) {
      _error = e;
      notifyListeners();
    }

    _announcementSub = announcementService.watchPublished().listen((list) {
      _announcements = list;
      notifyListeners();
    }, onError: onError);
    _messageSub = inboxService.watch(uid).listen((list) {
      _messages = list;
      notifyListeners();
    }, onError: onError);
  }

  /// Newest first; announcements and messages mixed by date
  List<InboxEntry> get entries {
    final list = [
      for (final a in _announcements ?? const <Announcement>[])
        InboxEntry.announcement(a, isRead: _readAnnouncements.contains(a.id)),
      for (final m in _messages ?? const <InboxMessage>[])
        InboxEntry.message(m),
    ];
    // A message just written has no server time yet: it is the newest
    final far = DateTime(9999);
    list.sort((a, b) => (b.createdAt ?? far).compareTo(a.createdAt ?? far));
    return list;
  }

  int get unreadCount => entries.where((e) => !e.isRead).length;

  UiState<List<InboxEntry>> get state {
    final error = _error;
    if (error != null) {
      return UiError(message: describeFirestoreError(error), onRetry: retry);
    }
    if (_uid == null) return const UiInitial();
    if (_announcements == null || _messages == null) return const UiLoading();
    final list = entries;
    if (list.isEmpty) {
      return const UiEmpty(
        message:
            'Chưa có tin nào. Thông báo của nhóm và câu trả lời cho đợt sale '
            'bạn báo sẽ hiện ở đây.',
      );
    }
    return UiSuccess(list);
  }

  void retry() => _subscribe();

  /// Opening a row marks it read: a message in Firestore (`readAt`, the only
  /// field the owner may change), an announcement on this device
  Future<void> markRead(InboxEntry entry) async {
    final uid = _uid;
    if (entry.isRead || uid == null) return;
    if (entry.isAnnouncement) {
      _readAnnouncements = {..._readAnnouncements, entry.id};
      notifyListeners();
      await preferencesService.addReadAnnouncement(entry.id);
      return;
    }
    try {
      await inboxService.markRead(uid, entry.id);
    } catch (e) {
      // Stays unread and can be opened again; nothing else depends on it
      debugPrint('Inbox markRead failed: $e');
    }
  }

  @override
  void dispose() {
    _announcementSub?.cancel();
    _messageSub?.cancel();
    super.dispose();
  }
}
