/// Product and variant codes of priceHistory (G8): the same item sold by several shops
/// shares one productCode, e.g. "ksound-a3-pro"; its variants share a variant code,
/// e.g. "den-nham". firestore.rules accept `^[a-z0-9]+(-[a-z0-9]+)*$` only.
library;

import 'vietnamese_text.dart';

const int maxProductCodeLength = 60;
const int maxVariantCodeLength = 30;

/// A number and the unit right after it become one part: "128 gb" → "128gb"
final _numberUnit = RegExp(r'(\d)\s+(mah|inch|gb|tb|mb|ml|kg|cm|mm|l|g|w)\b');
final _notCodeChar = RegExp(r'[^a-z0-9\s]');
final _spaces = RegExp(r'\s+');
final _dashes = RegExp(r'-+');

/// One part of a code: Vietnamese diacritics removed (đ → d), lowercase, a number
/// joined to its unit ("128 GB" → "128gb"), every other character removed
/// ("K-Sound" → "ksound"), words joined by '-' ("Đen nhám" → "den-nham").
/// Empty when nothing is left.
String normalizeCodePart(String text) {
  return removeVietnameseDiacritics(text.toLowerCase())
      .replaceAll(_notCodeChar, '')
      .replaceAllMapped(_numberUnit, (m) => '${m[1]}${m[2]}')
      .trim()
      .replaceAll(_spaces, '-')
      .replaceAll(_dashes, '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

/// "ksound-a3", "ksound-a3-pro", "nova-x5-128gb"; null without a brand or a model
String? buildProductCode(String? brand, String? model, [String? spec]) {
  final b = normalizeCodePart(brand ?? '');
  final m = normalizeCodePart(model ?? '');
  if (b.isEmpty || m.isEmpty) return null;
  return _join([b, m, normalizeCodePart(spec ?? '')], maxProductCodeLength);
}

/// "den-nham", "den-xl", "xanh-256gb"; null when every part is empty
String? buildVariantCode([String? color, String? size, String? capacity]) {
  final code = _join([
    for (final part in [color, size, capacity]) normalizeCodePart(part ?? ''),
  ], maxVariantCodeLength);
  return code.isEmpty ? null : code;
}

/// Non-empty parts joined by '-', cut to [max] characters without a trailing '-'
String _join(List<String> parts, int max) {
  final code = parts.where((p) => p.isNotEmpty).join('-');
  if (code.length <= max) return code;
  return code.substring(0, max).replaceAll(RegExp(r'-+$'), '');
}
