import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/buying_motive.dart';
import '../theme/app_colors.dart';
import '../viewmodels/purchase_viewmodel.dart';

/// Screen 03 & 04: Ghi khoản mua (Bước 1/2 và Bước 2/2) from Figma "Why I Buy ver2"
class RecordPurchaseScreen extends StatefulWidget {
  final double? initialAmount;
  final String? initialTitle;

  const RecordPurchaseScreen({
    super.key,
    this.initialAmount,
    this.initialTitle,
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
  double _rawAmount = 45000;

  // Step 2 State
  BuyingMotive _selectedMotive = BuyingMotive.emotion;
  final _noteController = TextEditingController();
  bool _isSaving = false;

  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _rawAmount = widget.initialAmount ?? 45000;
    _amountController.text = _currencyFormat.format(_rawAmount).trim();
    _titleController.text = widget.initialTitle ?? 'Trà sữa nướng';
    _noteController.text = 'Buồn vì công việc nên muốn uống gì ngọt...';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onAmountChanged(String val) {
    final cleaned = val.replaceAll(RegExp(r'[^0-9]'), '');
    final parsed = double.tryParse(cleaned) ?? 0;
    setState(() {
      _rawAmount = parsed;
    });
  }

  void _addQuickAmount(double amount) {
    setState(() {
      _rawAmount += amount;
      _amountController.text = _currencyFormat.format(_rawAmount).trim();
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
      _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  String _formatTimeHeader(DateTime dt) {
    final now = DateTime.now();
    final isToday = now.year == dt.year && now.month == dt.month && now.day == dt.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = yesterday.year == dt.year && yesterday.month == dt.month && yesterday.day == dt.day;
    final timeStr = DateFormat('HH:mm').format(dt);

    if (isToday) {
      return 'Hôm nay $timeStr';
    } else if (isYesterday) {
      return 'Hôm qua $timeStr';
    } else {
      return '${DateFormat('dd/MM').format(dt)} $timeStr';
    }
  }

  String _formatVietnameseDate(DateTime dt) {
    const weekdays = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    final weekdayName = weekdays[dt.weekday - 1];
    final dateStr = DateFormat('dd/MM/yyyy').format(dt);
    return '$weekdayName, $dateStr';
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
    purchaseVm.addPurchase(
      title: _titleController.text.trim(),
      amount: _rawAmount,
      motive: _selectedMotive,
      dateTime: _selectedDateTime,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
    );

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('Đã lưu khoản mua: ${_titleController.text.trim()}!'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onPrimary),
          onPressed: () {
            if (_currentStep == 2) {
              setState(() => _currentStep = 1);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Text(
          'Ghi khoản mua',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.onPrimary,
          ),
        ),
        actions: [
          if (_currentStep == 2)
            IconButton(
              icon: const Icon(Icons.help_outline_rounded, color: Color(0xFF6D6E73)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFCE6),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      _currentStep == 1 ? 'Bước 1/2: Thông tin khoản chi' : 'Bước 2/2: Động cơ mua sắm',
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
                          color: _currentStep == 2 ? AppColors.primary : const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE5E7EB)),

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
                color: Color(0xFF6D6E73),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Bắt buộc',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFDC2626),
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
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
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
                icon: const Icon(Icons.cancel_rounded, color: Color(0xFF9CA3AF), size: 22),
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
            color: Color(0xFF6D6E73),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_cafe_outlined, color: Color(0xFF6D6E73), size: 22),
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
                    hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.w400),
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
            color: Color(0xFF6D6E73),
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
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, color: Color(0xFF6D6E73), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatTimeHeader(_selectedDateTime),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatVietnameseDate(_selectedDateTime),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6D6E73),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.calendar_today_rounded, color: Color(0xFF6D6E73), size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickChip(String label, double amount) {
    return InkWell(
      onTap: () => _addQuickAmount(amount),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF47667B),
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
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFCE6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_cafe_outlined, color: AppColors.onPrimary, size: 22),
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
                      _currencyFormat.format(_rawAmount).trim(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF47667B),
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
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF6D6E73),
          ),
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
            color: Color(0xFF6D6E73),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: TextField(
            controller: _noteController,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.onPrimary,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Ví dụ: Buồn vì công việc nên muốn uống gì ngọt...',
              hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
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
          color: isSelected ? const Color(0xFFFFFCE6) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
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
                color: Color(0xFF070E20),
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
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
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
              onPressed: _isSaving ? null : (_currentStep == 1 ? _goToStep2 : _handleSavePurchase),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.onPrimary),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentStep == 1 ? 'Tiếp tục' : 'Lưu khoản mua',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentStep == 1 ? Icons.arrow_forward_rounded : Icons.check_rounded,
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
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
              ),
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
