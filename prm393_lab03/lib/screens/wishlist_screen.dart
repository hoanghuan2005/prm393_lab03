import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../models/buying_motive.dart';
import '../models/ui_state.dart';
import '../models/wishlist_status.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/decision_support_viewmodel.dart';
import '../viewmodels/wishlist_viewmodel.dart';
import '../widgets/app_text_field.dart';
import '../widgets/buy_intent_section.dart';
import '../widgets/motive_chip.dart';
import '../widgets/states/empty_view.dart';
import '../widgets/states/error_view.dart';
import '../widgets/states/loading_view.dart';
import '../widgets/why_i_buy_logo.dart';
import '../widgets/wishlist_card.dart';

/// Screen 01: Smart Wishlist with Search & Motive Filters
class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  bool _showSaleNotice = true;
  Timer? _saleNoticeTimer;

  // The query lives in the view model and survives tab switches; show it again
  late final TextEditingController _searchController = TextEditingController(
    text: context.read<WishlistViewModel>().searchQuery,
  );

  /// Kept for [dispose], where the context can no longer be read
  late final WishlistViewModel _wishlistVm;

  @override
  void initState() {
    super.initState();
    _wishlistVm = context.read<WishlistViewModel>();
    _startSaleNoticeTimer();
  }

  void _startSaleNoticeTimer() {
    _saleNoticeTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _showSaleNotice) {
        setState(() => _showSaleNotice = false);
      }
    });
  }

  void _dismissSaleNotice() {
    _saleNoticeTimer?.cancel();
    if (_showSaleNotice) {
      setState(() => _showSaleNotice = false);
    }
  }

  @override
  void dispose() {
    _saleNoticeTimer?.cancel();
    _searchController.dispose();
    // Filters are for this visit only; otherwise the list looks empty next time.
    // After this frame: listeners may not rebuild while the tree is being torn down.
    final vm = _wishlistVm;
    if (vm.hasActiveFilter) Future.microtask(vm.clearFilters);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wishlistVm = context.watch<WishlistViewModel>();
    // The view model cleared the query (e.g. after saving an item): empty the box too
    if (wishlistVm.searchQuery.isEmpty && _searchController.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && wishlistVm.searchQuery.isEmpty) {
          _searchController.clear();
        }
      });
    }
    final decisionVm = context.watch<DecisionSupportViewModel>();
    final nextSale = decisionVm.upcomingSales.firstOrNull;
    final hasSale = nextSale != null;

    final theme = Theme.of(context);

    final topPadding = MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
        Scaffold(
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
                Flexible(
                  child: Text(
                    'Danh sách mong muốn',
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleLarge.withInheritedColor.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.event_outlined),
                    if (hasSale)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                tooltip: 'Lịch sale',
                onPressed: () {
                  _dismissSaleNotice();
                  Navigator.pushNamed(context, AppRoutes.sales);
                },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Thêm món',
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.wishlistAdd);
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.space16,
                  vertical: AppDimens.space8,
                ),
                child: AppTextField(
                  controller: _searchController,
                  hint: 'Tìm kiếm sản phẩm hoặc động cơ...',
                  prefixIcon: Icons.search,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          tooltip: 'Xoá tìm kiếm',
                          onPressed: () {
                            _searchController.clear();
                            wishlistVm.setSearchQuery('');
                          },
                        )
                      : null,
                  onChanged: (val) {
                    wishlistVm.setSearchQuery(val);
                  },
                ),
              ),

              // Horizontal 8 Motive Filters
              SizedBox(
                height: AppDimens.space48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.space16,
                  ),
                  itemCount: BuyingMotive.values.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppDimens.space8),
                  itemBuilder: (context, index) {
                    final motive = BuyingMotive.values[index];
                    final isSelected =
                        wishlistVm.selectedMotiveFilter == motive;
                    return MotiveChip(
                      motive: motive,
                      isSelected: isSelected,
                      isCompact: true,
                      onSelected: (m) => wishlistVm.setMotiveFilter(m),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppDimens.space8),

              // Status Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.space16,
                ),
                child: Row(
                  children: [
                    _buildStatusFilterChip(
                      context,
                      label: 'Tất cả',
                      isSelected:
                          wishlistVm.selectedStatusFilter == null &&
                          !wishlistVm.reviewDueOnly,
                      onTap: () {
                        wishlistVm.setReviewDueFilter(false);
                        wishlistVm.setStatusFilter(null);
                      },
                    ),
                    const SizedBox(width: AppDimens.space8),
                    // "Cần xem lại": also the fallback when reminders are off or unsupported
                    _buildStatusFilterChip(
                      context,
                      label: 'Cần xem lại (${wishlistVm.reviewDueCount})',
                      isSelected: wishlistVm.reviewDueOnly,
                      onTap: () => wishlistVm.setReviewDueFilter(
                        !wishlistVm.reviewDueOnly,
                      ),
                    ),
                    const SizedBox(width: AppDimens.space8),
                    ...WishlistStatus.values.map((status) {
                      return Padding(
                        padding: const EdgeInsets.only(right: AppDimens.space8),
                        child: _buildStatusFilterChip(
                          context,
                          label: status.label,
                          isSelected: wishlistVm.selectedStatusFilter == status,
                          onTap: () => wishlistVm.setStatusFilter(status),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.space8),
              const Divider(),

              // Marked "Mua" in the Chrome extension, waiting for the purchase form
              const BuyIntentSection(),

              // Items Content
              Expanded(child: _buildBodyContent(context, wishlistVm)),
            ],
          ),
        ),
        if (hasSale)
          Positioned(
            top: topPadding + kToolbarHeight - 10,
            right: 12,
            child: IgnorePointer(
              ignoring: !_showSaleNotice,
              child: AnimatedOpacity(
                opacity: _showSaleNotice ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _SaleTooltipPopup(
                  saleName: nextSale.name,
                  daysUntil: nextSale.daysUntil(decisionVm.now),
                  onTap: () {
                    _dismissSaleNotice();
                    Navigator.pushNamed(context, AppRoutes.sales);
                  },
                  onClose: _dismissSaleNotice,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppSemanticColors.of(context).primaryContainer,
      checkmarkColor: AppColors.onPrimary,
      labelStyle: AppTextStyles.labelMedium
          .themed(context)
          .copyWith(
            // Selected chips sit on the light primaryContainer in both themes
            color: isSelected
                ? AppColors.onPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
      shape: const RoundedRectangleBorder(borderRadius: AppDimens.borderPill),
    );
  }

  Widget _buildBodyContent(BuildContext context, WishlistViewModel vm) {
    switch (vm.state) {
      case UiInitial():
      case UiLoading():
        return const LoadingView(message: 'Đang lọc danh sách...');
      case UiEmpty(message: final msg, actionTitle: final addTitle):
        if (vm.allItems.isEmpty) {
          return EmptyView(
            title: msg,
            subtitle:
                'Lưu món bạn đang muốn mua để cân nhắc trước khi quyết định.',
            actionTitle: addTitle,
            onAction: () => Navigator.pushNamed(context, AppRoutes.wishlistAdd),
          );
        }
        // The active chip may be scrolled out of sight: one button clears everything
        return EmptyView(
          title: msg,
          subtitle: vm.searchQuery.trim().isNotEmpty
              ? 'Thử từ khoá khác, hoặc xoá tìm kiếm và bộ lọc để xem mọi món.'
              : 'Xoá bộ lọc để xem mọi món trong danh sách.',
          actionTitle: vm.hasActiveFilter ? 'Xoá bộ lọc' : null,
          onAction: vm.hasActiveFilter
              ? () {
                  _searchController.clear();
                  vm.clearFilters();
                }
              : null,
        );
      case UiError(message: final msg, onRetry: final retry):
        return ErrorView(message: msg, onRetry: retry);
      case UiSuccess(data: final items):
        // Remote Config max_wishlist_items_shown: the rest stays one tap away
        final visible = vm.visibleOf(items);
        final hidden = items.length - visible.length;
        return ListView.builder(
          // A new filter starts at the top instead of keeping the old scroll offset
          key: ValueKey(
            '${vm.searchQuery}|${vm.selectedMotiveFilter}|'
            '${vm.selectedStatusFilter}|${vm.reviewDueOnly}',
          ),
          // Room for the system navigation bar under the last card (edge-to-edge)
          padding: EdgeInsets.fromLTRB(
            AppDimens.space16,
            AppDimens.space16,
            AppDimens.space16,
            AppDimens.space16 + MediaQuery.paddingOf(context).bottom,
          ),
          itemCount: visible.length + (hidden > 0 ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == visible.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppDimens.space8),
                child: Column(
                  children: [
                    Text(
                      'Đang hiện ${visible.length}/${items.length} món.',
                      style: AppTextStyles.labelMedium.themed(context),
                    ),
                    TextButton(
                      key: const ValueKey('wishlist-show-all'),
                      onPressed: vm.showAllItems,
                      child: Text('Xem thêm $hidden món'),
                    ),
                  ],
                ),
              );
            }
            final item = visible[index];
            return WishlistCard(
              item: item,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.itemDetail,
                  arguments: ItemDetailArgs(item),
                );
              },
            );
          },
        );
    }
  }
}

class _SaleTooltipPopup extends StatelessWidget {
  final String saleName;
  final int daysUntil;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _SaleTooltipPopup({
    required this.saleName,
    required this.daysUntil,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = daysUntil == 0
        ? 'Hôm nay'
        : (daysUntil == 1 ? 'Ngày mai' : 'còn $daysUntil ngày');

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      tween: Tween(begin: 0.8, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          alignment: const Alignment(0.62, -1.0),
          child: Opacity(
            opacity: ((scale - 0.8) / 0.2).clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Arrow pointing up to calendar icon
          Padding(
            padding: const EdgeInsets.only(right: 52),
            child: CustomPaint(
              size: const Size(16, 10),
              painter: _TooltipArrowPainter(
                color: AppSemanticColors.of(context).comparisonSurface,
              ),
            ),
          ),
          Material(
            elevation: 8,
            shadowColor: AppSemanticColors.of(context).illustrationShadow,
            borderRadius: AppDimens.borderMedium,
            color: AppSemanticColors.of(context).comparisonSurface,
            child: InkWell(
              borderRadius: AppDimens.borderMedium,
              onTap: onTap,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 290),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.space12,
                  vertical: AppDimens.space8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimens.space4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: AppDimens.space8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Wrap(
                            spacing: AppDimens.space8,
                            runSpacing: AppDimens.space8,
                            children: [
                              Text(
                                'Lịch sale: $saleName',
                                style: AppTextStyles
                                    .bodyMedium
                                    .withInheritedColor
                                    .copyWith(
                                      color: AppColors.textOnDark,

                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(width: AppDimens.space4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimens.space6,
                                  vertical: AppDimens.space2,
                                ),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: AppDimens.borderSmall,
                                ),
                                child: Text(
                                  timeStr,
                                  style: AppTextStyles
                                      .caption
                                      .withInheritedColor
                                      .copyWith(
                                        color: AppColors.onPrimary,

                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimens.space2),
                          Text(
                            'Bấm để xem danh sách & kế hoạch mua',
                            style: AppTextStyles.caption.withInheritedColor
                                .copyWith(
                                  color: AppSemanticColors.of(context)
                                      .comparisonHint,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDimens.space6),
                    IconButton(
                      tooltip: 'Đóng gợi ý',
                      onPressed: onClose,
                      icon: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AppSemanticColors.of(context).comparisonHint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TooltipArrowPainter extends CustomPainter {
  final Color color;

  _TooltipArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TooltipArrowPainter oldDelegate) =>
      oldDelegate.color != color;
}
