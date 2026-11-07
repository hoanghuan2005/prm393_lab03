/// Vietnamese text without diacritics, case kept: "Đồng hồ ĐẸP" → "Dong ho DEP".
/// đ/Đ become d/D. Combining marks (a letter typed as letter + mark, e.g. e + U+0301)
/// are removed too, so precomposed and decomposed text give the same result.
String removeVietnameseDiacritics(String text) {
  final out = StringBuffer();
  for (final rune in text.runes) {
    if (rune >= 0x0300 && rune <= 0x036F) continue;
    final char = String.fromCharCode(rune);
    out.write(_plainLetter[char] ?? char);
  }
  return out.toString();
}

const _accentGroups = {
  'a': 'àáạảãâầấậẩẫăằắặẳẵ',
  'e': 'èéẹẻẽêềếệểễ',
  'i': 'ìíịỉĩ',
  'o': 'òóọỏõôồốộổỗơờớợởỡ',
  'u': 'ùúụủũưừứựửữ',
  'y': 'ỳýỵỷỹ',
  'd': 'đ',
  'A': 'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ',
  'E': 'ÈÉẸẺẼÊỀẾỆỂỄ',
  'I': 'ÌÍỊỈĨ',
  'O': 'ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ',
  'U': 'ÙÚỤỦŨƯỪỨỰỬỮ',
  'Y': 'ỲÝỴỶỸ',
  'D': 'Đ',
};

final Map<String, String> _plainLetter = {
  for (final e in _accentGroups.entries)
    for (final c in e.value.split('')) c: e.key,
};
