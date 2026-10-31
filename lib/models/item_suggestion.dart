import 'budget_group.dart';

/// Lowercase, Vietnamese diacritics removed, punctuation turned into spaces:
/// "Tai nghe Sony WH-1000XM5!" → "tai nghe sony wh 1000xm5"
String normalizeTitle(String text) {
  final buffer = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    final plain = _plainLetter[char] ?? char;
    buffer.write(RegExp(r'[a-z0-9]').hasMatch(plain) ? plain : ' ');
  }
  return buffer.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
}

const _accentGroups = {
  'a': 'àáạảãâầấậẩẫăằắặẳẵ',
  'e': 'èéẹẻẽêềếệểễ',
  'i': 'ìíịỉĩ',
  'o': 'òóọỏõôồốộổỗơờớợởỡ',
  'u': 'ùúụủũưừứựửữ',
  'y': 'ỳýỵỷỹ',
  'd': 'đ',
};

final Map<String, String> _plainLetter = {
  for (final e in _accentGroups.entries)
    for (final c in e.value.split('')) c: e.key,
};

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

/// Keywords per default budget group, written without diacritics and separated by
/// commas. A title takes the group of its longest matching phrase, so "kem chống nắng"
/// is Làm đẹp, not Ăn uống.
const Map<String, String> budgetGroupKeywords = {
  'food': 'tra sua, ca phe, cafe, coffee, com, bun, pho, mi tom, banh mi, banh, pizza, ga ran, lau, do an, an vat, snack, nuoc ep, nuoc ngot, sinh to, tra, buffet, an trua, an toi, an sang, kem que, kem ly',
  'fashion': 'ao, quan, vay, dam, giay, dep, tui, tui xach, balo, mu, non, that lung, khan, tat, vi da, ao khoac, hoodie, sneaker, jean, jeans, so mi, dong ho, kinh mat, trang suc',
  'tech': 'tai nghe, dien thoai, iphone, samsung, xiaomi, laptop, may tinh, ban phim, chuot, man hinh, sac, cap sac, loa, dong ho thong minh, smartwatch, airpods, ipad, may tinh bang, op lung, usb, o cung, tay cam, camera, may anh, tablet, macbook, pin du phong, headphone, earbuds, router, phan mem, ung dung',
  'beauty': 'son, kem duong, kem chong nang, sua rua mat, nuoc hoa, mat na, serum, toner, phan, mascara, trang diem, cat toc, lam toc, lam nail, nail, my pham, dau goi, sua tam, tay trang, nuoc tay trang, duong am',
  'study': 'sach, giao trinh, khoa hoc, hoc phi, but, but bi, casio, may tinh casio, ielts, toeic, tieng anh, udemy, coursera, lop hoc, tai lieu, vo viet',
};

final Map<String, List<String>> _keywordPhrases = {
  for (final e in budgetGroupKeywords.entries) e.key: e.value.split(', '),
};

/// Budget group guessed from keywords, or null when no keyword matches
String? guessBudgetGroup(String title) {
  final padded = ' ${normalizeTitle(title)} ';
  String? best;
  var bestWords = 0;
  for (final group in defaultBudgetGroups) {
    for (final phrase in _keywordPhrases[group.id] ?? const <String>[]) {
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
