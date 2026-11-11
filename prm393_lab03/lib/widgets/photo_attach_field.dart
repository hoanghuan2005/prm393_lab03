import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/cloudinary_service.dart';
import '../theme/app_dimens.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_text_styles.dart';
import 'product_image.dart';

/// Optional photo (receipt / product) uploaded to Cloudinary; reports the link via [onChanged]
/// and the upload state via [onUploadingChanged] so the form can wait before saving.
class PhotoAttachField extends StatefulWidget {
  final String? imageUrl;
  final ValueChanged<String?> onChanged;
  final ValueChanged<bool>? onUploadingChanged;
  final bool enabled;
  final String label;

  const PhotoAttachField({
    super.key,
    required this.imageUrl,
    required this.onChanged,
    this.onUploadingChanged,
    this.enabled = true,
    this.label = 'Ảnh (không bắt buộc)',
  });

  @override
  State<PhotoAttachField> createState() => _PhotoAttachFieldState();
}

class _PhotoAttachFieldState extends State<PhotoAttachField> {
  static const double _thumbSize = 72;
  // The theme stretches outlined buttons to full width; keep these side by side
  static final _compact = OutlinedButton.styleFrom(
    minimumSize: const Size(0, AppDimens.minTouchTarget),
  );
  bool _uploading = false;

  void _setUploading(bool value) {
    setState(() => _uploading = value);
    widget.onUploadingChanged?.call(value);
  }

  Future<void> _pick(ImageSource source) async {
    if (_uploading) return;
    final messenger = ScaffoldMessenger.of(context);
    if (!CloudinaryService.isConfigured) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Chưa cấu hình Cloudinary.')),
      );
      return;
    }
    final XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('Pick photo failed: $e');
      return;
    }
    if (file == null || !mounted) return;
    _setUploading(true);
    try {
      final url = await CloudinaryService().uploadBytes(
        await file.readAsBytes(),
        filename: file.name,
      );
      if (mounted) widget.onChanged(url);
    } catch (e) {
      debugPrint('Cloudinary upload failed: $e');
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Chưa tải ảnh lên được. Vui lòng thử lại.'),
        ),
      );
    } finally {
      if (mounted) _setUploading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppSemanticColors.of(context);
    final hasImage = ProductImage.canShow(widget.imageUrl);
    final canAct = widget.enabled && !_uploading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTextStyles.labelLarge.themed(context)),
        const SizedBox(height: AppDimens.space8),
        Row(
          children: [
            Container(
              width: _thumbSize,
              height: _thumbSize,
              decoration: BoxDecoration(
                color: colors.mutedSurface,
                borderRadius: AppDimens.borderMedium,
                border: Border.all(
                  color: colors.cardBorder.withValues(alpha: 0.6),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: _uploading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : hasImage
                  ? ProductImage(url: widget.imageUrl, size: _thumbSize)
                  : Icon(
                      Icons.receipt_long_outlined,
                      color: colors.textSecondary,
                    ),
            ),
            const SizedBox(width: AppDimens.space12),
            Expanded(
              child: Wrap(
                spacing: AppDimens.space8,
                runSpacing: AppDimens.space8,
                children: [
                  OutlinedButton.icon(
                    key: const ValueKey('photo-attach-camera'),
                    style: _compact,
                    onPressed: canAct ? () => _pick(ImageSource.camera) : null,
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: const Text('Chụp'),
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey('photo-attach-gallery'),
                    style: _compact,
                    onPressed: canAct ? () => _pick(ImageSource.gallery) : null,
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: Text(hasImage ? 'Đổi ảnh' : 'Chọn ảnh'),
                  ),
                  if (hasImage)
                    TextButton.icon(
                      onPressed: canAct ? () => widget.onChanged(null) : null,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Bỏ ảnh'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
