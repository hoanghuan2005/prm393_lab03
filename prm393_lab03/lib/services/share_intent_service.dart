import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'product_metadata_service.dart';
import 'shopee_url_parser.dart';

/// Parsed and normalized product data extracted from a shared text/URL
class SharedItemData {
  final String title;
  final String url;
  final int? priceVnd;
  final int? originalPriceVnd;
  final String? imageUrl;
  final String? shopName;
  final String? description;
  final String platform;
  final String rawText;

  const SharedItemData({
    required this.title,
    required this.url,
    required this.priceVnd,
    this.originalPriceVnd,
    this.imageUrl,
    this.shopName,
    this.description,
    this.platform = 'Shopee',
    required this.rawText,
  });

  /// Synchronously extracts URL, price, and clean product title from raw text.
  static SharedItemData? parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final text = raw.trim();

    final url = ShopeeUrlParser.extractUrl(text) ?? '';
    final priceVnd = ShopeeUrlParser.extractPrice(text);
    var title = ShopeeUrlParser.cleanTitle(text, url);

    // If title is empty but we have a Shopee URL, try extracting title from slug
    if (title.isEmpty && url.isNotEmpty) {
      final slugTitle = ShopeeUrlParser.extractSlugTitle(url);
      if (slugTitle != null && slugTitle.isNotEmpty) {
        title = slugTitle;
      }
    }

    final isShopee = ShopeeUrlParser.isShopeeUrl(url);

    return SharedItemData(
      title: title,
      url: url,
      priceVnd: priceVnd,
      platform: isShopee ? 'Shopee' : 'Khác',
      rawText: text,
    );
  }

  /// Asynchronously follows redirects and extracts Open Graph metadata (image, title, price)
  Future<SharedItemData> resolveMetadata({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (url.isEmpty) return this;
    final meta = await ProductMetadataService.fetch(
      url,
      existingTitle: title.isNotEmpty ? title : null,
      existingPrice: priceVnd,
      timeout: timeout,
    );

    return copyWith(
      url: meta.url,
      title: (meta.title != null && meta.title!.isNotEmpty)
          ? meta.title
          : title,
      priceVnd: meta.priceVnd ?? priceVnd,
      originalPriceVnd: meta.originalPriceVnd ?? originalPriceVnd,
      imageUrl: meta.imageUrl ?? imageUrl,
      shopName: meta.shopName ?? shopName,
      description: meta.description ?? description,
      platform: meta.platform,
    );
  }

  SharedItemData copyWith({
    String? title,
    String? url,
    int? priceVnd,
    int? originalPriceVnd,
    String? imageUrl,
    String? shopName,
    String? description,
    String? platform,
    String? rawText,
  }) {
    return SharedItemData(
      title: title ?? this.title,
      url: url ?? this.url,
      priceVnd: priceVnd ?? this.priceVnd,
      originalPriceVnd: originalPriceVnd ?? this.originalPriceVnd,
      imageUrl: imageUrl ?? this.imageUrl,
      shopName: shopName ?? this.shopName,
      description: description ?? this.description,
      platform: platform ?? this.platform,
      rawText: rawText ?? this.rawText,
    );
  }

  @override
  String toString() =>
      'SharedItemData(title: "$title", url: "$url", priceVnd: $priceVnd, image: "$imageUrl", platform: "$platform")';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SharedItemData &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          url == other.url &&
          priceVnd == other.priceVnd &&
          rawText == other.rawText;

  @override
  int get hashCode => Object.hash(title, url, priceVnd, rawText);
}

/// Service to handle Android Native Share Sheet targets (Feature A-04).
/// Safe on all platforms: Web, iOS, Windows, macOS, Linux (silently no-ops).
class ShareIntentService {
  static const String channelName = 'com.group07.whyibuy/share_intent';
  final MethodChannel _channel;

  final List<SharedItemData> _pendingInitialData = [];
  void Function(SharedItemData data)? _onDataReceived;
  final Set<String> _receivedKeys = {};
  bool _isDisposed = false;

  ShareIntentService([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel(channelName);

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Consumes cold-start shared data if present (called when UI is ready).
  SharedItemData? consumeInitialData() {
    if (_pendingInitialData.isEmpty) return null;
    return _pendingInitialData.removeAt(0);
  }

  Future<void> _handleSharedText(String? text) async {
    if (_isDisposed) return;
    final parsed = SharedItemData.parse(text);
    if (parsed == null) return;
    final key = parsed.rawText;
    if (!_receivedKeys.add(key)) return;
    if (_receivedKeys.length > 20) {
      _receivedKeys.remove(_receivedKeys.first);
    }

    if (_onDataReceived != null) {
      _onDataReceived!(parsed);
    } else {
      _pendingInitialData.add(parsed);
    }
  }

  Future<void> initialize({
    void Function(SharedItemData data)? onDataReceived,
  }) async {
    _onDataReceived = onDataReceived;

    if (!isSupported) return;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onShareReceived') {
        await _handleSharedText(call.arguments as String?);
      }
    });

    try {
      final initialText = await _channel.invokeMethod<String>(
        'getInitialShareText',
      );
      await _handleSharedText(initialText);
    } catch (e) {
      debugPrint('ShareIntentService getInitialShareText error: $e');
    }
  }

  void dispose() {
    _isDisposed = true;
    _onDataReceived = null;
    _channel.setMethodCallHandler(null);
  }
}
