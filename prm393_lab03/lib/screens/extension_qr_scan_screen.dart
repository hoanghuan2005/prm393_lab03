import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/extension_session.dart';
import '../theme/app_text_styles.dart';

/// Cá nhân → Thiết bị đã liên kết → "Quét mã QR": reads the QR shown by the Chrome
/// extension and pops with its pairing id (null when the user goes back).
class ExtensionQrScanScreen extends StatefulWidget {
  const ExtensionQrScanScreen({super.key});

  static Future<String?> open(BuildContext context) => Navigator.of(context)
      .push<String>(
        MaterialPageRoute(builder: (_) => const ExtensionQrScanScreen()),
      );

  @override
  State<ExtensionQrScanScreen> createState() => _ExtensionQrScanScreenState();
}

class _ExtensionQrScanScreenState extends State<ExtensionQrScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  bool _done = false;
  bool _wrongCode = false;

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final barcode in capture.barcodes) {
      final id = ExtensionPairingRequest.idFromQr(barcode.rawValue);
      if (id != null) {
        _done = true;
        Navigator.of(context).pop(id);
        return;
      }
    }
    if (!_wrongCode) setState(() => _wrongCode = true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét mã QR liên kết')),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    error.errorCode == MobileScannerErrorCode.permissionDenied
                        ? 'App cần quyền camera để quét mã. Hãy cho phép trong Cài đặt của điện thoại.'
                        : 'Không mở được camera. Hãy thử lại.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              _wrongCode
                  ? 'Đây không phải mã liên kết Why I Buy?. Hãy quét mã QR trong extension.'
                  : 'Trên máy tính: mở extension Why I Buy? → Liên kết thiết bị → Tạo mã QR, rồi hướng camera vào mã.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
