import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/services/share_intent_service.dart';

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
    });

    test('extracts Lazada share string with trailing punctuation', () {
      const raw =
          'Xem ngay Bàn phím cơ không dây - https://s.lazada.vn/s.XYZ123.';
      final result = SharedItemData.parse(raw);

      expect(result, isNotNull);
      expect(result!.url, 'https://s.lazada.vn/s.XYZ123');
      expect(result.title, 'Bàn phím cơ không dây');
    });

    test('handles url only', () {
      const raw = 'https://tiki.vn/sach-dac-nhan-tam-p12345.html';
      final result = SharedItemData.parse(raw);

      expect(result, isNotNull);
      expect(result!.url, 'https://tiki.vn/sach-dac-nhan-tam-p12345.html');
      expect(result.title, '');
    });

    test('handles text only without url', () {
      const raw = 'Giày chạy bộ Nike Pegasus 40';
      final result = SharedItemData.parse(raw);

      expect(result, isNotNull);
      expect(result!.url, '');
      expect(result.title, 'Giày chạy bộ Nike Pegasus 40');
    });

    test('handles raw link with text before and after', () {
      const raw = 'Cân nhắc mua http://example.com/item giá tốt hôm nay';
      final result = SharedItemData.parse(raw);

      expect(result, isNotNull);
      expect(result!.url, 'http://example.com/item');
      expect(result.title, 'Cân nhắc mua  giá tốt hôm nay');
    });
  });

  group('ShareIntentService', () {
    test('consumeInitialData clears after being read', () {
      final service = ShareIntentService();
      expect(service.consumeInitialData(), isNull);
    });
  });
}

