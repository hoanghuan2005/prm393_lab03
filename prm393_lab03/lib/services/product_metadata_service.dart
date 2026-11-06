import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'shopee_url_parser.dart';

/// Normalized product information extracted from a shared link or metadata.
class ProductMetadata {
  final String url;
  final String? title;
  final int? priceVnd;
  final int? originalPriceVnd;
  final String? imageUrl;
  final String? shopName;
  final String? description;
  final String platform;

  const ProductMetadata({
    required this.url,
    this.title,
    this.priceVnd,
    this.originalPriceVnd,
    this.imageUrl,
    this.shopName,
    this.description,
    this.platform = 'Shopee',
  });

  ProductMetadata copyWith({
    String? url,
    String? title,
    int? priceVnd,
    int? originalPriceVnd,
    String? imageUrl,
    String? shopName,
    String? description,
    String? platform,
  }) {
    return ProductMetadata(
      url: url ?? this.url,
      title: title ?? this.title,
      priceVnd: priceVnd ?? this.priceVnd,
      originalPriceVnd: originalPriceVnd ?? this.originalPriceVnd,
      imageUrl: imageUrl ?? this.imageUrl,
      shopName: shopName ?? this.shopName,
      description: description ?? this.description,
      platform: platform ?? this.platform,
    );
  }
}

/// Service to fetch Open Graph and HTML metadata for products safely.
class ProductMetadataService {
  static const Duration defaultTimeout = Duration(seconds: 5);

  /// Fetches metadata from [rawUrl]. If network or parsing fails, returns fallback data
  /// without throwing exceptions or generating fake prices.
  static Future<ProductMetadata> fetch(
    String rawUrl, {
    String? existingTitle,
    int? existingPrice,
    Duration timeout = defaultTimeout,
  }) async {
    final cleanUrl = rawUrl.trim();
    if (cleanUrl.isEmpty) {
      return ProductMetadata(
        url: cleanUrl,
        title: existingTitle,
        priceVnd: existingPrice,
      );
    }

    String finalUrl = cleanUrl;
    if (ShopeeUrlParser.isShortenedUrl(cleanUrl)) {
      finalUrl = await ShopeeUrlParser.resolveRedirect(
        cleanUrl,
        timeout: timeout,
      );
    }

    // Try extracting title from URL slug first (instant, doesn't need network)
    final slugTitle = ShopeeUrlParser.extractSlugTitle(finalUrl);

    // Initial baseline with what we already know
    var metadata = ProductMetadata(
      url: finalUrl,
      title: existingTitle?.isNotEmpty == true ? existingTitle : slugTitle,
      priceVnd: existingPrice,
      platform: ShopeeUrlParser.isShopeeUrl(finalUrl) ? 'Shopee' : 'Khác',
    );

    if (kIsWeb) {
      // In web browser, direct CORS requests to external shopping sites are blocked.
      return metadata;
    }

    try {
      final uri = Uri.tryParse(finalUrl);
      if (uri == null) return metadata;

      final client = HttpClient()..connectionTimeout = timeout;
      client.userAgent = 'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

      final request = await client.getUrl(uri);
      request.followRedirects = true;
      request.maxRedirects = 5;

      final response = await request.close().timeout(timeout);
      if (response.statusCode == 200) {
        // Read up to 1MB to make sure Open Graph tags and initial state in large PDP HTMLs are captured
        final bodyBytes = <int>[];
        await for (final chunk in response) {
          bodyBytes.addAll(chunk);
          if (bodyBytes.length > 1024 * 1024) break;
        }

        final html = utf8.decode(bodyBytes, allowMalformed: true);
        metadata = _parseHtmlMetadata(html, metadata, finalUrl);
      }
      client.close();
    } catch (e) {
      debugPrint('ProductMetadataService fetch error: $e');
    }

    return metadata;
  }

  static bool _isShopeeBrandLogo(String url) {
    final lower = url.toLowerCase();
    return lower.contains('deo.shopeemobile.com') ||
        lower.contains('26c9324913c021677768c36975d635ef') ||
        lower.contains('homepagefe') ||
        lower.contains('brand-logo') ||
        lower.contains('shopee-logo');
  }

  static ProductMetadata _parseHtmlMetadata(
    String html,
    ProductMetadata baseline,
    String finalUrl,
  ) {
    String? title = baseline.title;
    String? imageUrl = baseline.imageUrl;
    String? description = baseline.description;
    String? shopName = baseline.shopName;
    int? price = baseline.priceVnd;

    // Helper to test if a title is a generic website title rather than a product name
    bool isGenericSiteTitle(String t) {
      final low = t.toLowerCase();
      return low.contains('mua và bán trên') ||
          low.contains('mua va ban tren') ||
          low == 'shopee việt nam' ||
          low == 'shopee viet nam';
    }

    // 1. Open Graph Title (supports attributes like data-rh="true" before property)
    final ogTitleMatch = RegExp(
      r'<meta[^>]+(?:property|name)=["\x27]og:title["\x27][^>]+content=["\x27]([^"\x27]+)["\x27]|<meta[^>]+content=["\x27]([^"\x27]+)["\x27][^>]+(?:property|name)=["\x27]og:title["\x27]',
      caseSensitive: false,
    ).firstMatch(html);
    final ogTitle = ogTitleMatch?.group(1) ?? ogTitleMatch?.group(2);

    if (ogTitle != null && ogTitle.trim().isNotEmpty) {
      // Clean Shopee suffix: e.g. "Tai nghe Bowie WM02 | Shopee Việt Nam" -> "Tai nghe Bowie WM02"
      final clean = ogTitle
          .replaceAll(RegExp(r'\s*\|\s*Shopee.*$', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s*-\s*Shopee.*$', caseSensitive: false), '')
          .trim();
      if (clean.isNotEmpty && !isGenericSiteTitle(clean)) {
        title = clean;
      }
    }

    if (title == null || title.isEmpty || isGenericSiteTitle(title)) {
      // Fallback A: <title> tag
      final titleTagMatch = RegExp(
        r'<title>([^<]+)</title>',
        caseSensitive: false,
      ).firstMatch(html);
      final rawTag = titleTagMatch?.group(1)?.trim();
      if (rawTag != null && rawTag.isNotEmpty) {
        final clean = rawTag
            .replaceAll(RegExp(r'\s*\|\s*Shopee.*$', caseSensitive: false), '')
            .replaceAll(RegExp(r'\s*-\s*Shopee.*$', caseSensitive: false), '')
            .trim();
        if (clean.isNotEmpty && !isGenericSiteTitle(clean)) {
          title = clean;
        }
      }
    }

    if (title == null || title.isEmpty || isGenericSiteTitle(title)) {
      // Fallback B: JSON initialState item title
      final jsonTitleMatch = RegExp(r'"title"\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"')
          .firstMatch(html);
      if (jsonTitleMatch != null) {
        final raw = jsonTitleMatch.group(1)!;
        if (raw.isNotEmpty && raw.length > 5 && !isGenericSiteTitle(raw)) {
          title = raw.replaceAll(r'\"', '"');
        }
      }
    }

    if (title != null && title.isNotEmpty) {
      title = ShopeeUrlParser.cleanTitle(title, null);
    }

    // 2. Open Graph Image (supports attributes like data-rh="true" before property)
    final ogImgMatch = RegExp(
      r'<meta[^>]+(?:property|name)=["\x27]og:image["\x27][^>]+content=["\x27]([^"\x27]+)["\x27]|<meta[^>]+content=["\x27]([^"\x27]+)["\x27][^>]+(?:property|name)=["\x27]og:image["\x27]',
      caseSensitive: false,
    ).firstMatch(html);
    final ogImg = ogImgMatch?.group(1) ?? ogImgMatch?.group(2);

    if (ogImg != null &&
        ogImg.trim().isNotEmpty &&
        !_isShopeeBrandLogo(ogImg)) {
      imageUrl = ogImg.trim();
    }

    // Fallback: search for Shopee image hash in HTML/JSON (e.g. "image":"vn-11134207-81ztc-mloysk0pcoi089")
    if (imageUrl == null || _isShopeeBrandLogo(imageUrl)) {
      final imgHashMatch = RegExp(r'"image"\s*:\s*"([a-zA-Z0-9_\-]+)"')
          .firstMatch(html);
      if (imgHashMatch != null) {
        final hash = imgHashMatch.group(1)!;
        if (hash.isNotEmpty && hash != 'null' && hash.length > 10) {
          imageUrl = 'https://down-vn.img.susercontent.com/file/$hash';
        }
      }
    }

    // 3. Open Graph Description
    final ogDescMatch = RegExp(
      r'<meta[^>]+(?:property|name)=["\x27]og:description["\x27][^>]+content=["\x27]([^"\x27]+)["\x27]|<meta[^>]+content=["\x27]([^"\x27]+)["\x27][^>]+(?:property|name)=["\x27]og:description["\x27]',
      caseSensitive: false,
    ).firstMatch(html);
    final ogDesc = ogDescMatch?.group(1) ?? ogDescMatch?.group(2);
    if (ogDesc != null && ogDesc.trim().isNotEmpty) {
      final d = ogDesc.trim();
      if (!isGenericSiteTitle(d)) {
        description = d;
      }
      // Try extracting shop name from description if format is: "Mua sắm [Sản phẩm] tại [Shop] trên Shopee..."
      final shopMatch = RegExp(
        r'tại\s+([^,.]+?)\s+trên\s+Shopee',
        caseSensitive: false,
      ).firstMatch(d);
      if (shopMatch != null) {
        shopName = shopMatch.group(1)?.trim();
      }
    }

    // 4. Open Graph / Product Price
    if (price == null) {
      final ogPriceMatch = RegExp(
        r'<meta[^>]+(?:property|name)=["\x27](?:product|og):price:amount["\x27][^>]+content=["\x27]([^"\x27]+)["\x27]|<meta[^>]+content=["\x27]([^"\x27]+)["\x27][^>]+(?:property|name)=["\x27](?:product|og):price:amount["\x27]',
        caseSensitive: false,
      ).firstMatch(html);
      final rawPrice = ogPriceMatch?.group(1) ?? ogPriceMatch?.group(2);
      if (rawPrice != null) {
        final parsed =
            double.tryParse(rawPrice)?.toInt() ??
            int.tryParse(rawPrice.replaceAll(RegExp(r'[^0-9]'), ''));
        if (parsed != null && parsed > 0) {
          price = parsed;
        }
      }
    }

    return baseline.copyWith(
      title: title,
      imageUrl: imageUrl,
      description: description,
      shopName: shopName,
      priceVnd: price,
    );
  }
}
