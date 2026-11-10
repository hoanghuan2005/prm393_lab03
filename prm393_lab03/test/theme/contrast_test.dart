import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/utils/contrast.dart';

void main() {
  test('WCAG black/white is 21; identical colours are 1', () {
    expect(contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)), 21);
    expect(contrastRatio(const Color(0xFFFFFFFF), const Color(0xFF000000)), 21);
    expect(contrastRatio(const Color(0xFF123456), const Color(0xFF123456)), 1);
  });

  test('alpha is composited before measuring', () {
    expect(contrastRatio(const Color(0x00000000), const Color(0xFFFFFFFF)), 1);
    final gray = Color.alphaBlend(
      const Color(0x80000000),
      const Color(0xFFFFFFFF),
    );
    expect(
      contrastRatio(const Color(0x80000000), const Color(0xFFFFFFFF)),
      contrastRatio(gray, const Color(0xFFFFFFFF)),
    );
    expect(
      () => contrastRatio(const Color(0xFFFFFFFF), const Color(0x80000000)),
      throwsArgumentError,
    );
  });
}
