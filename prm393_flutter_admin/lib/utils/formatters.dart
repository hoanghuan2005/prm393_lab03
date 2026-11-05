import 'package:why_i_buy_core/why_i_buy_core.dart';

/// 1234000 → "1.234.000 ₫"
String formatVnd(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer(amount < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '$buffer ₫';
}

/// "05/11/2026 14:30"
String formatDateTime(DateTime d) =>
    '${formatDay(d)} ${d.hour.toString().padLeft(2, '0')}:'
    '${d.minute.toString().padLeft(2, '0')}';

/// "T2" … "CN"
String weekdayLabel(DateTime d) =>
    d.weekday == DateTime.sunday ? 'CN' : 'T${d.weekday + 1}';

/// Last characters of an id: enough to tell users apart without personal data
String shortId(String id) =>
    id.length <= 6 ? id : '…${id.substring(id.length - 6)}';
