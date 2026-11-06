import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formatters/money_format.dart';
import '../core/validators/validators.dart';
import '../models/buying_motive.dart';
import '../models/wishlist_item.dart';
import '../services/product_metadata_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/budget_viewmodel.dart';
import '../viewmodels/wishlist_viewmodel.dart';
import '../widgets/amount_field.dart';
import '../widgets/app_button.dart';
import '../widgets/app_dropdown_field.dart';
import '../widgets/app_text_field.dart';
import '../widgets/item_suggestions.dart';
import '../widgets/motive_chip.dart';

/// Screen 04: Add Item Screen from Figma "Why I Buy".
/// With [existing] it edits that item; the price is then changed with "Cập nhật giá" instead.
class AddItemScreen extends StatefulWidget {
  final WishlistItem? existing;

  /// Prefilled name for a new item (e.g. the AI guess from "Chụp để tìm")
  final String? initialTitle;
  final String? initialUrl;
  final int? initialPrice;
  final String? initialImageUrl;
  final String? shopName;
  final String? productDescription;

  const AddItemScreen({
    super.key,
    this.existing,
    this.initialTitle,
    this.initialUrl,
    this.initialPrice,
    this.initialImageUrl,
    this.shopName,
    this.productDescription,
  });

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _urlController = TextEditingController();
  final _shopController = TextEditingController();

  BuyingMotive _selectedMotive = BuyingMotive.emotion;
  String? _budgetGroupId;
  int _priority = WishlistItem.defaultPriority;
  bool _isSaving = false;
  String? _imageUrl;
  String? _shopName;
  String? _productDescription;
  bool _isLoadingMetadata = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    if (item != null) {
      _titleController.text = item.title;
      _urlController.text = item.url ?? '';
      _shopController.text = item.shopName ?? '';
      _selectedMotive = item.displayMotive;
      _budgetGroupId = item.budgetGroupId;
      _priority = item.priority;
      _imageUrl = item.imageUrl;
    } else {
      if (widget.initialTitle case final title?) {
        _titleController.text = title;
      }
      if (widget.initialUrl case final url?) {
        _urlController.text = url;
      }
      if (widget.initialPrice case final price?) {
        _priceController.text = formatVnd(price).replaceAll(' ₫', '');
      }
      _imageUrl = widget.initialImageUrl;
      _shopName = widget.shopName;
      if (widget.shopName case final s?) {
        _shopController.text = s;
      }
      _productDescription = widget.productDescription;

      final url = _urlController.text.trim();
      if (url.isNotEmpty &&
          (_titleController.text.trim().isEmpty || _imageUrl == null)) {
        _loadMetadata(url);
      }
    }
  }

  Future<void> _loadMetadata(String url) async {
    if (!mounted) return;
    setState(() => _isLoadingMetadata = true);

    try {
      final meta = await ProductMetadataService.fetch(
        url,
        existingTitle: _titleController.text.trim().isNotEmpty
            ? _titleController.text.trim()
            : null,
        existingPrice: parseVnd(_priceController.text),
      );

      if (!mounted) return;

      setState(() {
        _isLoadingMetadata = false;
        final currentTitle = _titleController.text.trim();
        final shouldUpdateTitle =
            currentTitle.isEmpty ||
            currentTitle.toLowerCase().startsWith('cơ hội sở hữu') ||
            currentTitle.toLowerCase().startsWith('chia sẻ sản phẩm') ||
            (meta.title != null &&
                meta.title!.isNotEmpty &&
                currentTitle.length < 20);

        if (shouldUpdateTitle && meta.title != null && meta.title!.isNotEmpty) {
          _titleController.text = meta.title!;
        }
        if (_priceController.text.trim().isEmpty &&
            meta.priceVnd != null &&
            meta.priceVnd! > 0) {
          _priceController.text = formatVnd(meta.priceVnd!)
              .replaceAll(' ₫', '');
        }
        final hasBrandLogo =
            _imageUrl != null &&
            (_imageUrl!.contains('deo.shopeemobile.com') ||
                _imageUrl!.contains('26c9324913c021677768c36975d635ef'));
        if ((_imageUrl == null || hasBrandLogo) && meta.imageUrl != null) {
          _imageUrl = meta.imageUrl;
        }
        if (_shopName == null && meta.shopName != null) {
          _shopName = meta.shopName;
        }
        if (_shopController.text.trim().isEmpty &&
            meta.shopName != null &&
            meta.shopName!.isNotEmpty) {
          _shopController.text = meta.shopName!;
        }
        if (_productDescription == null && meta.description != null) {
          _productDescription = meta.description;
        }
        if (meta.url.isNotEmpty && meta.url != _urlController.text.trim()) {
          _urlController.text = meta.url;
        }
      });
    } catch (e) {
      debugPrint('AddItemScreen metadata load error: $e');
      if (mounted) {
        setState(() => _isLoadingMetadata = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _urlController.dispose();
    _shopController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    // Also reached from the SnackBar retry, possibly after leaving the screen
    if (!mounted || _isSaving) return;
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isSaving = true);
    final wishlistVm = context.read<WishlistViewModel>();

    final url = _urlController.text.trim();
    final existing = widget.existing;
    final success = existing != null
        ? await wishlistVm.updateDetails(
            existing,
            title: _titleController.text,
            url: url,
            motive: _selectedMotive,
            budgetGroupId: _budgetGroupId,
            priority: _priority,
          )
        : await wishlistVm.addItem(
            title: _titleController.text.trim(),
            price: parseVnd(_priceController.text),
            motive: _selectedMotive,
            productUrl: url.isNotEmpty ? url : null,
            budgetGroupId: _budgetGroupId,
            priority: _priority,
            imageUrl: _imageUrl,
            shopName: _shopController.text.trim().isNotEmpty
                ? _shopController.text.trim()
                : _shopName,
            saveChannel: widget.initialUrl != null || _imageUrl != null
                ? SaveChannel.share
                : SaveChannel.manual,
          );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit
                  ? 'Đã lưu thay đổi.'
                  : !_selectedMotive.skipsCooldown
                  ? 'Đã lưu vào danh sách cân nhắc. Thời gian cân nhắc: ${wishlistVm.coolingOffDays} ngày.'
                  : 'Đã lưu vào danh sách cân nhắc.',
            ),
            behavior: SnackBarBehavior.floating,
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
                wishlistVm.actionError ??
                    'Chưa lưu được món. Vui lòng thử lại.',
              ),
              behavior: SnackBarBehavior.floating,
              persist: false,
              action: SnackBarAction(label: 'Thử lại', onPressed: _handleSave),
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final coolingOffDays = context.watch<WishlistViewModel>().coolingOffDays;
    final groups = context.watch<BudgetViewModel>().groups;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Sửa thông tin món' : 'Thêm món cân nhắc'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.space16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoadingMetadata) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: AppDimens.space16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.space16,
                    vertical: AppDimens.space12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: AppDimens.borderMedium,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
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
                          'Đang tự động lấy thông tin từ Shopee...',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_imageUrl != null && _imageUrl!.isNotEmpty) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: AppDimens.space16),
                  padding: const EdgeInsets.all(AppDimens.space12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppDimens.borderMedium,
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _imageUrl!,
                          width: 68,
                          height: 68,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 68,
                            height: 68,
                            color: AppColors.background,
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimens.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEE4D2D)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Shopee',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFEE4D2D),
                                ),
                              ),
                            ),
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _shopController,
                              builder: (_, val, _) {
                                final name = val.text.trim().isNotEmpty
                                    ? val.text.trim()
                                    : _shopName;
                                if (name == null || name.isEmpty)
                                  return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Shop: $name',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Product Title Input
              AppTextField(
                label: 'Tên sản phẩm *',
                hint: 'Ví dụ: Tai nghe chống ồn Sony...',
                controller: _titleController,
                validator: Validators.validateTitle,
              ),
              const SizedBox(height: AppDimens.space16),
              if (!_isEdit)
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _titleController,
                  builder: (_, value, _) => DuplicateHint(
                    title: value.text,
                    budgetGroupId: _budgetGroupId,
                  ),
                ),

              // Price Input (new items only; an edit changes the price via "Cập nhật giá")
              if (!_isEdit) ...[
                // Same VND field as Ghi khoản mua: "389.000" grouping, "₫", empty = unknown price
                AmountField(
                  key: const ValueKey('wishlist-price'),
                  label: 'Giá dự kiến (không bắt buộc)',
                  hint: 'Để trống nếu chưa biết giá',
                  controller: _priceController,
                  optional: true,
                  enabled: !_isSaving,
                ),
                const SizedBox(height: AppDimens.space16),
              ],

              // Product URL Input
              AppTextField(
                label: 'Link Shopee / Lazada (Tùy chọn)',
                hint: 'https://shopee.vn/...',
                controller: _urlController,
                keyboardType: TextInputType.url,
                prefixIcon: Icons.link,
              ),
              const SizedBox(height: AppDimens.space16),

              // Shop Name Input
              AppTextField(
                label: 'Tên cửa hàng / Shop (Tùy chọn)',
                hint: 'Ví dụ: Shopee Mall, Shop Thời Trang...',
                controller: _shopController,
                prefixIcon: Icons.storefront_outlined,
              ),
              const SizedBox(height: AppDimens.space16),

              // Budget group: prefilled when the item is bought later. Re-keyed by value
              // so an applied suggestion shows in the field.
              KeyedSubtree(
                key: const ValueKey('wishlist-budget-group'),
                child: AppDropdownField<String?>(
                  key: ValueKey('wishlist-budget-group-$_budgetGroupId'),
                  value: groups.any((g) => g.id == _budgetGroupId)
                      ? _budgetGroupId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Nhóm ngân sách (không bắt buộc)',
                  ),
                  items: [
                    const AppDropdownItem<String?>(
                      value: null,
                      label: 'Chưa chọn',
                    ),
                    for (final group in groups)
                      AppDropdownItem<String?>(
                        value: group.id,
                        label: group.name,
                      ),
                  ],
                  enabled: !_isSaving,
                  onChanged: _isSaving
                      ? null
                      : (value) => setState(() => _budgetGroupId = value),
                ),
              ),
              // Only while no group is chosen; the user's own choice is never second-guessed
              if (_budgetGroupId == null)
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _titleController,
                  builder: (_, value, _) => BudgetGroupSuggestion(
                    title: value.text,
                    groups: groups,
                    selectedGroupId: _budgetGroupId,
                    enabled: !_isSaving,
                    onApply: (id) => setState(() => _budgetGroupId = id),
                  ),
                ),
              const SizedBox(height: AppDimens.space24),

              // Priority (1–5 stars): used by "So sánh" and the sale plan (spec 7.5)
              Text('Mức ưu tiên', style: AppTextStyles.titleMedium),
              Row(
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      key: ValueKey('priority-$i'),
                      tooltip: '$i sao',
                      onPressed: _isSaving
                          ? null
                          : () => setState(() => _priority = i),
                      icon: Icon(
                        i <= _priority
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: AppColors.motiveSale,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppDimens.space16),

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
              if (!_isEdit && !_selectedMotive.skipsCooldown)
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
                title: _isEdit ? 'Lưu thay đổi' : 'Lưu vào Wishlist',
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
