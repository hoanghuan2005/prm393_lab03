import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../models/purchase_item.dart';
import '../models/wishlist_item.dart';
import '../models/wishlist_status.dart';

/// Service responsible solely for rendering PDF documents (Single Responsibility per CR-02).
/// Receives data that already belongs to one month; it never fetches anything.
class ReportService {
  Future<Uint8List> generateMonthlyReportPdf({
    required String userName,
    required DateTime month,
    required List<PurchaseItem> purchases,
    required List<WishlistItem> decidedItems,
  }) async {
    final pdf = pw.Document();

    final total = purchases.fold(0, (sum, p) => sum + p.amountVnd);
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

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('FFDE02'),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(8),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'WHY I BUY - REPORT',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('070E20'),
                      ),
                    ),
                    pw.Text(
                      '${month.month}/${month.year}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColor.fromHex('070E20'),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // User Info
              pw.Text(
                'Nguoi dung: $userName',
                style: const pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 16),

              // Summary Stats
              pw.Text(
                'Tong quan thang:',
                style: const pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Bullet(text: 'So khoan mua da ghi: ${purchases.length}'),
              pw.Bullet(text: 'Tong da chi: ${formatVnd(total)}'),
              pw.Bullet(text: 'Mon da quyet dinh mua: ${boughtItems.length}'),
              pw.Bullet(
                text: 'Mon da quyet dinh khong mua: ${skippedItems.length}',
              ),
              pw.Bullet(
                text:
                    'Gia tri mon da quyet dinh khong mua: ${formatVnd(skippedValue)}',
              ),
              pw.SizedBox(height: 20),

              // Purchases Table
              pw.Text(
                'Khoan mua trong thang:',
                style: const pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: ['Ngay', 'Ten', 'So tien', 'Dong co'],
                data: purchases.map((p) {
                  return [
                    formatDate(p.occurredAt),
                    p.title,
                    formatVnd(p.amountVnd),
                    p.motive.label,
                  ];
                }).toList(),
                headerStyle: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                ),
                cellAlignment: pw.Alignment.centerLeft,
              ),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }
}
