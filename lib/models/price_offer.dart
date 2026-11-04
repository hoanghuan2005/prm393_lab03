import '../services/ai_service.dart';

/// One place selling the item, as AI read it from Google Search results.
/// Prices come from web pages and may be out of date; the UI says so.
class PriceOffer {
  final String shop;
  final int priceVnd;
  final Uri? url;

  const PriceOffer({required this.shop, required this.priceVnd, this.url});
}

/// "AI tìm giá ở các shop": offers sorted cheapest first, plus what Google requires
/// the app to show next to grounded answers (sources and search suggestions)
class PriceSearchResult {
  final String query;
  final List<PriceOffer> offers;
  final List<WebSource> sources;
  final String? searchEntryPointHtml;

  PriceSearchResult({
    required this.query,
    required List<PriceOffer> offers,
    this.sources = const [],
    this.searchEntryPointHtml,
  }) : offers = [...offers]..sort((a, b) => a.priceVnd.compareTo(b.priceVnd));

  bool get isEmpty => offers.isEmpty;

  PriceOffer? get cheapest => offers.isEmpty ? null : offers.first;
}
