import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formatters/money_format.dart';
import '../core/validators/validators.dart';
import '../models/buying_motive.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/wishlist_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/motive_chip.dart';

/// Screen 04: Add Item Screen from Figma "Why I Buy"
class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _urlController = TextEditingController();

  BuyingMotive _selectedMotive = BuyingMotive.emotion;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    // Also reached from the SnackBar retry, possibly after leaving the screen
    if (!mounted || _isSaving) return;
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isSaving = true);
    final wishlistVm = context.read<WishlistViewModel>();

    final price = parseVnd(_priceController.text);
    final success = await wishlistVm.addItem(
      title: _titleController.text.trim(),
      price: price,
      motive: _selectedMotive,
      productUrl: _urlController.text.trim().isNotEmpty
          ? _urlController.text.trim()
          : null,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !_selectedMotive.skipsCooldown
                  ? 'Đã lưu vào danh sách cân nhắc. Thời gian cân nhắc: ${wishlistVm.coolingOffDays} ngày.'
                  : 'Đã lưu vào danh sách cân nhắc.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      } else {
        // The form stays open with everything the user typed
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                wishlistVm.actionError ?? 'Chưa lưu được món. Vui lòng thử lại.',
              ),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(label: 'Thử lại', onPressed: _handleSave),
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final coolingOffDays = context.watch<WishlistViewModel>().coolingOffDays;
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm món cân nhắc')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.space16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Title Input
              AppTextField(
                label: 'Tên sản phẩm *',
                hint: 'Ví dụ: Tai nghe chống ồn Sony...',
                controller: _titleController,
                validator: Validators.validateTitle,
              ),
              const SizedBox(height: AppDimens.space16),

              // Price Input
              AppTextField(
                label: 'Giá dự kiến (VND)',
                hint: 'Ví dụ: 350000',
                controller: _priceController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.attach_money,
                validator: Validators.validateOptionalAmount,
              ),
              const SizedBox(height: AppDimens.space16),

              // Product URL Input
              AppTextField(
                label: 'Link Shopee / Lazada (Tùy chọn)',
                hint: 'https://shopee.vn/...',
                controller: _urlController,
                keyboardType: TextInputType.url,
                prefixIcon: Icons.link,
              ),
              const SizedBox(height: AppDimens.space24),

              // Motive Selection Header
              Text(
                'Tại sao bạn muốn mua món này? *',
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: AppDimens.space4),
              Text(
                'Chọn thật lòng động cơ thúc đẩy quyết định của bạn:',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppDimens.space12),

              // 8 Motives Wrap
              Wrap(
                spacing: AppDimens.space8,
                runSpacing: AppDimens.space8,
                children: BuyingMotive.values.map((motive) {
                  final isSelected = _selectedMotive == motive;
                  return MotiveChip(
                    motive: motive,
                    isSelected: isSelected,
                    onSelected: (m) => setState(() => _selectedMotive = m),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppDimens.space20),

              // Cooldown Hint if Emotion/Social is selected
              if (!_selectedMotive.skipsCooldown)
                Container(
                  padding: const EdgeInsets.all(AppDimens.space16),
                  decoration: BoxDecoration(
                    color: AppColors.motiveEmotionBg,
                    borderRadius: AppDimens.borderMedium,
                    border: Border.all(
                      color: AppColors.motiveEmotion.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.psychology,
                        color: AppColors.motiveEmotion,
                      ),
                      const SizedBox(width: AppDimens.space12),
                      Expanded(
                        child: Text(
                          'Món này có $coolingOffDays ngày cân nhắc trước khi quyết định (mọi động cơ trừ Nhu cầu).',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.motiveEmotion,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: AppDimens.space32),

              // Save Button
              AppButton(
                title: 'Lưu vào Wishlist',
                icon: Icons.check,
                isLoading: _isSaving,
                onPressed: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
