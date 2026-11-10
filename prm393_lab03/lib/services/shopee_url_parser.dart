import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Utility to recognize, extract, and normalize Shopee URLs and shared text.
class ShopeeUrlParser {
  static final _urlRegex = RegExp(r'https?://[^\s<>"]+', caseSensitive: false);

  /// Extracts the first HTTP(S) URL found in [text], stripping trailing punctuation.
  static String? extractUrl(String text) {
    final match = _urlRegex.firstMatch(text);
    if (match == null) return null;
    final url = match.group(0)!;
    return url.replaceAll(RegExp(r'[.,;!?)\]]+$'), '');
  }

  /// Determines whether [url] belongs to Shopee domains.
  static bool isShopeeUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    return host.contains('shopee.') ||
        host == 's.shopee.vn' ||
        host == 'shope.ee' ||
        host == 'vn.shp.ee' ||
        host == 'shp.ee';
  }

  /// Checks if [url] is a shortened Shopee link.
  static bool isShortenedUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    return host == 's.shopee.vn' ||
        host == 'shope.ee' ||
        host == 'vn.shp.ee' ||
        host == 'shp.ee';
  }

  /// Resolves HTTP redirect chain to find the canonical destination URL.
  /// Also inspects bridge HTML pages (HTTP 200) often returned by short Shopee links
  /// (e.g. vn.shp.ee, s.shopee.vn) to extract the actual product destination URL.
  /// Safe against timeouts and network errors.
  static Future<String> resolveRedirect(
    String url, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (kIsWeb || !isShortenedUrl(url)) return url;
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return url;

      final client = HttpClient()..connectionTimeout = timeout;
      client.userAgent = 'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

      final request = await client.getUrl(uri);
      request.followRedirects = true;
      request.maxRedirects = 5;

      final response = await request.close().timeout(timeout);

      // Case 1: Standard 301/302 HTTP redirect
      if (response.redirects.isNotEmpty) {
        final loc = response.redirects.last.location.toString();
        client.close();
        return loc;
      }

      // Case 2: Intermediate bridge page returning HTTP 200 with CONFIG/deepLinkUrl
      if (response.statusCode == 200) {
        final bytes = <int>[];
        await for (final chunk in response) {
          bytes.addAll(chunk);
          if (bytes.length > 64 * 1024) break;
        }
        client.close();

        final html = utf8.decode(bytes, allowMalformed: true);

        // Subcase 2a: var CONFIG = { httpUrl: "https:\/\/shopee.vn\/product\/..." }
        final httpUrlMatch = RegExp(r'httpUrl\s*:\s*"([^"]+)"')
            .firstMatch(html);
        if (httpUrlMatch != null) {
          var target = httpUrlMatch.group(1)!;
          target = target.replaceAll(r'\/', '/').replaceAll(r'\u0026', '&');
          if (target.startsWith('http')) {
            return target;
          }
        }

        // Subcase 2b: deepLinkUrl navigate_url=https%3A%2F%2Fshopee.vn...
        final navMatch = RegExp(r'navigate_url=([^&"\\\s]+)').firstMatch(html);
        if (navMatch != null) {
          final decoded = Uri.decodeComponent(navMatch.group(1)!);
          if (decoded.startsWith('http')) {
            return decoded;
          }
        }

        // Subcase 2c: Canonical or direct link in bridge page
        final aHrefMatch = RegExp(
          r'<a[^>]+href=["\x27](https?://[^"\x27]*shopee\.[^"\x27]+/product/[^"\x27]+)["\x27]',
          caseSensitive: false,
        ).firstMatch(html);
        if (aHrefMatch != null) {
          return aHrefMatch.group(1)!;
        }
      } else {
        client.close();
      }
      return url;
    } catch (e) {
      debugPrint('ShopeeUrlParser resolveRedirect error: $e');
      return url;
    }
  }

  /// Extracts the readable product name from Shopee URL slug e.g.:
  /// `https://shopee.vn/Tai-nghe-Bluetooth-Baseus-Bowie-WM02-i.12345.67890` -> "Tai nghe Bluetooth Baseus Bowie WM02"
  static String? extractSlugTitle(String url) {
    final reg = RegExp(
      r'shopee\.[a-z.]+/([^/?#]+)-i\.\d+\.\d+',
      caseSensitive: false,
    );
    final match = reg.firstMatch(url);
    if (match != null) {
      final slug = match.group(1)!;
      try {
        final decoded = Uri.decodeComponent(slug.replaceAll('-', ' ')).trim();
        if (decoded.isNotEmpty && !decoded.startsWith('product')) {
          return decoded;
        }
      } catch (_) {}
    }
    return null;
  }

  /// Extracts price in VND from text (e.g. "₫299.000", "150.000đ", "150k", "giá: 150.000").
  static int? extractPrice(String text) {
    // 1. Check for shorthand like "150k" or "150K"
    final kMatch = RegExp(r'\b(\d+)\s*[kK]\b').firstMatch(text);
    if (kMatch != null) {
      final num = int.tryParse(kMatch.group(1)!);
      if (num != null && num > 0) return num * 1000;
    }

    // 2. Check for "giá: 150.000", "giá chỉ 150.000"
    final giaMatch = RegExp(
      r'giá\s*(?:chỉ|là)?\s*[:\s]?\s*(\d[\d.,]*\d)',
      caseSensitive: false,
    ).firstMatch(text);
    if (giaMatch != null) {
      final digits = giaMatch.group(1)!.replaceAll(RegExp(r'[^0-9]'), '');
      final p = int.tryParse(digits);
      if (p != null && p >= 1000) return p;
    }

    // 3. Check for standard ₫ / đ / VND currency indicators
    final match = RegExp(
      r'(?:(\d[\d.,\s]*)\s*(?:₫|đ|vnd)|(?:₫|đ|vnd)\s*(\d[\d.,\s]*))',
      caseSensitive: false,
    ).firstMatch(text);
    final value = match?.group(1) ?? match?.group(2);
    if (value == null) return null;
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final price = int.tryParse(digits);
    return price != null && price > 0 ? price : null;
  }

  /// Cleans marketing boilerplate from shared Shopee text to extract product title.
  static String cleanTitle(String raw, String? url) {
    var text = raw;
    if (url != null && url.isNotEmpty) {
      text = text.replaceFirst(url, '');
    }

    // Remove price mentions like "với giá chỉ ₫299.000", "giá ₫120.000", or standalone "₫150.000"
    text = text.replaceAll(
      RegExp(
        r'(?:với\s+)?giá\s+(?:chỉ\s+)?(?:(?:₫|đ|vnd)\s*[\d.,\s]+|[\d.,\s]+\s*(?:₫|đ|vnd))\b\.?',
        caseSensitive: false,
      ),
      '',
    );
    text = text.replaceAll(
      RegExp(
        r'(?:đang\s+)?giảm\s+(?:giá\s+)?(?:\d+\s*%|sốc|cực\s+sốc)?[!.]?',
        caseSensitive: false,
      ),
      '',
    );
    text = text.replaceAll(
      RegExp(
        r'(?:₫|đ|vnd)\s*[\d.,]+|[\d.,]+\s*(?:₫|đ|vnd)',
        caseSensitive: false,
      ),
      '',
    );

    // Remove Shopee boilerplate prefixes and suffixes
    text = text.replaceAll(
      RegExp(
        r'^(?:Cơ\s+hội\s+sở\s+hữu\s+sản\s+phẩm|Chia\s+sẻ\s+sản\s+phẩm|Cơ\s+hội\s+sở\s+hữu|Chia\s+sẻ\s+ngay|Mua\s+ngay\s+trên\s+\w+[:\-]?|Chia\s+sẻ\s+từ\s+\w+[:\-]?|Xem\s+ngay[:\-]?|Mua\s+ngay[:\-]?|Xem\s+ngay\s+trên\s+\w+[:\-]?)\s*',
        caseSensitive: false,
      ),
      '',
    );
    text = text.replaceAll(
      RegExp(
        r'(?:Mua\s+ngay|Xem\s+ngay|Đọc\s+thêm)\s*[:\-]?\s*$',
        caseSensitive: false,
      ),
      '',
    );
    text = text.replaceAll(
      RegExp(r'trên\s+Shopee\s*(?:Việt\s+Nam)?', caseSensitive: false),
      '',
    );
    // Remove seller promotional brackets like [FREESHIP XTRA], [CHÍNH HÃNG], [BH 12T]
    text = text.replaceAll(
      RegExp(
        r'\[(?:freeship|chính hãng|chinh hang|mã giảm|hot|xả kho|xa kho|bh|sale|voucher|sốc|cực sốc)[^\]]*\]',
        caseSensitive: false,
      ),
      '',
    );
    text = text.replaceAll(RegExp(r'【[^】]*】'), '');

    // Remove promotional suffixes like "BH 12 tháng", "Chính hãng 100%", "Giá rẻ"
    text = text.replaceAll(
      RegExp(
        r'\b(?:bh|bảo hành)\s*\d+\s*(?:tháng|năm|t)\b',
        caseSensitive: false,
      ),
      '',
    );
    text = text.replaceAll(
      RegExp(
        r'\b(?:chính hãng\s*100%|chính hãng|giá rẻ|cao cấp|freeship\s*xtra|freeship)\b',
        caseSensitive: false,
      ),
      '',
    );

    text = text.replaceAll(
      RegExp(r'^[M|m]ua\s+(?:ngay\s+)?(?:sản\s+phẩm\s+)?'),
      '',
    );
    text = cleanLeadingArtifacts(text);
    text = text.replaceAll(RegExp(r'[\-|:•\s.!]+$'), '');
    text = text.replaceAll(RegExp(r'^[\-|:•\s.!]+'), '');
    text = text.replaceAll(RegExp(r'\s{2,}'), ' ').trim();

    return truncateToWordBoundary(text, maxLength: 60);
  }

  /// Removes stray leading digits/artifacts like "0Ô Dù" -> "Ô Dù", "01. "
  static String cleanLeadingArtifacts(String raw) {
    var t = raw.trim();
    t = t.replaceFirst(RegExp(r'^[0-9]+(?=[A-Za-zÀ-ỹ])'), '');
    t = t.replaceFirst(RegExp(r'^[0-9]+[\s.:\-–—|•]+(?=[A-Za-zÀ-ỹ])'), '');
    t = t.replaceFirst(
      RegExp(r'^(?:Top\s*(?:No\.?\s*)?\d+[\s:\-–—|•]+)', caseSensitive: false),
      '',
    );
    return t.trim();
  }

  /// Truncates [text] at the last whole-word boundary before [maxLength].
  static String truncateToWordBoundary(String text, {int maxLength = 60}) {
    final trimmed = text.trim();
    if (trimmed.length <= maxLength) return trimmed;
    final sub = trimmed.substring(0, maxLength);
    final lastSpace = sub.lastIndexOf(' ');
    if (lastSpace > 15) {
      return sub
          .substring(0, lastSpace)
          .replaceAll(RegExp(r'[,\-|:•\s.!]+$'), '')
          .trim();
    }
    return sub.trim();
  }
}
