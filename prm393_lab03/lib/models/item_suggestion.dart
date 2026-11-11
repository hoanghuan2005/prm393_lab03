import '../core/utils/vietnamese_text.dart';
import 'budget_group.dart';

final _asciiLetterOrDigit = RegExp(r'[a-z0-9]');
final _spaces = RegExp(r'\s+');

/// Lowercase, Vietnamese diacritics removed, punctuation turned into spaces:
/// "Tai nghe Sony WH-1000XM5!" → "tai nghe sony wh 1000xm5"
String normalizeTitle(String text) {
  final buffer = StringBuffer();
  for (final rune in removeVietnameseDiacritics(text.toLowerCase()).runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_asciiLetterOrDigit.hasMatch(char) ? char : ' ');
  }
  return buffer.toString().trim().replaceAll(_spaces, ' ');
}

/// Like [normalizeTitle] but tone marks are kept: "Kiểm tra!" → "kiểm tra"
String _normalizeKeepingTones(String text) {
  final buffer = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    final isLetterOrDigit = _asciiLetterOrDigit.hasMatch(
      removeVietnameseDiacritics(char),
    );
    buffer.write(isLetterOrDigit ? char : ' ');
  }
  return buffer.toString().trim().replaceAll(_spaces, ' ');
}

/// Letters typed as letter + combining mark cannot be compared with the keywords
bool _hasCombiningMarks(String text) =>
    text.runes.any((r) => r >= 0x0300 && r <= 0x036F);

/// Words that only describe quantity or form, not what the item is
final _stopWords = 'cai chiec bo doi mon do cho va voi cua loai size mau moi hang chinh san pham sp the'
    .split(' ')
    .toSet();

/// Meaningful words of a title, used to compare two titles
Set<String> titleTokens(String title) => {
  for (final t in normalizeTitle(title).split(' '))
    if (t.length >= 2 && !_stopWords.contains(t)) t,
};

bool _isNumber(String token) => RegExp(r'^\d+$').hasMatch(token);

/// Keywords per default budget group, separated by commas. A title takes the group
/// of its longest matching phrase, so "kem chống nắng" is Làm đẹp, not Ăn uống.
///
/// Keywords carry their tone marks: a title typed with tone marks is compared with
/// them, so "kiểm tra" is not "trà" and "sơn tường" is not "son". A title typed
/// without any tone mark is compared without them (see [guessBudgetGroup]).
const Map<String, String> budgetGroupKeywords = {
  'food': 'trà sữa, cà phê, cafe, coffee, cơm, bún, phở, mì tôm, bánh mì, bánh, pizza, gà rán, lẩu, đồ ăn, ăn vặt, snack, nước ép, nước ngọt, sinh tố, trà, buffet, ăn trưa, ăn tối, ăn sáng, kem que, kem ly',
  'fashion': 'áo, quần, váy, đầm, giày, dép, túi, túi xách, balo, mũ, nón, thắt lưng, khăn, tất, ví da, áo khoác, hoodie, sneaker, jean, jeans, sơ mi, đồng hồ, kính mát, trang sức',
  'tech': 'tai nghe, điện thoại, iphone, samsung, xiaomi, laptop, máy tính, bàn phím, chuột, màn hình, sạc, cáp sạc, loa, đồng hồ thông minh, smartwatch, airpods, ipad, máy tính bảng, ốp lưng, usb, ổ cứng, tay cầm, camera, máy ảnh, tablet, macbook, pin dự phòng, headphone, earbuds, router, phần mềm, ứng dụng',
  'beauty': 'son, kem dưỡng, kem chống nắng, sữa rửa mặt, nước hoa, mặt nạ, serum, toner, phấn, mascara, trang điểm, cắt tóc, làm tóc, làm nail, nail, mỹ phẩm, dầu gội, sữa tắm, tẩy trang, nước tẩy trang, dưỡng ẩm',
  'study': 'sách, giáo trình, khoá học, khóa học, học phí, bút, bút bi, casio, máy tính casio, ielts, toeic, tiếng anh, udemy, coursera, lớp học, tài liệu, vở viết',
};

final Map<String, List<String>> _tonedPhrases = {
  for (final e in budgetGroupKeywords.entries) e.key: e.value.split(', '),
};

final Map<String, List<String>> _plainPhrases = {
  for (final e in _tonedPhrases.entries)
    e.key: e.value.map(normalizeTitle).toSet().toList(),
};

/// Budget group guessed from keywords, or null when no keyword matches.
/// Only ever shown as a suggestion the user taps to accept.
String? guessBudgetGroup(String title) {
  final plain = normalizeTitle(title);
  final toned = _hasCombiningMarks(title)
      ? plain
      : _normalizeKeepingTones(title);
  // No tone mark at all ("tra sua"): fall back to comparing without them
  final useTones = toned != plain;
  final padded = ' ${useTones ? toned : plain} ';
  final phrasesByGroup = useTones ? _tonedPhrases : _plainPhrases;
  String? best;
  var bestWords = 0;
  for (final group in defaultBudgetGroups) {
    for (final phrase in phrasesByGroup[group.id] ?? const <String>[]) {
      final words = phrase.split(' ').length;
      if (words > bestWords && padded.contains(' $phrase ')) {
        best = group.id;
        bestWords = words;
      }
    }
  }
  return best;
}

/// A budget group offered to the user; never applied without a tap
class GroupSuggestion {
  final String groupId;
  final bool fromAi;

  const GroupSuggestion({required this.groupId, required this.fromAi});
}

enum DuplicateSource { purchase, wishlist, owned }

/// Something the user already bought (last 30 days) or is already considering
class DuplicateCandidate {
  final String id;
  final String title;
  final DuplicateSource source;
  final String? budgetGroupId;

  /// Purchase date, or the day a wishlist item was saved
  final DateTime date;

  /// Actual amount for a purchase; latest price (possibly unknown) for a wishlist item
  final int? amountVnd;

  const DuplicateCandidate({
    required this.id,
    required this.title,
    required this.source,
    required this.date,
    this.budgetGroupId,
    this.amountVnd,
  });
}

class DuplicateMatch {
  final DuplicateCandidate candidate;
  final bool fromAi;

  const DuplicateMatch({required this.candidate, required this.fromAi});
}

/// How alike two titles are, from their meaningful words
enum TitleSimilarity {
  /// Clearly the same kind of item; shown without asking AI
  likely,

  /// Shares a word or a budget group; AI decides
  possible,
  none,
}

TitleSimilarity compareTitles(
  Set<String> a,
  Set<String> b, {
  bool sameGroup = false,
}) {
  if (a.isEmpty || b.isEmpty) return TitleSimilarity.none;
  final shared = a.intersection(b);
  final sharedWords = shared.where((t) => !_isNumber(t)).length;
  final overlap = shared.length / (a.length < b.length ? a.length : b.length);
  if (sharedWords >= 1 &&
      overlap >= 0.6 &&
      (shared.length >= 2 || (a.length == 1 && b.length == 1))) {
    return TitleSimilarity.likely;
  }
  if (sharedWords >= 1 || sameGroup) return TitleSimilarity.possible;
  return TitleSimilarity.none;
}

/// Share of the shorter title's words found in the other; orders AI candidates
double titleOverlap(Set<String> a, Set<String> b) {
  if (a.isEmpty || b.isEmpty) return 0;
  return a.intersection(b).length / (a.length < b.length ? a.length : b.length);
}
