import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/item_status.dart';
import '../models/wishlist_item.dart';

/// Service responsible solely for rendering PDF documents (Single Responsibility per CR-02)
class ReportService {
  Future<Uint8List> generateMonthlyReportPdf({
    required String userName,
    required List<WishlistItem> items,
    required double totalSaved,
  }) async {
    final pdf = pw.Document();

    final boughtItems = items.where((i) => i.status == ItemStatus.bought).toList();
    final droppedItems = items.where((i) => i.status == ItemStatus.dropped).toList();
    final waitingItems = items.where((i) => i.status == ItemStatus.considering || i.status == ItemStatus.waiting).toList();

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
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
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
                      DateTime.now().toString().substring(0, 10),
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
              pw.Text('Nguoi dung: $userName', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text(
                'Tiet kiem thanh cong tu viec hoan mua: ${totalSaved.toStringAsFixed(0)} VND',
                style: pw.TextStyle(fontSize: 14, color: PdfColor.fromHex('10B981'), fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 16),

              // Summary Stats
              pw.Text('Thong ke quyet dinh:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Bullet(text: 'Tong so mon can nhac: ${items.length}'),
              pw.Bullet(text: 'Mon da quyet dinh mua: ${boughtItems.length}'),
              pw.Bullet(text: 'Mon da chu dong bo qua: ${droppedItems.length}'),
              pw.Bullet(text: 'Mon dang trong thoi gian hoan tam ly: ${waitingItems.length}'),
              pw.SizedBox(height: 20),

              // Items Table
              pw.Text('Danh sach mon hang gan day:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: ['Ten mon', 'Gia (VND)', 'Dong co', 'Trang thai'],
                data: items.take(10).map((item) {
                  return [
                    item.title,
                    item.price.toStringAsFixed(0),
                    item.motive.label,
                    item.status.label,
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
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
