final RegExp _thousands = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');

/// 4.8 → "4,8"
String formatStars(double stars) =>
    stars.toStringAsFixed(1).replaceAll('.', ',');

/// 1200 → "1.200"
String formatCount(int count) =>
    count.toString().replaceAllMapped(_thousands, (m) => '${m[1]}.');

/// "★ 4,8 (1.200 đánh giá)"; null without product stars
String? formatProductRating(double? stars, int? count) {
  if (stars == null) return null;
  return [
    '★ ${formatStars(stars)}',
    if (count != null && count > 0) '(${formatCount(count)} đánh giá)',
  ].join(' ');
}

/// "Shop Mây ★ 4,9": the shop name exactly as stored, then its stars; null when
/// neither is known
String? formatShopRating(String? shopName, double? stars) {
  final name = shopName?.trim();
  final parts = [
    if (name != null && name.isNotEmpty) name,
    if (stars != null) '★ ${formatStars(stars)}',
  ];
  return parts.isEmpty ? null : parts.join(' ');
}
