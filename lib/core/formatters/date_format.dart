import 'package:intl/intl.dart';

const List<String> _weekdays = [
  'Thứ Hai',
  'Thứ Ba',
  'Thứ Tư',
  'Thứ Năm',
  'Thứ Sáu',
  'Thứ Bảy',
  'Chủ Nhật',
];

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool isToday(DateTime dt, {DateTime? now}) =>
    isSameDay(dt, now ?? DateTime.now());

bool isYesterday(DateTime dt, {DateTime? now}) =>
    isSameDay(dt, (now ?? DateTime.now()).subtract(const Duration(days: 1)));

/// "12:15"
String formatTime(DateTime dt) => DateFormat('HH:mm').format(dt);

/// "26/10/2026"
String formatDate(DateTime dt) => DateFormat('dd/MM/yyyy').format(dt);

/// "26/10"
String formatDayMonth(DateTime dt) => DateFormat('dd/MM').format(dt);

/// "Hôm nay 12:15", "Hôm qua 23:40", otherwise "24/10 08:05"
String formatRelativeDateTime(DateTime dt, {DateTime? now}) {
  final time = formatTime(dt);
  if (isToday(dt, now: now)) return 'Hôm nay $time';
  if (isYesterday(dt, now: now)) return 'Hôm qua $time';
  return '${formatDayMonth(dt)} $time';
}

/// "Thứ Hai, 26/10/2026"
String formatWeekdayDate(DateTime dt) =>
    '${_weekdays[dt.weekday - 1]}, ${formatDate(dt)}';

/// "Tháng 10/2026"
String formatMonthLabel(DateTime month) => 'Tháng ${month.month}/${month.year}';
