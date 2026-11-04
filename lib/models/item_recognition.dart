/// How sure the model is about what is in the photo
enum RecognitionConfidence {
  high('Khá chắc chắn'),
  medium('Có thể đúng'),
  low('Chưa chắc');

  final String label;

  const RecognitionConfidence(this.label);

  static RecognitionConfidence parse(Object? value) => switch (value) {
    'high' => RecognitionConfidence.high,
    'medium' => RecognitionConfidence.medium,
    _ => RecognitionConfidence.low,
  };
}

/// "Chụp để tìm": what the AI thinks the photographed item is.
/// Nothing here is checked against a shop: price is a rough AI estimate.
class ItemRecognition {
  /// Short product name to search for, e.g. "Chuột không dây Logitech MX Master 3S"
  final String name;
  final String? brand;

  /// Kind of item in Vietnamese, e.g. "Chuột máy tính"
  final String? category;

  /// Other things the item could be (at most [maxAlternatives])
  final List<String> alternatives;
  final int? priceMinVnd;
  final int? priceMaxVnd;
  final RecognitionConfidence confidence;

  static const int maxAlternatives = 3;

  const ItemRecognition({
    required this.name,
    this.brand,
    this.category,
    this.alternatives = const [],
    this.priceMinVnd,
    this.priceMaxVnd,
    this.confidence = RecognitionConfidence.low,
  });

  /// The model found no product in the photo
  bool get isEmpty => name.isEmpty;

  bool get hasPriceRange => priceMinVnd != null && priceMaxVnd != null;

  /// Text searched in shops: the chosen name, plus the brand when the name lacks it
  static String searchQuery(String name, {String? brand}) {
    final b = brand?.trim() ?? '';
    if (b.isEmpty || name.toLowerCase().contains(b.toLowerCase())) {
      return name.trim();
    }
    return '$b ${name.trim()}';
  }
}

/// Where "Chụp để tìm" sends the user to compare prices. Each link opens the shop's own
/// search already sorted from the lowest price, so the cheapest offers come first.
enum ShopSite {
  shopee('Shopee'),
  lazada('Lazada'),
  tiki('Tiki'),
  googleShopping('Google Shopping');

  final String label;

  const ShopSite(this.label);

  Uri cheapestFirstUrl(String query) => switch (this) {
    ShopSite.shopee => Uri.https('shopee.vn', '/search', {
      'keyword': query,
      'sortBy': 'price',
      'order': 'asc',
    }),
    ShopSite.lazada => Uri.https('www.lazada.vn', '/catalog/', {
      'q': query,
      'sort': 'priceasc',
    }),
    ShopSite.tiki => Uri.https('tiki.vn', '/search', {
      'q': query,
      'sort': 'price,asc',
    }),
    ShopSite.googleShopping => Uri.https('www.google.com', '/search', {
      'tbm': 'shop',
      'q': query,
      'tbs': 'p_ord:p',
    }),
  };
}
