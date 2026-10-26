import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../models/purchase_item.dart';
import '../models/spending_insight.dart';
import '../models/wishlist_item.dart';
import '../models/wishlist_status.dart';

/// Service responsible solely for rendering PDF documents (Single Responsibility per CR-02).
/// Receives data that already belongs to one month; it never fetches anything.
///
/// The built-in PDF fonts have no Vietnamese diacritics and no "₫", so the report embeds
/// Be Vietnam Pro (the app's design-system font, SIL OFL, assets/fonts/) and works offline.
class ReportService {
  static const String _regularFont = 'assets/fonts/BeVietnamPro-Regular.ttf';
  static const String _boldFont = 'assets/fonts/BeVietnamPro-Bold.ttf';

  final AssetBundle _bundle;
  pw.ThemeData? _theme;

  ReportService({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  Future<pw.ThemeData> _loadTheme() async {
    final cached = _theme;
    if (cached != null) return cached;
    final regular = pw.Font.ttf(await _bundle.load(_regularFont));
    final bold = pw.Font.ttf(await _bundle.load(_boldFont));
    return _theme = pw.ThemeData.withFont(base: regular, bold: bold);
  }

  Future<Uint8List> generateMonthlyReportPdf({
    required String userName,
    required DateTime month,
    required List<PurchaseItem> purchases,
    required List<WishlistItem> decidedItems,
  }) async {
    final theme = await _loadTheme();
    final pdf = pw.Document(
      theme: theme,
      title: 'Why I Buy – ${formatMonthLabel(month)}',
      author: 'Why I Buy',
    );

    final sorted = [...purchases]
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    final total = sorted.fold(0, (sum, p) => sum + p.amountVnd);
    final boughtItems = decidedItems
        .where((i) => i.status == WishlistStatus.purchased)
        .toList();
    final skippedItems = decidedItems
        .where((i) => i.status == WishlistStatus.skipped)
        .toList();
    final skippedValue = skippedItems.fold(
      0,
      (sum, i) => sum + (i.latestPriceVnd ?? 0),
    );
    final dark = PdfColor.fromHex('070E20');
    const sectionStyle = pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
    );

    pdf.addPage(
      // MultiPage: long purchase lists continue on the next page, table header repeated
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Trang ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (pw.Context context) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('FFDE02'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'WHY I BUY – CHIÊM NGHIỆM THÁNG',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: dark,
                  ),
                ),
                pw.Text(
                  formatMonthLabel(month),
                  style: pw.TextStyle(fontSize: 12, color: dark),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Người dùng: $userName', style: sectionStyle),
          pw.SizedBox(height: 12),
          pw.Divider(),
          pw.SizedBox(height: 12),

          // Summary
          pw.Text('Tổng quan tháng', style: sectionStyle),
          pw.SizedBox(height: 8),
          pw.Bullet(text: 'Số khoản mua đã ghi: ${sorted.length}'),
          pw.Bullet(text: 'Tổng đã chi: ${formatVnd(total)}'),
          pw.Bullet(text: 'Món đã quyết định mua: ${boughtItems.length}'),
          pw.Bullet(
            text: 'Món đã quyết định không mua: ${skippedItems.length}',
          ),
          if (skippedItems.isNotEmpty)
            pw.Bullet(
              text:
                  'Giá trị món đã quyết định không mua: '
                  '${MonthlySpendingStats.describeSkippedValue(skippedValue: skippedValue, skippedCount: skippedItems.length, unpricedCount: skippedItems.where((i) => i.latestPriceVnd == null).length)}',
            ),
          pw.SizedBox(height: 20),

          // Purchases table
          pw.Text('Khoản mua trong tháng', style: sectionStyle),
          pw.SizedBox(height: 8),
          if (sorted.isEmpty)
            pw.Text('Chưa có khoản mua nào được ghi trong tháng này.')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Ngày', 'Tên', 'Số tiền', 'Động cơ'],
              data: [
                for (final p in sorted)
                  [
                    formatDate(p.occurredAt),
                    p.title,
                    formatVnd(p.amountVnd),
                    p.motive.label,
                  ],
              ],
              headerStyle: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {2: pw.Alignment.centerRight},
              columnWidths: {
                0: const pw.FixedColumnWidth(70),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FixedColumnWidth(90),
                3: const pw.FlexColumnWidth(2),
              },
            ),
        ],
      ),
    );

    return await pdf.save();
  }
}
