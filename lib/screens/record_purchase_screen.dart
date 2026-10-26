import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../models/buying_motive.dart';
import '../models/purchase_item.dart';
import '../theme/app_colors.dart';
import '../viewmodels/purchase_viewmodel.dart';

/// Screen 03 & 04: Ghi khoản mua (Bước 1/2 và Bước 2/2) from Figma "Why I Buy ver2"
class RecordPurchaseScreen extends StatefulWidget {
  final int? initialAmount;
  final String? initialTitle;
  final PurchaseItem? existingPurchase;

  const RecordPurchaseScreen({
    super.key,
    this.initialAmount,
    this.initialTitle,
    this.existingPurchase,
  });

  @override
  State<RecordPurchaseScreen> createState() => _RecordPurchaseScreenState();
}

class _RecordPurchaseScreenState extends State<RecordPurchaseScreen> {
  int _currentStep = 1; // 1 or 2

  // Step 1 Controllers & State
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();
  int _rawAmount = 0;

  // Step 2 State
  BuyingMotive _selectedMotive = BuyingMotive.emotion;
  final _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingPurchase != null) {
      final p = widget.existingPurchase!;
      _rawAmount = p.amountVnd;
      _amountController.text = formatVnd(_rawAmount);
      _titleController.text = p.title;
      _selectedDateTime = p.occurredAt;
      _selectedMotive = p.motive;
      _noteController.text = p.note ?? '';
    } else {
      _rawAmount = widget.initialAmount ?? 0;
      if (_rawAmount > 0) {
        _amountController.text = formatVnd(_rawAmount);
      }
      _titleController.text = widget.initialTitle ?? '';
      _noteController.text = '';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onAmountChanged(String val) {
    final parsed = parseVnd(val) ?? 0;
    setState(() {
      _rawAmount = parsed;
    });
  }

  void _addQuickAmount(int amount) {
    setState(() {
      _rawAmount += amount;
      _amountController.text = formatVnd(_rawAmount);
    });
  }

  void _clearAmount() {
    setState(() {
      _rawAmount = 0;
      _amountController.text = '0 ₫';
    });
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (time == null || !mounted) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _goToStep2() {
    if (_rawAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số tiền thực chi hợp lệ'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên món đồ hoặc dịch vụ'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() {
      _currentStep = 2;
    });
  }

  Future<void> _handleSavePurchase() async {
    setState(() => _isSaving = true);

    final purchaseVm = context.read<PurchaseViewModel>();
    final title = _titleController.text.trim();
    final note = _noteController.text.trim().isNotEmpty
        ? _noteController.text.trim()
        : null;

    if (widget.existingPurchase != null) {
      await purchaseVm.updatePurchase(
        id: widget.existingPurchase!.id,
        title: title,
        amount: _rawAmount,
        motive: _selectedMotive,
        dateTime: _selectedDateTime,
        note: note,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Đã cập nhật khoản mua: $title!'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop();
    } else {
      final savedItem = await purchaseVm.addPurchase(
        title: title,
        amount: _rawAmount,
        motive: _selectedMotive,
        dateTime: _selectedDateTime,
        note: note,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (savedItem == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chưa lưu được khoản mua. Thử lại sau ít phút.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Đã lưu khoản mua: $title!'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop();
      // Flow 8: Navigate to detail review screen
      Navigator.pushNamed(
        context,
        AppRoutes.purchaseDetail,
        arguments: PurchaseDetailArgs(savedItem),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.onPrimary,
          ),
          onPressed: () {
            if (_currentStep == 2) {
              setState(() => _currentStep = 1);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          widget.existingPurchase != null
              ? 'Chỉnh sửa khoản mua'
              : 'Ghi khoản mua',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.onPrimary,
          ),
        ),
        actions: [
          if (_currentStep == 2)
            IconButton(
              icon: const Icon(
                Icons.help_outline_rounded,
                color: AppColors.textSecondary,
              ),
              tooltip: 'Giải thích động cơ',
              onPressed: () => _showMotiveHelpDialog(context),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Stepper indicator header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  // Yellow pill step tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      _currentStep == 1
                          ? 'Bước 1/2: Thông tin khoản chi'
                          : 'Bước 2/2: Động cơ mua sắm',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Progress Dots
                  Row(
                    children: [
                      Container(
                        width: _currentStep == 1 ? 18 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: _currentStep == 2 ? 18 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentStep == 2
                              ? AppColors.primary
                              : AppColors.divider,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.divider),

            // Content body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _currentStep == 1 ? _buildStep1() : _buildStep2(),
              ),
            ),

            // Bottom action container
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ===================== STEP 1 WIDGETS =====================
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Số tiền thực chi
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Số tiền thực chi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Bắt buộc',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onErrorContainer,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Amount Input Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onPrimary,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: _onAmountChanged,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.cancel_rounded,
                  color: AppColors.textHint,
                  size: 22,
                ),
                onPressed: _clearAmount,
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Quick amount chips
        Row(
          children: [
            _buildQuickChip('+20.000 ₫', 20000),
            const SizedBox(width: 8),
            _buildQuickChip('+50.000 ₫', 50000),
            const SizedBox(width: 8),
            _buildQuickChip('+100.000 ₫', 100000),
          ],
        ),

        const SizedBox(height: 24),

        // 2. Tên món đồ hoặc dịch vụ
        const Text(
          'Tên món đồ hoặc dịch vụ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.local_cafe_outlined,
                color: AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _titleController,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onPrimary,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Ví dụ: Trà sữa nướng, Cơm tấm...',
                    hintStyle: TextStyle(
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 3. Thời điểm chi tiêu
        const Text(
          'Thời điểm chi tiêu',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickDateTime,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatRelativeDateTime(_selectedDateTime),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatWeekdayDate(_selectedDateTime),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickChip(String label, int amount) {
    return InkWell(
      onTap: () => _addQuickAmount(amount),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.accentNeutral,
          ),
        ),
      ),
    );
  }

  // ===================== STEP 2 WIDGETS =====================
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recap Card of Item being saved
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_cafe_outlined,
                  color: AppColors.onPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleController.text.trim(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatVnd(_rawAmount),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentNeutral,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Question header
        const Text(
          'Điều gì thúc đẩy bạn mua món này?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.onPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Chọn 1 động cơ chính',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),

        const SizedBox(height: 16),

        // Motive 8-Grid (2 columns x 4 rows)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: BuyingMotive.values.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.3,
          ),
          itemBuilder: (context, index) {
            final motive = BuyingMotive.values[index];
            final isSelected = motive == _selectedMotive;
            return _buildMotiveCard(motive, isSelected);
          },
        ),

        const SizedBox(height: 24),

        // Optional note input
        const Text(
          'Ghi chú thêm (không bắt buộc)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _noteController,
            maxLines: 2,
            style: const TextStyle(fontSize: 14, color: AppColors.onPrimary),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Ví dụ: Buồn vì công việc nên muốn uống gì ngọt...',
              hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
              isDense: true,
            ),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMotiveCard(BuyingMotive motive, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedMotive = motive;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : motive.backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                motive.icon,
                size: 18,
                color: isSelected ? AppColors.onPrimary : motive.color,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                motive.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.onPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: AppColors.onPrimary,
              ),
          ],
        ),
      ),
    );
  }

  // ===================== BOTTOM ACTION BAR =====================
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              onPressed: _isSaving
                  ? null
                  : (_currentStep == 1 ? _goToStep2 : _handleSavePurchase),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentStep == 1
                              ? 'Tiếp tục'
                              : (widget.existingPurchase != null
                                    ? 'Cập nhật khoản mua'
                                    : 'Lưu khoản mua'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentStep == 1
                              ? Icons.arrow_forward_rounded
                              : Icons.check_rounded,
                          size: 20,
                        ),
                      ],
                    ),
            ),
          ),
          if (_currentStep == 1) ...[
            const SizedBox(height: 6),
            const Text(
              'Bước tiếp theo: chọn động cơ của khoản mua',
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ],
        ],
      ),
    );
  }

  void _showMotiveHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Động cơ mua sắm là gì?'),
        content: const SingleChildScrollView(
          child: Text(
            'Why I Buy giúp bạn phân biệt rõ 8 lý do thực sự khiến bạn móc hầu bao:\n\n'
            '• Nhu cầu: Đồ thiết yếu cho sinh hoạt, công việc.\n'
            '• Mong muốn: Món đồ nâng cấp chất lượng cuộc sống.\n'
            '• Khuyến mãi: Giảm giá, quà tặng khiến bạn quyết định mua nhanh.\n'
            '• Ảnh hưởng MXH: Thấy trên TikTok, Facebook, người nổi tiếng dùng.\n'
            '• Quảng cáo: Tiếp thị nhắm mục tiêu, banner tài trợ.\n'
            '• Cảm xúc: Mua để giải tỏa căng thẳng, buồn bã hoặc tự thưởng.\n'
            '• Tiện lợi: Tiện đường, tiết kiệm công sức nhất thời.\n'
            '• Khác: Các nguyên nhân phát sinh khác.',
            style: TextStyle(height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }
}
