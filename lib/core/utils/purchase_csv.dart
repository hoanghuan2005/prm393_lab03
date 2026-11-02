import '../../models/budget_group.dart';
import '../../models/purchase_item.dart';

/// "Xuất dữ liệu" (screen 10): the purchase log and its motives as CSV.
/// UTF-8 with a BOM and CRLF line ends, so Excel opens Vietnamese text correctly.
class PurchaseCsv {
  PurchaseCsv._();

  static const List<String> header = [
    'Ngày',
    'Giờ',
    'Tên món',
    'Số tiền (VND)',
    'Động cơ',
    'Nhóm ngân sách',
    'Ghi chú',
    'Dùng mã giảm giá',
    'Mức hài lòng (1-5)',
    'Từ danh sách mong muốn',
  ];

  static const String bom = '﻿';

  /// `whyibuy-10-2026.csv` (Figma screen 10 "đã xuất dữ liệu"), without extension
  static String fileName(DateTime now) =>
      'whyibuy-${_two(now.month)}-${now.year}';

  /// Oldest first, like a diary. Unknown group ids keep their id as the name.
  static String build(List<PurchaseItem> purchases, List<BudgetGroup> groups) {
    final groupNames = {for (final g in groups) g.id: g.name};
    final sorted = [...purchases]
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    final rows = <List<String>>[
      header,
      for (final p in sorted)
        [
          '${p.occurredAt.year}-${_two(p.occurredAt.month)}-${_two(p.occurredAt.day)}',
          '${_two(p.occurredAt.hour)}:${_two(p.occurredAt.minute)}',
          p.title,
          '${p.amountVnd}',
          p.motive.label,
          groupNames[p.budgetGroupId] ?? p.budgetGroupId,
          p.note ?? '',
          p.usedDiscountCode ? 'Có' : 'Không',
          p.satisfaction?.toString() ?? '',
          p.wishlistItemId != null ? 'Có' : 'Không',
        ],
    ];
    return bom + rows.map((r) => r.map(escape).join(',')).join('\r\n');
  }

  /// Quotes a field when needed. Text starting with = + - @ (or a tab/CR) is prefixed
  /// with ' so a spreadsheet does not run it as a formula; plain numbers are kept.
  static String escape(String field) {
    var value = field;
    final isNumber = RegExp(r'^-?\d+$').hasMatch(value);
    if (!isNumber && value.isNotEmpty && '=+-@\t\r'.contains(value[0])) {
      value = "'$value";
    }
    if (value.contains(RegExp(r'[",\r\n]'))) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
