import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../app/routes.dart';
import '../core/formatters/money_format.dart';
import '../models/item_recognition.dart';
import '../models/price_offer.dart';
import '../models/ui_state.dart';
import '../services/analytics_events.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/photo_search_viewmodel.dart';
import '../viewmodels/wishlist_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/states/empty_view.dart';
import '../widgets/states/error_view.dart';
import '../widgets/why_i_buy_logo.dart';

/// "Chụp để tìm": the user photographs something they like but cannot name; AI names
/// it, then the app offers shop searches and — first — adding it to the wishlist so it
/// goes through the cooling-off period like any other item.
/// Layout follows Figma 20 / 20a ("Lấy giá từ ảnh chụp"): step label, left-aligned
/// heading, dashed photo frame, product card, actions pinned to the bottom.
class PhotoSearchScreen extends StatefulWidget {
  const PhotoSearchScreen({super.key});

  @override
  State<PhotoSearchScreen> createState() => _PhotoSearchScreenState();
}

class _PhotoSearchScreenState extends State<PhotoSearchScreen> {
  final _picker = ImagePicker();

  /// Photos are scaled down before upload: enough detail for the model, fewer tokens
  static const double _maxSide = 1024;

  bool _cameraAvailable = false;

  /// Kept so dispose can clear it without looking up an unmounted context
  late PhotoSearchViewModel _vm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PhotoSearchViewModel>().reset();
      _recoverLostPhoto();
    });
    try {
      _cameraAvailable = _picker.supportsImageSource(ImageSource.camera);
    } catch (_) {
      _cameraAvailable = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _vm = context.read<PhotoSearchViewModel>();
  }

  @override
  void dispose() {
    // The ViewModel lives app-wide: drop the photo and any late AI reply on leaving
    _vm.discard();
    super.dispose();
  }

  /// Android may kill the app while the camera is open on low-memory phones; the photo
  /// taken then comes back here instead of from pickImage.
  Future<void> _recoverLostPhoto() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final response = await _picker.retrieveLostData();
      final file = response.file;
      if (response.isEmpty || file == null || !mounted) return;
      await _identifyFile(file);
    } catch (e) {
      debugPrint('PhotoSearch lost data failed: $e');
    }
  }

  ImageSource get _mainSource =>
      _cameraAvailable ? ImageSource.camera : ImageSource.gallery;

  Future<void> _pick(ImageSource source) async {
    final XFile? file;
    try {
      file = await _picker.pickImage(
        source: source,
        maxWidth: _maxSide,
        maxHeight: _maxSide,
        imageQuality: 80,
      );
    } catch (e) {
      debugPrint('PhotoSearch pick failed: $e');
      _snack(
        source == ImageSource.camera
            ? 'Chưa mở được camera. Kiểm tra quyền camera của app rồi thử lại.'
            : 'Chưa mở được thư viện ảnh. Vui lòng thử lại.',
      );
      return;
    }
    if (file == null || !mounted) return; // cancelled
    await _identifyFile(file);
  }

  Future<void> _identifyFile(XFile file) async {
    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (e) {
      debugPrint('PhotoSearch read failed: $e');
      _snack('Chưa đọc được ảnh. Vui lòng chọn ảnh khác.');
      return;
    }
    if (!mounted) return;
    await _vm.identify(bytes, mimeType: _mimeOf(file));
  }

  static String _mimeOf(XFile file) {
    final type = file.mimeType;
    if (type != null && type.startsWith('image/')) return type;
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  Future<void> _openLink(Uri url) async {
    var ok = false;
    try {
      ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('PhotoSearch launch failed: $e');
    }
    if (!ok) _snack('Chưa mở được trang tìm kiếm.');
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  void _addToWishlist(String name) {
    // The AI's name prefills the form; the user can still edit it there
    context.read<PhotoSearchViewModel>().aiResultAccepted(
      AiFeatures.photoSearch,
    );
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.wishlistAdd,
      arguments: AddItemArgs(initialTitle: name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PhotoSearchViewModel>();
    final state = vm.state;
    final hasPhoto = state is! UiInitial<ItemRecognition>;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leadingWidth: 42,
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
            const SizedBox(width: 4),
            Text(
              'Chụp để tìm',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          if (hasPhoto && state is! UiLoading<ItemRecognition>)
            TextButton(
              key: const ValueKey('photo-search-retake'),
              onPressed: vm.reset,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text('Chọn ảnh khác'),
            ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.space16,
            AppDimens.space8,
            AppDimens.space16,
            AppDimens.space24,
          ),
          child: switch (state) {
            UiInitial() => _buildPicker(),
            UiLoading() => _buildLoading(vm),
            UiSuccess(:final data) => _buildResult(vm, data),
            UiEmpty(:final message) => _buildProblem(
              vm,
              EmptyView(
                title: message,
                subtitle: 'Thử chụp gần hơn, đủ sáng và chỉ để một món đồ trong khung hình.',
                icon: Icons.image_search_outlined,
              ),
            ),
            UiError(:final message, :final onRetry) => _buildProblem(
              vm,
              ErrorView(message: message, onRetry: onRetry),
            ),
          },
        ),
      ),
      bottomNavigationBar: switch (state) {
        UiInitial() => _bottomBar([
          AppButton(
            key: const ValueKey('photo-search-camera'),
            title: _cameraAvailable ? 'Chụp ảnh' : 'Chọn ảnh',
            icon: _cameraAvailable
                ? Icons.photo_camera_outlined
                : Icons.photo_library_outlined,
            onPressed: () => _pick(_mainSource),
          ),
          if (_cameraAvailable)
            _LinkButton(
              key: const ValueKey('photo-search-gallery'),
              label: 'Chọn từ thư viện',
              onPressed: () => _pick(ImageSource.gallery),
            ),
          const _PrivacyNote(),
        ]),
        UiSuccess(:final data) => _bottomBar([
          AppButton(
            key: const ValueKey('photo-search-add'),
            title: 'Thêm vào danh sách cân nhắc',
            onPressed: () => _addToWishlist(vm.selectedName ?? data.name),
          ),
        ]),
        UiEmpty() || UiError() => _bottomBar([
          AppButton(
            title: 'Chọn ảnh khác',
            variant: AppButtonVariant.secondary,
            onPressed: vm.reset,
          ),
        ]),
        UiLoading() => null,
      },
    );
  }

  // ==================== BƯỚC 1: CHỌN ẢNH (Figma 20) ====================
  Widget _buildPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepHeader(
          step: 'Bước 1/2',
          title: 'Chọn ảnh món đồ bạn thích',
          subtitle:
              'Chụp rõ một món đồ. AI đoán tên để bạn tìm, rồi bạn có thể '
              'thêm vào danh sách cân nhắc trước khi quyết định mua.',
        ),
        const SizedBox(height: AppDimens.space16),
        _DashedFrame(
          onTap: () => _pick(_mainSource),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_a_photo_outlined,
                size: 36,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppDimens.space12),
              Text(
                'Chưa chọn ảnh',
                style: AppTextStyles.bodyLarge
                    .themed(context)
                    .copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppDimens.space4),
              Text(
                'Đủ sáng · một món · chụp gần',
                style: AppTextStyles.caption
                    .themed(context)
                    .copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== ĐANG NHẬN DIỆN ====================
  Widget _buildLoading(PhotoSearchViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepHeader(
          step: 'Bước 2/2',
          title: 'Đang nhận diện…',
          subtitle: 'Thường mất vài giây.',
        ),
        const SizedBox(height: AppDimens.space16),
        _ProductCard(
          image: vm.imageBytes,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI đang xem ảnh',
                style: AppTextStyles.titleMedium.themed(context),
              ),
              const SizedBox(height: AppDimens.space12),
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(4)),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  color: AppColors.primary,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== KHÔNG NHẬN RA / LỖI ====================
  Widget _buildProblem(PhotoSearchViewModel vm, Widget view) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepHeader(step: 'Bước 2/2', title: 'Kiểm tra kết quả'),
        const SizedBox(height: AppDimens.space16),
        if (vm.imageBytes != null)
          Center(child: _Thumb(bytes: vm.imageBytes!, size: 120)),
        view,
      ],
    );
  }

  // ==================== BƯỚC 2: KẾT QUẢ (Figma 20a) ====================
  Widget _buildResult(PhotoSearchViewModel vm, ItemRecognition data) {
    final selected = vm.selectedName ?? data.name;
    final names = [data.name, ...data.alternatives];
    final meta = [?data.category, ?data.brand].join(' · ');
    final coolingOffDays = context.watch<WishlistViewModel>().coolingOffDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepHeader(
          step: 'Bước 2/2',
          title: 'Kiểm tra món AI nhận ra',
          subtitle: 'Chọn lại tên nếu AI đoán chưa đúng.',
        ),
        const SizedBox(height: AppDimens.space16),
        _ProductCard(
          image: vm.imageBytes,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selected,
                key: const ValueKey('photo-search-name'),
                style: AppTextStyles.titleMedium.themed(context),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppDimens.space6),
              _ConfidencePill(data.confidence),
              if (meta.isNotEmpty) ...[
                const SizedBox(height: AppDimens.space6),
                Text(
                  meta,
                  style: AppTextStyles.caption
                      .themed(context)
                      .copyWith(
                        color: AppSemanticColors.of(context).textSecondary,
                      ),
                ),
              ],
            ],
          ),
        ),
        if (data.hasPriceRange) ...[
          const SizedBox(height: AppDimens.space12),
          _PriceRange(min: data.priceMinVnd!, max: data.priceMaxVnd!),
        ],
        if (names.length > 1) ...[
          const SizedBox(height: AppDimens.space20),
          Text(
            'Tên khác · chạm để chọn lại',
            style: AppTextStyles.labelLarge
                .themed(context)
                .copyWith(color: AppSemanticColors.of(context).textSecondary),
          ),
          const SizedBox(height: AppDimens.space8),
          Wrap(
            spacing: AppDimens.space8,
            runSpacing: AppDimens.space8,
            children: [
              for (final n in names)
                _NameOption(
                  label: n,
                  selected: n == selected,
                  onTap: () => vm.selectName(n),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppDimens.space24),
        _WhereToBuy(query: vm.searchQuery ?? data.name, onOpen: _openLink),
        if (vm.canSearchPrices) ...[
          const SizedBox(height: AppDimens.space12),
          _AiPriceSearch(
            state: vm.priceState,
            query: vm.searchQuery ?? data.name,
            onSearch: vm.searchPrices,
            onOpen: _openLink,
          ),
        ],
        const SizedBox(height: AppDimens.space20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.hourglass_empty_rounded,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppDimens.space8),
            Expanded(
              child: Text(
                'Thêm vào danh sách cân nhắc để món này qua $coolingOffDays '
                'ngày chờ rồi hẵng quyết định mua.',
                style: AppTextStyles.caption
                    .themed(context)
                    .copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _bottomBar(List<Widget> children) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppDimens.space16,
        AppDimens.space12,
        AppDimens.space16,
        AppDimens.space8,
      ),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

// ==================== WIDGETS ====================

class _StepHeader extends StatelessWidget {
  final String step;
  final String title;
  final String? subtitle;

  const _StepHeader({required this.step, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          step,
          style: AppTextStyles.labelMedium
              .themed(context)
              .copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppDimens.space4),
        Text(
          title,
          style: AppTextStyles.titleLarge
              .themed(context)
              .copyWith(color: theme.colorScheme.onSurface),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppDimens.space6),
          Text(
            subtitle!,
            style: AppTextStyles.bodyMedium
                .themed(context)
                .copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

/// Large tappable frame with a dashed border (Figma 20 "Chưa chọn ảnh")
class _DashedFrame extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _DashedFrame({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Chọn ảnh món đồ',
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: AppDimens.borderLarge,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppDimens.borderLarge,
          child: CustomPaint(
            painter: _DashedBorderPainter(color: theme.colorScheme.outline),
            child: SizedBox(
              height: 300,
              width: double.infinity,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;

  const _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AppDimens.radiusLarge),
        ),
      );
    const dash = 6.0, gap = 5.0;
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Photo on the left, details on the right (Figma 20a product card)
class _ProductCard extends StatelessWidget {
  final Uint8List? image;
  final Widget child;

  const _ProductCard({required this.image, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppDimens.space12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppDimens.borderLarge,
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (image != null) _Thumb(bytes: image!, size: 104),
          const SizedBox(width: AppDimens.space12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final Uint8List bytes;
  final double size;

  const _Thumb({required this.bytes, required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppDimens.borderMedium,
      child: Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      ),
    );
  }
}

class _ConfidencePill extends StatelessWidget {
  final RecognitionConfidence confidence;

  const _ConfidencePill(this.confidence);

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (confidence) {
      RecognitionConfidence.high => (
        AppSemanticColors.of(context).successContainer,
        AppSemanticColors.of(context).onSuccessContainer,
      ),
      RecognitionConfidence.medium => (
        AppSemanticColors.of(context).aiContainer,
        AppSemanticColors.of(context).onAiContainer,
      ),
      RecognitionConfidence.low => (
        AppSemanticColors.of(context).mutedSurface,
        AppSemanticColors.of(context).textSecondary,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space8,
        vertical: AppDimens.space2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 12, color: fg),
          const SizedBox(width: AppDimens.space4),
          Text(
            'AI · ${confidence.label}',
            style: AppTextStyles.labelMedium
                .themed(context)
                .copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}

/// Price range on the brand yellow, like "Giá nhận được" in Figma 20a
class _PriceRange extends StatelessWidget {
  final int min;
  final int max;

  const _PriceRange({required this.min, required this.max});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.space12),
      decoration: BoxDecoration(
        color: AppSemanticColors.of(context).primaryContainer,
        borderRadius: AppDimens.borderMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Giá tham khảo',
            style: AppTextStyles.labelMedium
                .themed(context)
                .copyWith(color: AppSemanticColors.of(context).textSecondary),
          ),
          const SizedBox(height: AppDimens.space2),
          Text(
            '${formatVnd(min)} – ${formatVnd(max)}',
            style: AppTextStyles.titleLarge
                .themed(context)
                .copyWith(color: AppColors.onPrimary),
          ),
          const SizedBox(height: AppDimens.space2),
          Text(
            'AI ước lượng, giá thật ở mỗi shop có thể khác.',
            style: AppTextStyles.caption
                .themed(context)
                .copyWith(color: AppSemanticColors.of(context).textSecondary),
          ),
        ],
      ),
    );
  }
}

class _NameOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NameOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? AppSemanticColors.of(context).primaryContainer
            : AppSemanticColors.of(context).cardSurface,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected
                ? AppColors.primary
                : AppSemanticColors.of(context).cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: ConstrainedBox(
            // Touch target ≥ 48dp tall without looking bulky
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space12,
                vertical: AppDimens.space8,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected) ...[
                    const Icon(
                      Icons.check,
                      size: 16,
                      color: AppColors.onPrimary,
                    ),
                    const SizedBox(width: AppDimens.space4),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: AppTextStyles.bodyMedium
                          .themed(context)
                          .copyWith(
                            color: selected
                                ? AppColors.onPrimary
                                : AppSemanticColors.of(context).textBody,
                            fontWeight: selected ? FontWeight.w600 : null,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Free price comparison: each shop's own search, already sorted cheapest first
class _WhereToBuy extends StatelessWidget {
  final String query;
  final void Function(Uri url) onOpen;

  const _WhereToBuy({required this.query, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Xem giá thấp nhất ở từng nơi',
          style: AppTextStyles.labelLarge
              .themed(context)
              .copyWith(color: AppSemanticColors.of(context).textSecondary),
        ),
        const SizedBox(height: AppDimens.space2),
        Text(
          'Mỗi trang đã sắp xếp giá từ thấp đến cao cho "$query".',
          style: AppTextStyles.caption
              .themed(context)
              .copyWith(color: AppSemanticColors.of(context).hint),
        ),
        const SizedBox(height: AppDimens.space8),
        _ListCard(
          children: [
            for (final site in ShopSite.values)
              _ListRow(
                key: ValueKey('photo-search-shop-${site.name}'),
                leading: Icon(
                  Icons.storefront_outlined,
                  size: 20,
                  color: AppSemanticColors.of(context).accent,
                ),
                title: site.label,
                trailingText: 'Giá thấp → cao',
                onTap: () => onOpen(site.cheapestFirstUrl(query)),
              ),
          ],
        ),
      ],
    );
  }
}

/// "AI tìm giá ở các shop" (Google Search grounding). Shown only when the flag is on.
class _AiPriceSearch extends StatelessWidget {
  final UiState<PriceSearchResult> state;
  final String query;
  final VoidCallback onSearch;
  final void Function(Uri url) onOpen;

  const _AiPriceSearch({
    required this.state,
    required this.query,
    required this.onSearch,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      UiInitial() => AppButton(
        key: const ValueKey('photo-search-ai-prices'),
        title: 'AI tìm giá ở các shop',
        icon: Icons.auto_awesome,
        variant: AppButtonVariant.secondary,
        onPressed: onSearch,
      ),
      UiLoading() => _ListCard(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimens.space16),
            child: Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: AppDimens.space12),
                Expanded(
                  child: Text(
                    'AI đang tìm giá trên Google…',
                    style: AppTextStyles.bodyMedium.themed(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      UiSuccess(:final data) => _buildOffers(context, data),
      UiEmpty(:final message) => _Notice(message: message),
      UiError(:final message, :final onRetry) => _Notice(
        message: message,
        actionLabel: onRetry == null ? null : 'Thử lại',
        onAction: onRetry,
      ),
    };
  }

  Widget _buildOffers(BuildContext context, PriceSearchResult data) {
    final cheapest = data.cheapest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nơi bán AI tìm được',
          style: AppTextStyles.labelLarge
              .themed(context)
              .copyWith(color: AppSemanticColors.of(context).textSecondary),
        ),
        const SizedBox(height: AppDimens.space8),
        _ListCard(
          children: [
            for (final offer in data.offers)
              _ListRow(
                leading: offer == cheapest
                    ? const _Badge(label: 'Rẻ nhất')
                    : const SizedBox(width: 20),
                title: offer.shop,
                trailingText: formatVnd(offer.priceVnd),
                trailingBold: true,
                onTap: () => onOpen(
                  offer.url ??
                      ShopSite.googleShopping.cheapestFirstUrl(
                        '${offer.shop} $query',
                      ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppDimens.space6),
        Text(
          'AI đọc giá từ kết quả Google, giá thật có thể đã thay đổi. '
          'Kiểm tra lại trên trang của shop trước khi mua.',
          style: AppTextStyles.caption
              .themed(context)
              .copyWith(color: AppSemanticColors.of(context).hint),
        ),
        if (data.sources.isNotEmpty) ...[
          const SizedBox(height: AppDimens.space8),
          Wrap(
            spacing: AppDimens.space4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Nguồn:',
                style: AppTextStyles.caption
                    .themed(context)
                    .copyWith(
                      color: AppSemanticColors.of(context).textSecondary,
                    ),
              ),
              for (final s in data.sources.take(4))
                InkWell(
                  onTap: () => onOpen(s.uri),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimens.space4,
                    ),
                    child: Text(
                      s.title,
                      style: AppTextStyles.caption
                          .themed(context)
                          .copyWith(
                            color: AppSemanticColors.of(context).accent,
                            decoration: TextDecoration.underline,
                          ),
                    ),
                  ),
                ),
            ],
          ),
        ],
        if (data.searchEntryPointHtml case final html?) ...[
          const SizedBox(height: AppDimens.space8),
          _SearchSuggestions(html: html, onOpen: onOpen),
        ],
      ],
    );
  }
}

/// Google's "Search suggestions" for a grounded answer. The Gemini terms require
/// showing this HTML as provided; links inside open in the browser.
class _SearchSuggestions extends StatefulWidget {
  final String html;
  final void Function(Uri url) onOpen;

  const _SearchSuggestions({required this.html, required this.onOpen});

  @override
  State<_SearchSuggestions> createState() => _SearchSuggestionsState();
}

class _SearchSuggestionsState extends State<_SearchSuggestions> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri != null && uri.scheme.startsWith('http')) {
              widget.onOpen(uri);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(
        '<html><head><meta name="viewport" '
        'content="width=device-width, initial-scale=1"></head>'
        '<body style="margin:0">${widget.html}</body></html>',
      );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppDimens.borderMedium,
      child: SizedBox(
        height: 88,
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  final List<Widget> children;

  const _ListCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppDimens.borderLarge,
        border: Border.all(color: theme.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: AppDimens.space16,
                color: theme.dividerColor,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String trailingText;
  final bool trailingBold;
  final VoidCallback onTap;

  const _ListRow({
    super.key,
    required this.leading,
    required this.title,
    required this.trailingText,
    required this.onTap,
    this.trailingBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.space16,
              vertical: AppDimens.space8,
            ),
            child: Row(
              children: [
                leading,
                const SizedBox(width: AppDimens.space12),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.bodyLarge
                        .themed(context)
                        .copyWith(color: theme.colorScheme.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppDimens.space8),
                Text(
                  trailingText,
                  style: trailingBold
                      ? AppTextStyles.titleMedium.themed(context)
                      : AppTextStyles.caption
                            .themed(context)
                            .copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                ),
                const SizedBox(width: AppDimens.space4),
                Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;

  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space6,
        vertical: AppDimens.space2,
      ),
      decoration: BoxDecoration(
        color: AppSemanticColors.of(context).photoStatusContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium
            .themed(context)
            .copyWith(color: AppSemanticColors.of(context).brandText),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _Notice({required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.space12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppDimens.borderMedium,
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppDimens.space8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium
                  .themed(context)
                  .copyWith(color: theme.colorScheme.onSurface),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _LinkButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: theme.colorScheme.primary,
        minimumSize: const Size.fromHeight(48),
        textStyle: AppTextStyles.labelLarge.themed(context),
      ),
      child: Text(label),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppDimens.space4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppDimens.space4),
          Flexible(
            child: Text(
              'Ảnh chỉ dùng để nhận diện, không được lưu lại',
              style: AppTextStyles.caption
                  .themed(context)
                  .copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
