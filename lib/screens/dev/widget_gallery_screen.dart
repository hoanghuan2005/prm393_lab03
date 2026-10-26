import 'package:flutter/material.dart';

import '../../models/buying_motive.dart';
import '../../models/ui_state.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/amount_field.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/app_button.dart';
import '../../widgets/budget_bar.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/money_text.dart';
import '../../widgets/motive_chip.dart';
import '../../widgets/price_chip.dart';
import '../../widgets/section_card.dart';
import '../../widgets/states/ui_state_builder.dart';
import '../../widgets/undo_snack_bar.dart';

/// Debug-only catalogue of the shared widgets in lib/widgets, so the team can see each
/// one with sample values. Opened from the Firebase Demo Area; not registered in release.
class WidgetGalleryScreen extends StatefulWidget {
  const WidgetGalleryScreen({super.key});

  @override
  State<WidgetGalleryScreen> createState() => _WidgetGalleryScreenState();
}

class _WidgetGalleryScreenState extends State<WidgetGalleryScreen> {
  final _formKey = GlobalKey<FormState>();
  BuyingMotive? _selectedMotive = BuyingMotive.sale;

  static final Map<String, UiState<String>> _states = {
    'UiLoading': const UiLoading(),
    'UiEmpty': const UiEmpty(message: 'Chưa có khoản mua nào được ghi'),
    'UiError': UiError(message: 'Không có kết nối mạng.', onRetry: () {}),
    'UiSuccess': const UiSuccess('Dữ liệu đã tải'),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Widget Gallery')),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.space16),
        children: [
          SectionCard(
            title: 'UiStateBuilder',
            icon: Icons.layers_outlined,
            children: [
              for (final entry in _states.entries) ...[
                Text(entry.key, style: AppTextStyles.labelLarge),
                SizedBox(
                  height: 220,
                  child: UiStateBuilder<String>(
                    state: entry.value,
                    builder: (_, data) => Center(child: Text(data)),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppDimens.space16),
          SectionCard(
            title: 'AmountField',
            icon: Icons.payments_outlined,
            children: [
              Form(
                key: _formKey,
                child: const Column(
                  children: [
                    AmountField(label: 'Số tiền thực chi *'),
                    SizedBox(height: AppDimens.space12),
                    AmountField(label: 'Giá (tuỳ chọn)', optional: true),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.space12),
              AppButton(
                title: 'Kiểm tra form',
                variant: AppButtonVariant.secondary,
                onPressed: () => _formKey.currentState?.validate(),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space16),
          SectionCard(
            title: 'Dialog · SnackBar · Bottom sheet',
            icon: Icons.open_in_new,
            children: [
              AppButton(
                title: 'ConfirmDialog',
                variant: AppButtonVariant.secondary,
                onPressed: () => ConfirmDialog.show(
                  context,
                  title: 'Lưu thay đổi?',
                  message: 'Thông tin món sẽ được cập nhật.',
                ),
              ),
              const SizedBox(height: AppDimens.space8),
              AppButton(
                title: 'ConfirmDialog (isDanger)',
                variant: AppButtonVariant.secondary,
                onPressed: () => ConfirmDialog.show(
                  context,
                  title: 'Xoá khoản mua này?',
                  message: 'Khoản mua sẽ bị xoá khỏi lịch sử.',
                  confirmLabel: 'Xoá',
                  isDanger: true,
                ),
              ),
              const SizedBox(height: AppDimens.space8),
              AppButton(
                title: 'showUndoSnackBar',
                variant: AppButtonVariant.secondary,
                onPressed: () => showUndoSnackBar(
                  context,
                  'Đã chuyển món sang Bỏ qua.',
                  () {},
                ),
              ),
              const SizedBox(height: AppDimens.space8),
              AppButton(
                title: 'AppBottomSheet',
                variant: AppButtonVariant.secondary,
                onPressed: () => AppBottomSheet.show<void>(
                  context,
                  title: 'Cập nhật giá',
                  child: const AmountField(label: 'Giá hiện tại'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space16),
          const SectionCard(
            title: 'MoneyText · PriceChip',
            icon: Icons.sell_outlined,
            children: [
              MoneyText(389000, size: MoneyTextSize.large),
              MoneyText(389000),
              MoneyText(389000, size: MoneyTextSize.small),
              MoneyText(null),
              SizedBox(height: AppDimens.space12),
              Wrap(
                spacing: AppDimens.space8,
                children: [
                  PriceChip(priceVnd: 1290000),
                  PriceChip(priceVnd: null),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space16),
          SectionCard(
            title: 'MotiveChip',
            icon: Icons.psychology_outlined,
            children: [
              Wrap(
                spacing: AppDimens.space8,
                runSpacing: AppDimens.space8,
                children: [
                  for (final motive in BuyingMotive.values)
                    MotiveChip(
                      motive: motive,
                      isSelected: motive == _selectedMotive,
                      onSelected: (m) => setState(() => _selectedMotive = m),
                    ),
                ],
              ),
              const SizedBox(height: AppDimens.space12),
              Text(
                'isCompact (chỉ hiển thị)',
                style: AppTextStyles.labelMedium,
              ),
              const SizedBox(height: AppDimens.space8),
              const Wrap(
                spacing: AppDimens.space8,
                children: [
                  MotiveChip(motive: BuyingMotive.need, isCompact: true),
                  MotiveChip(motive: BuyingMotive.emotion, isCompact: true),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space16),
          const SectionCard(
            title: 'BudgetBar',
            icon: Icons.account_balance_wallet_outlined,
            children: [
              BudgetBar(spentVnd: 40000, limitVnd: 1000000, label: 'Công nghệ'),
              SizedBox(height: AppDimens.space16),
              BudgetBar(
                spentVnd: 690000,
                limitVnd: 600000,
                label: 'Thời trang',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
