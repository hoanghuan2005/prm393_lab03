import 'dart:convert';

/// A Shopee product link split into its ids (spec 6.4). Only shopee.vn and its
/// subdomains are accepted; short links (s.shopee.vn, shp.ee) must be opened first.
class ShopeeLink {
  final String shopId;
  final String itemId;

  /// Variant from `extraParams.display_model_id`; null when the link has none
  final String? modelId;

  const ShopeeLink({required this.shopId, required this.itemId, this.modelId});

  /// Same format as the Chrome extension writes on wishlist items
  String get productKey => 'shopee:$shopId:$itemId';

  String get canonicalUrl => 'https://shopee.vn/product/$shopId/$itemId';

  static final _slugIds = RegExp(r'-i\.(\d+)\.(\d+)$');
  static final _pathIds = RegExp(r'^/(?:product|opaanlp)/(\d+)/(\d+)/?$');
  static final _digits = RegExp(r'^\d+$');
  static final _productKey = RegExp(r'^shopee:(\d+):(\d+)$');

  static const _shortHosts = {'s.shopee.vn', 'shp.ee', 'vn.shp.ee'};

  static Uri? _uri(String? text) {
    final raw = text?.trim() ?? '';
    if (raw.isEmpty) return null;
    final uri = Uri.tryParse(raw.contains('://') ? raw : 'https://$raw');
    if (uri == null || uri.host.isEmpty) return null;
    return uri;
  }

  /// A short link that has to be opened in the browser before it can be split
  static bool isShortLink(String? text) =>
      _shortHosts.contains(_uri(text)?.host.toLowerCase());

  /// Ids of a Shopee product link; null for short links, other sites and plain text
  static ShopeeLink? tryParse(String? text) {
    final uri = _uri(text);
    if (uri == null) return null;
    final host = uri.host.toLowerCase();
    if (_shortHosts.contains(host)) return null;
    if (host != 'shopee.vn' && !host.endsWith('.shopee.vn')) return null;

    final path = uri.path;
    final query = uri.queryParameters;
    String? shopId, itemId;
    if (_slugIds.firstMatch(path) case final m?) {
      (shopId, itemId) = (m.group(1), m.group(2));
    } else if (_pathIds.firstMatch(path) case final m?) {
      (shopId, itemId) = (m.group(1), m.group(2));
    } else if (_digits.hasMatch(query['shopid'] ?? '') &&
        _digits.hasMatch(query['itemid'] ?? '')) {
      (shopId, itemId) = (query['shopid'], query['itemid']);
    }
    if (shopId == null || itemId == null) return null;
    return ShopeeLink(
      shopId: shopId,
      itemId: itemId,
      modelId: _modelId(query['extraParams']),
    );
  }

  /// Invalid JSON only loses the variant, never the product (spec 6.4 case 7)
  static String? _modelId(String? extraParams) {
    if (extraParams == null || extraParams.isEmpty) return null;
    try {
      final decoded = jsonDecode(extraParams);
      final id = decoded is Map ? decoded['display_model_id'] : null;
      final text = id?.toString() ?? '';
      return _digits.hasMatch(text) ? text : null;
    } on FormatException {
      return null;
    }
  }

  /// Reads a `shopee:<shopId>:<itemId>` key written by the extension
  static ShopeeLink? fromProductKey(String? key, {String? modelId}) {
    final m = _productKey.firstMatch(key ?? '');
    if (m == null) return null;
    return ShopeeLink(
      shopId: m.group(1)!,
      itemId: m.group(2)!,
      modelId: modelId,
    );
  }
}
