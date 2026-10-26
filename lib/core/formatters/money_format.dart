final RegExp _thousands = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
final RegExp _nonDigits = RegExp(r'[^0-9]');

/// 389000 → "389.000 ₫"; null → [empty] (a missing price is never shown as 0)
String formatVnd(int? amount, {String empty = 'Chưa có giá'}) {
  if (amount == null) return empty;
  final digits = amount.abs().toString().replaceAllMapped(
    _thousands,
    (m) => '${m[1]}.',
  );
  return '${amount < 0 ? '-' : ''}$digits ₫';
}

/// "389.000 ₫" → 389000; returns null when nothing is entered or the value is 0
int? parseVnd(String input) {
  final digits = input.replaceAll(_nonDigits, '');
  if (digits.isEmpty) return null;
  final value = int.tryParse(digits);
  if (value == null || value == 0) return null;
  return value;
}
