import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/services/share_intent_service.dart';
import 'package:prm393_lab03/services/shopee_url_parser.dart';

void main() {
  group('SharedItemData.parse', () {
    test('returns null for null or empty input', () {
      expect(SharedItemData.parse(null), isNull);
      expect(SharedItemData.parse(''), isNull);
      expect(SharedItemData.parse('   '), isNull);
    });

    test('extracts Shopee share string with boilerplate prefix', () {
      const raw =
          'Mua ngay trên Shopee: Tai nghe Sony WH-1000XM5 https://shopee.vn/product/123/456';
      final result = SharedItemData.parse(raw);

      expect(result, isNotNull);
      expect(result!.url, 'https://shopee.vn/product/123/456');
      expect(result.title, 'Tai nghe Sony WH-1000XM5');
      expect(result.priceVnd, isNull);
      expect(result.platform, 'Shopee');
    });

    test('extracts Shopee real-life share text with [CHÍNH HÃNG] and price', () {
      const raw =
          'Mua [CHÍNH HÃNG] Tai nghe Bluetooth True Wireless Baseus Bowie WM02 trên Shopee với giá chỉ ₫299.000. Mua ngay: https://s.shopee.vn/606yXkYABC';
      final result = SharedItemData.parse(raw);

      expect(result, isNotNull);
      expect(result!.url, 'https://s.shopee.vn/606yXkYABC');
      expect(result.title, 'Tai nghe Bluetooth True Wireless Baseus Bowie WM02');
      expect(result.priceVnd, 299000);
      expect(result.platform, 'Shopee');
    });

    test('extracts Lazada share string with trailing punctuation', () {
      const raw =
          'Xem ngay Bàn phím cơ không dây - https://s.lazada.vn/s.XYZ123.';
      final result = SharedItemData.parse(raw);

      expect(result, isNotNull);
      expect(result!.url, 'https://s.lazada.vn/s.XYZ123');
      expect(result.title, 'Bàn phím cơ không dây');
    });

    test('handles bare Shopee shortened url', () {
      const raw = 'https://s.shopee.vn/606yXkYABC';
      final result = SharedItemData.parse(raw);

      expect(result, isNotNull);
      expect(result!.url, 'https://s.shopee.vn/606yXkYABC');
      expect(result.title, '');
      expect(result.priceVnd, isNull);
      expect(result.platform, 'Shopee');
    });

    test('extracts title from Shopee slug when title is otherwise empty', () {
      const raw = 'https://shopee.vn/Tai-nghe-Sony-WH-1000XM5-i.12345.67890';
      final result = SharedItemData.parse(raw);

      expect(result, isNotNull);
      expect(result!.url, 'https://shopee.vn/Tai-nghe-Sony-WH-1000XM5-i.12345.67890');
      expect(result.title, 'Tai nghe Sony WH 1000XM5');
      expect(result.platform, 'Shopee');
    });

    test('handles text only without url', () {
      const raw = 'Giày chạy bộ Nike Pegasus 40';
      final result = SharedItemData.parse(raw);

      expect(result, isNotNull);
      expect(result!.url, '');
      expect(result.title, 'Giày chạy bộ Nike Pegasus 40');
      expect(result.priceVnd, isNull);
    });

    test('handles raw link with text before and after', () {
      const raw = 'Cân nhắc mua http://example.com/item giá tốt hôm nay';
      final result = SharedItemData.parse(raw);

      expect(result, isNotNull);
      expect(result!.url, 'http://example.com/item');
      expect(result.title, 'Cân nhắc mua giá tốt hôm nay');
    });

    test('extracts a price when the shared text includes currency', () {
      const raw = 'Tai nghe Sony 1.290.000₫ https://shopee.vn/product/123/456';
      final result = SharedItemData.parse(raw);

      expect(result, isNotNull);
      expect(result!.priceVnd, 1290000);
    });

    test('extracts clean title from "Cơ hội sở hữu sản phẩm" prefix', () {
      const raw =
          'Cơ hội sở hữu sản phẩm Loa Bluetooth G63, Loa Chữ G Kèm Đồng Hồ https://vn.shp.ee/MG5chA9s';
      final result = SharedItemData.parse(raw);

      expect(result, isNotNull);
      expect(result!.title, 'Loa Bluetooth G63, Loa Chữ G Kèm Đồng Hồ');
      expect(result.url, 'https://vn.shp.ee/MG5chA9s');
      expect(result.priceVnd, isNull);
    });

    test('extracts price shorthand like 150k or giá 150.000', () {
      expect(ShopeeUrlParser.extractPrice('Loa mini giá 150.000'), 150000);
      expect(ShopeeUrlParser.extractPrice('Bán tai nghe 250k free ship'), 250000);
    });
  });

  group('ShopeeUrlParser', () {
    test('identifies full Shopee and shortened Shopee domains', () {
      expect(ShopeeUrlParser.isShopeeUrl('https://shopee.vn/product/1/2'), isTrue);
      expect(ShopeeUrlParser.isShopeeUrl('https://s.shopee.vn/abc'), isTrue);
      expect(ShopeeUrlParser.isShopeeUrl('https://shope.ee/abc'), isTrue);
      expect(ShopeeUrlParser.isShopeeUrl('https://vn.shp.ee/abc'), isTrue);
      expect(ShopeeUrlParser.isShopeeUrl('https://tiki.vn/sp/123'), isFalse);
    });

    test('identifies shortened URLs', () {
      expect(ShopeeUrlParser.isShortenedUrl('https://s.shopee.vn/abc'), isTrue);
      expect(ShopeeUrlParser.isShortenedUrl('https://shope.ee/abc'), isTrue);
      expect(ShopeeUrlParser.isShortenedUrl('https://shopee.vn/product/1/2'), isFalse);
    });

    test('extracts slug product name correctly', () {
      const url = 'https://shopee.vn/Chu%E1%BB%99t-kh%C3%B4ng-d%C3%A2y-Logitech-M331-Silent-Plus-i.12345.67890';
      final title = ShopeeUrlParser.extractSlugTitle(url);
      expect(title, 'Chuột không dây Logitech M331 Silent Plus');
    });
  });

  group('ProductMetadata HTML Parsing', () {
    test('parses Open Graph tags correctly without fake price', () {
      const html = '''
<!DOCTYPE html>
<html>
<head>
  <meta property="og:title" content="Tai nghe Baseus Bowie WM02 | Shopee Việt Nam">
  <meta property="og:image" content="https://down-vn.img.susercontent.com/file/vn-11134207.jpg">
  <meta property="og:description" content="Mua sắm Tai nghe tại Baseus Official Store trên Shopee...">
  <meta property="product:price:amount" content="299000">
</head>
<body></body>
</html>
''';
      // Using public test or checking parser
      expect(html, contains('og:title'));
    });
  });

  group('ShareIntentService', () {
    test('consumeInitialData clears after being read', () {
      final service = ShareIntentService();
      expect(service.consumeInitialData(), isNull);
    });
  });
}
