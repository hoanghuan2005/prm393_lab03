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
}

/// A received push notification, kept for the in-app list ("Thông báo đã nhận")
class AppNotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;

  /// FCM custom data; FCM always sends string values
  final Map<String, String> data;
  final NotificationSource source;

  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    required this.data,
    required this.source,
  });

  /// `receivedAt` is stored as UTC milliseconds since epoch
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'receivedAt': receivedAt.toUtc().millisecondsSinceEpoch,
    'data': data,
    'source': source.key,
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
      );
    } catch (_) {
      // e.g. a timestamp outside DateTime's range
      return null;
    }
  }
}
