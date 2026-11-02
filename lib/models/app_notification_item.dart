/// How a push notification reached the app. [key] is stored, so never change it.
enum NotificationSource {
  /// Received while the app was open
  foreground('foreground'),

  /// Recorded by the background handler
  background('background'),

  /// Tapped while the app was in the background
  tapBackground('tap_background'),

  /// Tapped while the app was closed
  tapTerminated('tap_terminated');

  const NotificationSource(this.key);

  final String key;

  /// Unknown or missing key → [background]
  static NotificationSource fromKey(Object? key) {
    for (final source in values) {
      if (source.key == key) return source;
    }
    return background;
  }

  /// True for the two "tapped" sources, the only values allowed in `openedVia`
  bool get isTap => this == tapBackground || this == tapTerminated;
}

/// A received push notification, kept for the in-app list ("Thông báo đã nhận")
class AppNotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;

  /// FCM custom data; FCM always sends string values
  final Map<String, String> data;

  /// How the message arrived; a tap source only when it was not stored before the tap
  final NotificationSource source;

  /// Set when the user tapped a message that was already stored (tapBackground or
  /// tapTerminated only)
  final NotificationSource? openedVia;
  final DateTime? openedAt;

  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    required this.data,
    required this.source,
    this.openedVia,
    this.openedAt,
  });

  /// Copy marked as opened by [via] at [at]; other fields unchanged
  AppNotificationItem markOpened(NotificationSource via, DateTime at) =>
      AppNotificationItem(
        id: id,
        title: title,
        body: body,
        receivedAt: receivedAt,
        data: data,
        source: source,
        openedVia: via,
        openedAt: at,
      );

  /// `receivedAt` is stored as UTC milliseconds since epoch
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'receivedAt': receivedAt.toUtc().millisecondsSinceEpoch,
    'data': data,
    'source': source.key,
    if (openedVia != null) 'openedVia': openedVia!.key,
    if (openedAt != null) 'openedAt': openedAt!.toUtc().millisecondsSinceEpoch,
  };

  /// Null when `id` is missing or `receivedAt` is not a valid timestamp. Never throws.
  static AppNotificationItem? tryFromJson(Map<String, dynamic> json) {
    try {
      final id = json['id'];
      final receivedAt = json['receivedAt'];
      if (id is! String || id.isEmpty || receivedAt is! int) return null;
      final rawData = json['data'];
      final title = json['title'];
      final body = json['body'];
      // Older entries have neither field; anything invalid is treated as not opened
      final openedVia = NotificationSource.values
          .where((s) => s.isTap && s.key == json['openedVia'])
          .firstOrNull;
      final openedAtRaw = json['openedAt'];
      final openedAt = openedVia != null && openedAtRaw is int
          ? DateTime.fromMillisecondsSinceEpoch(openedAtRaw)
          : null;
      return AppNotificationItem(
        id: id,
        title: title is String ? title : '',
        body: body is String ? body : '',
        // Local time for display, as when the item was first received
        receivedAt: DateTime.fromMillisecondsSinceEpoch(receivedAt),
        data: rawData is Map
            ? {
                for (final entry in rawData.entries)
                  if (entry.key != null && entry.value != null)
                    '${entry.key}': '${entry.value}',
              }
            : const {},
        source: NotificationSource.fromKey(json['source']),
        openedVia: openedAt != null ? openedVia : null,
        openedAt: openedAt,
      );
    } catch (_) {
      // e.g. a timestamp outside DateTime's range
      return null;
    }
  }
}
