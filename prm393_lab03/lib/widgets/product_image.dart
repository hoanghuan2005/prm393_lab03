import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/app_semantic_colors.dart';

/// Product photo saved by the Chrome extension (`WishlistItem.imageUrl`, a Shopee CDN link).
/// Shows nothing when there is no usable http(s) link, and a quiet placeholder while
/// loading or when the image cannot be fetched (offline, link expired).
class ProductImage extends StatelessWidget {
  final String? url;
  final double size;
  final BorderRadius borderRadius;

  const ProductImage({
    super.key,
    required this.url,
    this.size = 56,
    this.borderRadius = AppDimens.borderMedium,
  });

  /// Only web links are shown; anything else (empty, data:, file paths) is ignored
  static bool canShow(String? url) {
    final uri = url == null ? null : Uri.tryParse(url.trim());
    return uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (!canShow(url)) return const SizedBox.shrink();
    final cacheSize = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.network(
        url!.trim(),
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: cacheSize,
        excludeFromSemantics: true,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _placeholder(context),
        errorBuilder: (context, error, stack) =>
            _placeholder(context, icon: Icons.image_not_supported_outlined),
      ),
    );
  }

  Widget _placeholder(
    BuildContext context, {
    IconData icon = Icons.image_outlined,
  }) => Container(
    width: size,
    height: size,
    color: AppSemanticColors.of(context).mutedSurface,
    alignment: Alignment.center,
    child: Icon(
      icon,
      size: size * 0.4,
      color: AppSemanticColors.of(context).textSecondary,
    ),
  );
}
