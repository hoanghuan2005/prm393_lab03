import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../models/buying_motive.dart';
import '../models/ui_state.dart';
import '../models/wishlist_status.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/wishlist_viewmodel.dart';
import '../widgets/app_text_field.dart';
import '../widgets/motive_chip.dart';
import '../widgets/states/empty_view.dart';
import '../widgets/states/error_view.dart';
import '../widgets/states/loading_view.dart';
import '../widgets/wishlist_card.dart';

/// Screen 01: Smart Wishlist with Search & Motive Filters
class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wishlistVm = context.watch<WishlistViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Wishlist'),
        actions: [
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
            height: 48,
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
                final isSelected = wishlistVm.selectedMotiveFilter == motive;
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
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
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
                  onTap: () =>
                      wishlistVm.setReviewDueFilter(!wishlistVm.reviewDueOnly),
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

          // Items Content
          Expanded(child: _buildBodyContent(context, wishlistVm)),
        ],
      ),
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
      selectedColor: AppColors.primaryContainer,
      checkmarkColor: AppColors.onPrimary,
      labelStyle: AppTextStyles.labelMedium.copyWith(
        color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
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
      case UiEmpty(message: final msg):
        return EmptyView(
          title: msg,
          subtitle: 'Thử tìm kiếm với từ khóa khác hoặc xóa bộ lọc động cơ.',
          actionTitle: vm.searchQuery.isNotEmpty ? 'Xóa tìm kiếm' : null,
          onAction: vm.searchQuery.isNotEmpty
              ? () {
                  _searchController.clear();
                  vm.setSearchQuery('');
                }
              : null,
        );
      case UiError(message: final msg, onRetry: final retry):
        return ErrorView(message: msg, onRetry: retry);
      case UiSuccess(data: final items):
        return ListView.builder(
          padding: const EdgeInsets.all(AppDimens.space16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
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
