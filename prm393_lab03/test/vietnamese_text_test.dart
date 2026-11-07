import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/utils/vietnamese_text.dart';

void main() {
  group('removeVietnameseDiacritics', () {
    test('every tone and vowel mark, case kept', () {
      expect(
        removeVietnameseDiacritics('Tiếng Việt có dấu'),
        'Tieng Viet co dau',
      );
      expect(
        removeVietnameseDiacritics('àáạảã âầấậẩẫ ăằắặẳẵ ơờớợởỡ ưừứựửữ ỳýỵỷỹ'),
        'aaaaa aaaaaa aaaaaa oooooo uuuuuu yyyyy',
      );
    });

    test('capital letters', () {
      expect(removeVietnameseDiacritics('ĐỒNG HỒ ĐẸP'), 'DONG HO DEP');
      expect(
        removeVietnameseDiacritics('ÀÁẠẢÃ ÂẦẤẬẨẪ ĂẰẮẶẲẴ ÈÉẸẺẼ ÊỀẾỆỂỄ'),
        'AAAAA AAAAAA AAAAAA EEEEE EEEEEE',
      );
      expect(
        removeVietnameseDiacritics(
          'ÌÍỊỈĨ ÒÓỌỎÕ ÔỒỐỘỔỖ ƠỜỚỢỞỠ ÙÚỤỦŨ ƯỪỨỰỬỮ ỲÝỴỶỸ',
        ),
        'IIIII OOOOO OOOOOO OOOOOO UUUUU UUUUUU YYYYY',
      );
    });

    test('đ and Đ become d and D', () {
      expect(removeVietnameseDiacritics('đ'), 'd');
      expect(removeVietnameseDiacritics('Đ'), 'D');
      expect(removeVietnameseDiacritics('Đen đỏ'), 'Den do');
    });

    test('combining marks (letter + mark) give the same result', () {
      // "Việt" typed as V i e + circumflex + dot below + t
      expect(removeVietnameseDiacritics('Vie\u0302\u0323t'), 'Viet');
      expect(removeVietnameseDiacritics('nha\u0301m'), 'nham');
      expect(removeVietnameseDiacritics('O\u031B\u0300'), 'O');
    });

    test('other text is left as it is', () {
      expect(
        removeVietnameseDiacritics('K-Sound A3 (128 GB)!'),
        'K-Sound A3 (128 GB)!',
      );
      expect(removeVietnameseDiacritics(''), '');
    });
  });
}
