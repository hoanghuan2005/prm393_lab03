import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/ui_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/wishlist_viewmodel.dart';
import '../widgets/states/empty_view.dart';
import '../widgets/states/error_view.dart';
import '../widgets/states/loading_view.dart';
import '../widgets/wishlist_card.dart';
import 'add_item_screen.dart';
import 'item_detail_screen.dart';

/// Screen 00: Trang chủ (Hub) from Figma "Why I Buy"
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final wishlistVm = context.watch<WishlistViewModel>();
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xin chào,',
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
            ),
            Text(
              authVm.displayName,
              style: AppTextStyles.titleMedium,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            tooltip: 'Thêm món mới',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddItemScreen()),
              );
            },
          ),
          const SizedBox(width: AppDimens.space8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Savings Card (Mindfulness impact)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimens.space20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppDimens.borderLarge,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tiết kiệm từ việc hoãn mua',
                        style: AppTextStyles.labelLarge.copyWith(color: AppColors.onPrimary),
                      ),
                      const Icon(Icons.savings_outlined, color: AppColors.onPrimary),
                    ],
                  ),
                  const SizedBox(height: AppDimens.space8),
                  Text(
                    currencyFormatter.format(wishlistVm.totalSavedAmount),
                    style: AppTextStyles.displayMedium.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppDimens.space8),
                  Text(
                    '${wishlistVm.cooldownCount} món đang được làm nguội tâm lý',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space24),

            // Periodic Sale Notice Banner (Shopee/Lazada Sale Calendar)
            Container(
              padding: const EdgeInsets.all(AppDimens.space16),
              decoration: BoxDecoration(
                color: AppColors.motiveSaleBg,
                borderRadius: AppDimens.borderMedium,
                border: Border.all(color: AppColors.motiveSale.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_offer_outlined, color: AppColors.motiveSale),
                  const SizedBox(width: AppDimens.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lịch Sale Định Kỳ',
                          style: AppTextStyles.labelLarge.copyWith(color: AppColors.motiveSale),
                        ),
                        Text(
                          'Siêu Sale Giữa Tháng (15) & Lương Về (25). Hãy hoãn mua để nhận ưu đãi tốt nhất.',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space24),

            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Danh sách gần đây',
                  style: AppTextStyles.titleLarge,
                ),
                Text(
                  '${wishlistVm.filteredItems.length} món',
                  style: AppTextStyles.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: AppDimens.space12),

            // Wishlist Items Stream/State
            _buildWishlistContent(context, wishlistVm),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddItemScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Thêm món'),
      ),
    );
  }

  Widget _buildWishlistContent(BuildContext context, WishlistViewModel vm) {
    switch (vm.state) {
      case UiInitial():
      case UiLoading():
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: AppDimens.space32),
          child: LoadingView(message: 'Đang tải dữ liệu đám mây...'),
        );
      case UiEmpty(message: final msg, actionTitle: final actionTitle):
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimens.space24),
          child: EmptyView(
            title: msg,
            subtitle: 'Thêm món đồ bạn đang phân vân để bắt đầu hoãn tâm lý 3 ngày.',
            actionTitle: actionTitle,
            onAction: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddItemScreen()),
              );
            },
          ),
        );
      case UiError(message: final msg, onRetry: final retry):
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimens.space24),
          child: ErrorView(
            message: msg,
            onRetry: retry,
          ),
        );
      case UiSuccess(data: final items):
        final displayItems = items.take(10).toList();
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayItems.length,
          itemBuilder: (context, index) {
            final item = displayItems[index];
            return WishlistCard(
              item: item,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ItemDetailScreen(item: item),
                  ),
                );
              },
            );
          },
        );
    }
  }
}
