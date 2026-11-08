import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/admin_models.dart';
import '../services/admin_service.dart';
import '../theme/admin_colors.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedPlatform = 'Tất cả';
  String? _sendingPushId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showToast({
    required bool isSuccess,
    required String message,
    String? details,
  }) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 24, right: 32, left: 32),
        backgroundColor:
            isSuccess ? const Color(0xFF065F46) : const Color(0xFF991B1B),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSuccess ? AdminColors.emerald : AdminColors.rose,
            width: 1.5,
          ),
        ),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: (isSuccess ? AdminColors.emerald : AdminColors.rose)
                    .withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                color:
                    isSuccess ? const Color(0xFF34D399) : const Color(0xFFF87171),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (details != null && details.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      details,
                      style: const TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendVoucherPush(VoucherItem item, AdminService admin) async {
    final pushId = 'voucher_${item.id}';
    if (_sendingPushId != null) return;
    setState(() => _sendingPushId = pushId);

    try {
      await admin.sendVoucherPushDirect(item);
      _showToast(
        isSuccess: true,
        message: 'Đã bắn Push Voucher thành công!',
        details:
            'Mã: ${item.code} (${item.title}) đã được phát tới người dùng.',
      );
    } catch (e) {
      _showToast(
        isSuccess: false,
        message: 'Bắn Push thất bại!',
        details: e
            .toString()
            .replaceAll('Exception: ', '')
            .replaceAll('StateError: ', ''),
      );
    } finally {
      if (mounted) setState(() => _sendingPushId = null);
    }
  }

  Future<void> _sendSaleEventPush(
    AdminSaleEvent event,
    AdminService admin,
  ) async {
    final pushId = 'sale_${event.id}';
    if (_sendingPushId != null) return;
    setState(() => _sendingPushId = pushId);

    try {
      await admin.sendSaleEventPushDirect(event);
      _showToast(
        isSuccess: true,
        message: 'Đã bắn thông báo Đợt Sale thành công!',
        details:
            '${event.name} (${event.date}): Nhắc nhở người dùng săn deal thành công.',
      );
    } catch (e) {
      _showToast(
        isSuccess: false,
        message: 'Bắn thông báo đợt sale thất bại!',
        details: e
            .toString()
            .replaceAll('Exception: ', '')
            .replaceAll('StateError: ', ''),
      );
    } finally {
      if (mounted) setState(() => _sendingPushId = null);
    }
  }

  void _showAddVoucherDialog(BuildContext context, [VoucherItem? initialData]) {
    final codeCtrl = TextEditingController(text: initialData?.code ?? '');
    final titleCtrl = TextEditingController(text: initialData?.title ?? '');
    final discountCtrl = TextEditingController(
      text: initialData != null ? initialData.discountAmount.toString() : '30000',
    );
    final minOrderCtrl = TextEditingController(
      text: initialData != null ? initialData.minOrder.toString() : '150000',
    );
    final validUntilCtrl = TextEditingController(
      text: initialData?.validUntil ?? '2026-11-15',
    );
    final urlCtrl = TextEditingController(text: initialData?.affiliateUrl ?? '');
    String platform = initialData?.platform ?? 'Shopee';
    String category = initialData?.category ?? 'Tất cả';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AdminColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AdminColors.border),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AdminColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_offer_rounded,
                  color: AdminColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                initialData == null ? 'Thêm Voucher Khuyến Mãi' : 'Chỉnh Sửa Voucher',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AdminColors.textPrimary,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sàn TMĐT & Danh mục
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sàn TMĐT',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AdminColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: platform,
                              dropdownColor: AdminColors.surfaceLight,
                              style: TextStyle(color: AdminColors.textPrimary, fontSize: 13),
                              decoration: _inputDeco(),
                              items: const [
                                DropdownMenuItem(value: 'Shopee', child: Text('Shopee')),
                                DropdownMenuItem(value: 'Lazada', child: Text('Lazada')),
                                DropdownMenuItem(value: 'Tất cả', child: Text('Toàn sàn / Khác')),
                              ],
                              onChanged: (v) {
                                if (v != null) setDialogState(() => platform = v);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ngành hàng',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AdminColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: category,
                              dropdownColor: AdminColors.surfaceLight,
                              style: TextStyle(color: AdminColors.textPrimary, fontSize: 13),
                              decoration: _inputDeco(),
                              items: const [
                                DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả')),
                                DropdownMenuItem(value: 'Công nghệ', child: Text('Công nghệ')),
                                DropdownMenuItem(value: 'Thời trang', child: Text('Thời trang')),
                                DropdownMenuItem(value: 'Làm đẹp', child: Text('Làm đẹp')),
                                DropdownMenuItem(value: 'Gia dụng', child: Text('Gia dụng')),
                              ],
                              onChanged: (v) {
                                if (v != null) setDialogState(() => category = v);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Mã Code
                  Text(
                    'Mã Voucher (Code)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AdminColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: codeCtrl,
                    style: TextStyle(color: AdminColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                    decoration: _inputDeco(hintText: 'VD: SHOPEE1111, FREESHIP50K'),
                  ),
                  const SizedBox(height: 14),

                  // Tiêu đề
                  Text(
                    'Tiêu đề / Mô tả voucher',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AdminColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleCtrl,
                    style: TextStyle(color: AdminColors.textPrimary, fontSize: 13),
                    decoration: _inputDeco(hintText: 'VD: Giảm 50K cho đơn từ 250K toàn sàn Shopee'),
                  ),
                  const SizedBox(height: 14),

                  // Mức giảm & Đơn tối thiểu
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Số tiền giảm (VND)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AdminColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: discountCtrl,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: AdminColors.emerald, fontSize: 13, fontWeight: FontWeight.bold),
                              decoration: _inputDeco(hintText: '30000'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đơn tối thiểu (VND)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AdminColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: minOrderCtrl,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: AdminColors.textPrimary, fontSize: 13),
                              decoration: _inputDeco(hintText: '150000'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Hạn dùng & Link
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hạn dùng (YYYY-MM-DD)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AdminColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: validUntilCtrl,
                              style: TextStyle(color: AdminColors.textPrimary, fontSize: 13),
                              decoration: _inputDeco(hintText: '2026-11-15'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Link săn mã (Tùy chọn)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AdminColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: urlCtrl,
                              style: TextStyle(color: AdminColors.textPrimary, fontSize: 13),
                              decoration: _inputDeco(hintText: 'https://shopee.vn/m/...'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Hủy', style: TextStyle(color: AdminColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.primary,
                foregroundColor: AdminColors.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final code = codeCtrl.text.trim();
                final title = titleCtrl.text.trim();
                if (code.isEmpty || title.isEmpty) return;

                final discount = int.tryParse(discountCtrl.text.trim()) ?? 0;
                final minOrder = int.tryParse(minOrderCtrl.text.trim()) ?? 0;
                final validUntil = validUntilCtrl.text.trim().isEmpty
                    ? '2026-11-15'
                    : validUntilCtrl.text.trim();
                final url = urlCtrl.text.trim();

                final item = VoucherItem(
                  id: initialData?.id ?? 'vouch_${DateTime.now().millisecondsSinceEpoch}',
                  code: code,
                  title: title,
                  platform: platform,
                  discountAmount: discount,
                  minOrder: minOrder,
                  validUntil: validUntil,
                  affiliateUrl: url,
                  isActive: true,
                  category: category,
                );

                context.read<AdminService>().addVoucher(item);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã lưu voucher: $code'),
                    backgroundColor: AdminColors.emerald,
                  ),
                );
              },
              child: const Text('Lưu & Đăng lên App', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showPasteLinkDialog(BuildContext context) {
    final linkCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AdminColors.border),
        ),
        title: Row(
          children: [
            const Icon(Icons.link_rounded, color: AdminColors.blue, size: 24),
            const SizedBox(width: 8),
            Text(
              'Nhập Link Chương Trình Khuyến Mãi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dán link chiến dịch Shopee hoặc Lazada (ví dụ trang 11.11, mã giảm giá, freeship):',
                style: TextStyle(fontSize: 13, color: AdminColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: linkCtrl,
                style: TextStyle(color: AdminColors.textPrimary, fontSize: 13),
                decoration: _inputDeco(hintText: 'https://shopee.vn/m/11-11-sieu-sale...'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Đóng', style: TextStyle(color: AdminColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final raw = linkCtrl.text.trim();
              if (raw.isEmpty) return;
              Navigator.of(ctx).pop();

              // Heuristic extract
              final isShopee = raw.contains('shopee.vn') || raw.contains('shp.ee');
              final isLazada = raw.contains('lazada.vn');
              final platform = isShopee ? 'Shopee' : (isLazada ? 'Lazada' : 'Tất cả');

              // Open Add dialog pre-filled
              _showAddVoucherDialog(
                context,
                VoucherItem(
                  id: 'vouch_${DateTime.now().millisecondsSinceEpoch}',
                  code: isShopee ? 'SHOPEE1111' : 'LAZADA1111',
                  title: 'Ưu Đãi Đặc Biệt Từ $platform (Sự Kiện Siêu Sale)',
                  platform: platform,
                  discountAmount: 50000,
                  minOrder: 200000,
                  validUntil: '2026-11-15',
                  affiliateUrl: raw,
                  isActive: true,
                ),
              );
            },
            child: const Text('Phân tích & Thêm'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: AdminColors.textMuted, fontSize: 13),
      filled: true,
      fillColor: AdminColors.surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AdminColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AdminColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AdminColors.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminService>();
    final vouchers = admin.vouchers.where((v) {
      final matchesSearch = _searchQuery.isEmpty ||
          v.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          v.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesPlatform =
          _selectedPlatform == 'Tất cả' || v.platform == _selectedPlatform;
      return matchesSearch && matchesPlatform;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Toolbar
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Săn Voucher & Lịch Sale',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AdminColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AdminColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AdminColors.primary.withValues(alpha: 0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '${admin.vouchers.length} Voucher',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AdminColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tự động quét lịch sale sàn TMĐT, thêm voucher ưu đãi và gợi ý đến giỏ hàng người dùng.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AdminColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminColors.textPrimary,
                      side: BorderSide(color: AdminColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.link_rounded, size: 18, color: AdminColors.blue),
                    label: const Text('Nhập Link Shopee'),
                    onPressed: () => _showPasteLinkDialog(context),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminColors.textPrimary,
                      side: BorderSide(color: AdminColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.event_repeat_rounded, size: 18, color: AdminColors.purple),
                    label: const Text('Đồng Bộ Lịch Sale'),
                    onPressed: () async {
                      await admin.syncStandardSalesCalendar();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã đồng bộ lịch sale ngày đôi 11.11, 15 giữa tháng, 25 ngày lương!'),
                            backgroundColor: AdminColors.purple,
                          ),
                        );
                      }
                    },
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminColors.emerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.bolt_rounded, size: 18),
                    label: const Text('Quét Tự Động Shopee (1-Click)'),
                    onPressed: () async {
                      final count = await admin.autoGenerateSampleShopeePromotions();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('⚡ Đã quét và tự động sinh $count Voucher Shopee mới nhất!'),
                            backgroundColor: AdminColors.emerald,
                          ),
                        );
                      }
                    },
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminColors.primary,
                      foregroundColor: AdminColors.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Tạo Voucher Thủ Công', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _showAddVoucherDialog(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. Tabs: Danh sách Voucher & Lịch Sale
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AdminColors.border)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AdminColors.primary,
              unselectedLabelColor: AdminColors.textSecondary,
              indicatorColor: AdminColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: [
                Tab(
                  child: Row(
                    children: [
                      const Icon(Icons.confirmation_num_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text('Danh Sách Voucher (${admin.vouchers.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text('Lịch Sale Toàn Sàn (${admin.saleEvents.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Tab Contents
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Danh Sách Voucher
                _buildVoucherListTab(context, admin, vouchers),

                // TAB 2: Lịch Sale Toàn Sàn
                _buildSaleEventsTab(context, admin),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherListTab(
    BuildContext context,
    AdminService admin,
    List<VoucherItem> vouchers,
  ) {
    return Column(
      children: [
        // Filter bar
        Row(
          children: [
            Expanded(
              child: TextField(
                style: TextStyle(color: AdminColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Tìm theo mã hoặc tên voucher...',
                  hintStyle: TextStyle(color: AdminColors.textMuted, fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: AdminColors.textMuted),
                  filled: true,
                  fillColor: AdminColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AdminColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AdminColors.border),
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AdminColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AdminColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPlatform,
                  dropdownColor: AdminColors.surfaceLight,
                  style: TextStyle(color: AdminColors.textPrimary, fontSize: 13),
                  items: const [
                    DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả Sàn')),
                    DropdownMenuItem(value: 'Shopee', child: Text('Shopee')),
                    DropdownMenuItem(value: 'Lazada', child: Text('Lazada')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedPlatform = v);
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Voucher Items List
        Expanded(
          child: vouchers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.discount_outlined, size: 48, color: AdminColors.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        'Chưa có voucher nào phù hợp',
                        style: TextStyle(color: AdminColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: vouchers.length,
                  itemBuilder: (context, index) {
                    final item = vouchers[index];
                    return _buildVoucherCard(context, admin, item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildVoucherCard(BuildContext context, AdminService admin, VoucherItem item) {
    final isShopee = item.platform == 'Shopee';
    final platformColor = isShopee ? const Color(0xFFEE4D2D) : const Color(0xFF0F146D);
    final isSending = _sendingPushId == 'voucher_${item.id}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isActive ? AdminColors.border : AdminColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sàn TMĐT icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: platformColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              isShopee ? 'S' : 'L',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: platformColor,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Thông tin voucher
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Code chip
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: item.code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã sao chép mã: ${item.code}'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AdminColors.surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AdminColors.borderSubtle),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.code,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                color: AdminColors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.copy_rounded, size: 14, color: AdminColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: platformColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.platform,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: platformColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AdminColors.surfaceLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.category,
                        style: TextStyle(fontSize: 11, color: AdminColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: item.isActive ? AdminColors.textPrimary : AdminColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Giảm: ${_formatMoney(item.discountAmount)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AdminColors.emerald,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Đơn tối thiểu: ${_formatMoney(item.minOrder)}',
                      style: TextStyle(fontSize: 12, color: AdminColors.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Hạn dùng: ${item.validUntil}',
                      style: TextStyle(fontSize: 12, color: AdminColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Row(
            children: [
              // Bật / Tắt hiển thị
              Tooltip(
                message: item.isActive ? 'Đang hiển thị trên App (Click để tắt)' : 'Đã ẩn khỏi App (Click để bật)',
                child: Switch(
                  value: item.isActive,
                  activeThumbColor: AdminColors.emerald,
                  onChanged: (val) => admin.toggleVoucherActive(item.id),
                ),
              ),
              const SizedBox(width: 8),

              // Bắn Push Notification Trực Tiếp
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.primary.withValues(alpha: 0.15),
                  foregroundColor: AdminColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: AdminColors.primary.withValues(alpha: 0.3)),
                  ),
                ),
                icon: isSending
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AdminColors.primary,
                        ),
                      )
                    : const Icon(Icons.campaign_rounded, size: 16),
                label: Text(
                  isSending ? 'Đang bắn...' : 'Bắn Push',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: isSending ? null : () => _sendVoucherPush(item, admin),
              ),
              const SizedBox(width: 8),

              // Xóa
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AdminColors.rose),
                tooltip: 'Xóa voucher',
                onPressed: () => admin.deleteVoucher(item.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaleEventsTab(BuildContext context, AdminService admin) {
    return ListView.builder(
      itemCount: admin.saleEvents.length,
      itemBuilder: (context, index) {
        final event = admin.saleEvents[index];
        final isSending = _sendingPushId == 'sale_${event.id}';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AdminColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AdminColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AdminColors.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.flash_on_rounded, color: AdminColors.purple, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          event.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AdminColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (event.confirmed)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AdminColors.emerald.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Đã xác nhận',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AdminColors.emerald,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.highlight,
                      style: TextStyle(fontSize: 13, color: AdminColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 13, color: AdminColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          'Ngày diễn ra: ${event.date}',
                          style: TextStyle(fontSize: 12, color: AdminColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.purple.withValues(alpha: 0.15),
                  foregroundColor: AdminColors.purple,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: AdminColors.purple.withValues(alpha: 0.3)),
                  ),
                ),
                icon: isSending
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AdminColors.purple,
                        ),
                      )
                    : const Icon(Icons.notifications_active_rounded, size: 16),
                label: Text(
                  isSending ? 'Đang bắn...' : 'Bắn Nhắc Đợt Sale',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: isSending ? null : () => _sendSaleEventPush(event, admin),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _formatMoney(int amount) {
    if (amount <= 0) return '0đ';
    final str = amount.toString();
    final buffer = StringBuffer();
    var count = 0;
    for (var i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) buffer.write('.');
    }
    return '${buffer.toString().split('').reversed.join('')} đ';
  }
}
