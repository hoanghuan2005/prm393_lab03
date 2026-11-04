import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Parsed data extracted from a shared text/URL
class SharedItemData {
  final String title;
  final String url;
  final String rawText;

  const SharedItemData({
    required this.title,
    required this.url,
    required this.rawText,
  });

  /// Extracts the URL and cleans up the remaining text as product title.
  static SharedItemData? parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final text = raw.trim();

    // Match web URL (http:// or https://)
    final urlRegex = RegExp(r'https?://[^\s]+', caseSensitive: false);
    final match = urlRegex.firstMatch(text);

    String url = '';
    String title = '';

    if (match != null) {
      url = match.group(0)!;
      // Strip trailing punctuation often attached to links
      url = url.replaceAll(RegExp(r'[.,;!]+$'), '');

      // Remainder is title
      var remaining = text.replaceFirst(match.group(0)!, '').trim();

      // Clean up common boilerplate prefixes/suffixes from Shopee, Lazada, etc.
      remaining = remaining
          .replaceAll(
            RegExp(
              r'^(Mua\s+ngay\s+trên\s+\w+[:\-]?|Chia\s+sẻ\s+từ\s+\w+[:\-]?|Xem\s+ngay[:\-]?)\s*',
              caseSensitive: false,
            ),
            '',
          )
          .replaceAll(RegExp(r'[\-|:•\s]+$'), '')
          .replaceAll(RegExp(r'^[\-|:•\s]+'), '')
          .trim();

      title = remaining;
    } else {
      // No URL found, treat whole text as title
      title = text;
    }

    return SharedItemData(
      title: title,
      url: url,
      rawText: text,
    );
  }

  @override
  String toString() => 'SharedItemData(title: "$title", url: "$url")';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SharedItemData &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          url == other.url &&
          rawText == other.rawText;

  @override
  int get hashCode => Object.hash(title, url, rawText);
}

/// Service to handle Android Native Share Sheet targets (Feature A-04).
/// Safe on all platforms: Web, iOS, Windows, macOS, Linux (silently no-ops).
class ShareIntentService {
  static const String channelName = 'com.group07.whyibuy/share_intent';
  final MethodChannel _channel;

  SharedItemData? _pendingInitialData;
  void Function(SharedItemData data)? _onDataReceived;

  ShareIntentService([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel(channelName);

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Consumes cold-start shared data if present (called when UI is ready).
  SharedItemData? consumeInitialData() {
    final data = _pendingInitialData;
    _pendingInitialData = null;
    return data;
  }

  Future<void> initialize({
    void Function(SharedItemData data)? onDataReceived,
  }) async {
    _onDataReceived = onDataReceived;

    if (!isSupported) return;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onShareReceived') {
        final text = call.arguments as String?;
        final parsed = SharedItemData.parse(text);
        if (parsed != null) {
          if (_onDataReceived != null) {
            _onDataReceived!(parsed);
          } else {
            _pendingInitialData = parsed;
          }
        }
      }
    });

    try {
      final initialText = await _channel.invokeMethod<String>(
        'getInitialShareText',
      );
      if (initialText != null && initialText.isNotEmpty) {
        final parsed = SharedItemData.parse(initialText);
        if (parsed != null) {
          _pendingInitialData = parsed;
        }
      }
    } catch (e) {
      debugPrint('ShareIntentService getInitialShareText error: $e');
    }
  }
}
