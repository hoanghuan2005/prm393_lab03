import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/extension_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../widgets/why_i_buy_logo.dart';

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
  final ImagePicker _picker = ImagePicker();
  bool _done = false;
  bool _wrongCode = false;
  bool _picking = false;
  bool _noCodeInImage = false;

  /// A screenshot / photo of the extension's QR: for devices without a usable
  /// camera (emulator) or when the code is on the same phone
  Future<void> _pickImage() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null || !mounted) return;
      final capture = await _controller.analyzeImage(
        file.path,
        formats: const [BarcodeFormat.qrCode],
      );
      if (!mounted) return;
      if (capture == null || capture.barcodes.isEmpty) {
        setState(() => _noCodeInImage = true);
        return;
      }
      setState(() => _noCodeInImage = false);
      _onDetect(capture);
    } catch (_) {
      if (mounted) setState(() => _noCodeInImage = true);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leadingWidth: AppDimens.minTouchTarget,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.chevron_left_rounded, size: 30),
          tooltip: 'Quay lại',
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            const WhyIBuyLogo(size: 26, color: AppColors.onPrimary),
            const SizedBox(width: AppDimens.space4),
            Expanded(
              child: Text(
                'Quét mã QR liên kết',
                style: AppTextStyles.titleLarge.withInheritedColor.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.space24),
                  child: Text(
                    error.errorCode == MobileScannerErrorCode.permissionDenied
                        ? 'App cần quyền camera để quét mã. Bạn có thể cấp quyền trong Cài đặt của điện thoại.'
                        : 'Không mở được camera. Bạn có thể thử lại.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.themed(context),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.space20,
              AppDimens.space20,
              AppDimens.space20,
              AppDimens.space8,
            ),
            child: Text(
              _noCodeInImage
                  ? 'Không tìm thấy mã QR trong ảnh. Chọn ảnh chụp rõ mã QR của tiện ích trình duyệt.'
                  : _wrongCode
                  ? 'Đây không phải mã liên kết Why I Buy?. Mã liên kết nằm trong tiện ích trình duyệt.'
                  : 'Trên máy tính: mở extension Why I Buy? → Liên kết thiết bị → Tạo mã QR, rồi hướng camera vào mã.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.themed(context),
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(
              AppDimens.space20,
              0,
              AppDimens.space20,
              AppDimens.space20,
            ),
            child: OutlinedButton.icon(
              onPressed: _picking ? null : _pickImage,
              icon: _picking
                  ? const SizedBox(
                      width: AppDimens.space20,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.image_outlined),
              label: const Text('Chọn ảnh có mã QR'),
            ),
          ),
        ],
      ),
    );
  }
}
