import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/utils/product_code.dart';

/// The pattern firestore.rules accept for productCode and variant codes
final _rulesPattern = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

void main() {
  group('normalizeCodePart', () {
    test('every character outside [a-z0-9 ] is removed, not replaced', () {
      expect(normalizeCodePart('K-Sound'), 'ksound');
      expect(normalizeCodePart('WH-1000XM5'), 'wh1000xm5');
      expect(normalizeCodePart('Pro+ (2026)!'), 'pro-2026');
    });

    test('Vietnamese diacritics removed, đ → d, words joined by -', () {
      expect(normalizeCodePart('Đen nhám'), 'den-nham');
      expect(normalizeCodePart('XANH DƯƠNG'), 'xanh-duong');
      // The same letters typed as letter + combining mark
      expect(normalizeCodePart('Đen nha\u0301m'), 'den-nham');
    });

    test('a number is joined to the unit right after it', () {
      expect(normalizeCodePart('128 GB'), '128gb');
      expect(normalizeCodePart('500 ml'), '500ml');
      expect(normalizeCodePart('5000 mAh'), '5000mah');
      expect(normalizeCodePart('2 l'), '2l');
      expect(normalizeCodePart('27 inch'), '27inch');
      expect(normalizeCodePart('16 GB RAM 1 TB'), '16gb-ram-1tb');
      // Not a unit: kept apart
      expect(normalizeCodePart('128 gaming'), '128-gaming');
    });

    test('repeated and outer dashes are dropped', () {
      expect(normalizeCodePart('  - Nova  --  X5 - '), 'nova-x5');
      expect(normalizeCodePart('!!!'), '');
      expect(normalizeCodePart(''), '');
    });
  });

  group('buildProductCode', () {
    test('brand, model and optional spec', () {
      expect(buildProductCode('K-Sound', 'A3', null), 'ksound-a3');
      expect(buildProductCode('K-Sound', 'A3 Pro'), 'ksound-a3-pro');
      expect(buildProductCode('Nova', 'X5', '128 GB'), 'nova-x5-128gb');
    });

    test('null without a brand or a model', () {
      expect(buildProductCode(null, 'A3'), isNull);
      expect(buildProductCode('K-Sound', null), isNull);
      expect(buildProductCode('  ', 'A3'), isNull);
      expect(buildProductCode('K-Sound', '---'), isNull);
    });

    test('at most 60 characters, still accepted by the rules', () {
      final code = buildProductCode('Brand', 'model ' * 20, '256 GB')!;
      expect(code.length, lessThanOrEqualTo(maxProductCodeLength));
      expect(code, matches(_rulesPattern));
    });
  });

  group('buildVariantCode', () {
    test('non-empty parts joined by -', () {
      expect(buildVariantCode('Đen nhám'), 'den-nham');
      expect(buildVariantCode('Xanh', 'XL'), 'xanh-xl');
      expect(buildVariantCode(null, null, '256 GB'), '256gb');
      expect(buildVariantCode('', 'M', null), 'm');
    });

    test('null when every part is empty', () {
      expect(buildVariantCode(), isNull);
      expect(buildVariantCode(null, ' ', '-'), isNull);
    });

    test('at most 30 characters, still accepted by the rules', () {
      final code = buildVariantCode(
        'xanh duong nhat pha trang',
        'XXL',
        '1 TB',
      )!;
      expect(code.length, lessThanOrEqualTo(maxVariantCodeLength));
      expect(code, matches(_rulesPattern));
    });
  });
}
