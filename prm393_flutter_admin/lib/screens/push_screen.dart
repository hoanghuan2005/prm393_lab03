import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/admin_service.dart';
import '../theme/admin_colors.dart';

class PushScreen extends StatefulWidget {
  const PushScreen({super.key});

  @override
  State<PushScreen> createState() => _PushScreenState();
}

class _PushScreenState extends State<PushScreen> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  String _targetAudience = 'dormant';
  String _targetScreen = 'wishlist_add';
  bool _isSending = false;
  bool _showSuccessToast = false;

  @override
  void initState() {
    super.initState();
    final admin = context.read<AdminService>();
    _titleController = TextEditingController(text: admin.draftTitle);
    _bodyController = TextEditingController(text: admin.draftBody);
    _targetAudience = admin.draftTarget;
    _targetScreen = admin.draftScreen;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _applyQuickTemplate(String type) {
    setState(() {
      if (type == 'dormant') {
        _titleController.text = '👋 Bạn đã thử chia sẻ link mua sắm vào Why I Buy chưa?';
        _bodyController.text = 'Chỉ cần bấm Chia sẻ từ Shopee hoặc Lazada -> chọn Why I Buy, bạn sẽ có ngay 48 giờ để cân nhắc trước khi chốt đơn!';
        _targetAudience = 'dormant';
        _targetScreen = 'wishlist_add';
      } else if (type == 'late_night') {
        _titleController.text = '🌙 Đêm khuya rồi, hãy để giỏ hàng nghỉ ngơi nhé';
        _bodyController.text = 'Nhiều quyết định chi tiêu cảm xúc thường xuất hiện sau 22h. Hãy ngủ một giấc thật ngon và xem lại vào sáng mai!';
        _targetAudience = 'all';
        _targetScreen = 'wishlist';
      } else if (type == 'weekend') {
        _titleController.text = '📊 Cuối tuần thảnh thơi: Cùng nhìn lại chi tiêu tuần qua';
        _bodyController.text = 'Mở tab Mô Hình để xem bạn đã giữ vững cam kết tài chính như thế nào trong 7 ngày vừa rồi nhé.';
        _targetAudience = 'active_today';
        _targetScreen = 'patterns';
      }
    });
  }

  Future<void> _handleSend() async {
    final admin = context.read<AdminService>();
    if (_targetAudience == 'specific' && admin.preselectedUser == null) return;
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) return;

    setState(() => _isSending = true);
    try {
      await admin.sendBroadcast(
        title: title,
        body: body,
        targetAudience: _targetAudience,
        targetScreen: _targetScreen,
      );
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _showSuccessToast = true;
        _titleController.clear();
        _bodyController.clear();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể gửi thông báo: $error')),
      );
    }

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showSuccessToast = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminService>();
    final hasValidAudience =
        _targetAudience != 'specific' || admin.preselectedUser != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success Toast
          if (_showSuccessToast) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AdminColors.emerald,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: AdminColors.onPrimary, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Thông điệp Push Notification đã được phát thành công đến người dùng!',
                      style: TextStyle(fontWeight: FontWeight.w800, color: AdminColors.onPrimary, fontSize: 13),
                    ),
                  ),
                  Text('ĐÃ GỬI & LƯU FIRESTORE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AdminColors.onPrimary)),
                ],
              ),
            ),
          ],

          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 900;

              final formWidget = Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AdminColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AdminColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SOẠN THÔNG ĐIỆP PUSH NOTIFICATION',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AdminColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Phát thông báo đẩy đến người dùng',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AdminColors.textPrimary),
                              ),
                            ],
                          ),
                          if (admin.preselectedUser != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AdminColors.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AdminColors.primary),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Gửi riêng: ${admin.preselectedUser!.displayName}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AdminColors.primary),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () => admin.clearPreselectedUser(),
                                    child: Icon(Icons.close, size: 14, color: AdminColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // AI 1-Click Templates
                      Text(
                        'Gợi ý mẫu thông điệp kích hoạt thông minh (1-Click):',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTemplateBtn(
                              '👋 Kích hoạt User Chưa Dùng',
                              'dormant',
                              AdminColors.purple,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTemplateBtn(
                              '🌙 Cân Nhắc Đêm Khuya',
                              'late_night',
                              AdminColors.amber,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTemplateBtn(
                              '📊 Tổng Kết Cuối Tuần',
                              'weekend',
                              AdminColors.blue,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Target Audience Dropdown
                      Text('Nhóm đối tượng nhận thông báo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.textPrimary)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AdminColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AdminColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: hasValidAudience ? _targetAudience : null,
                            hint: const Text('Chọn đối tượng nhận thông báo'),
                            isExpanded: true,
                            dropdownColor: AdminColors.surface,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            onChanged: (val) {
                              if (val != null) setState(() => _targetAudience = val);
                            },
                            items: [
                              DropdownMenuItem(value: 'dormant', child: Text('Tải app nhưng chưa dùng (${admin.metrics.dormantUsers} người)')),
                              DropdownMenuItem(value: 'active_today', child: Text('Đang hoạt động hôm nay (DAU: ${admin.metrics.activeUsersToday} người)')),
                              DropdownMenuItem(value: 'all', child: Text('Tất cả người dùng (${admin.metrics.totalUsers} người)')),
                              if (admin.preselectedUser != null)
                                DropdownMenuItem(value: 'specific', child: Text('Người dùng: ${admin.preselectedUser!.displayName}')),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Title input
                      Text('Tiêu đề thông báo (Push Title)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.textPrimary)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _titleController,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(color: AdminColors.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Nhập tiêu đề hấp dẫn, ngắn gọn...',
                          hintStyle: TextStyle(color: AdminColors.textSecondary, fontSize: 13),
                          filled: true,
                          fillColor: AdminColors.surfaceLight,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AdminColors.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AdminColors.border)),
                          focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AdminColors.primary, width: 1.5)),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Body input
                      Text('Nội dung thông điệp (Push Body)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.textPrimary)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _bodyController,
                        onChanged: (_) => setState(() {}),
                        maxLines: 3,
                        style: TextStyle(color: AdminColors.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Nhập thông điệp ấm áp, đồng cảm, gợi mở tư duy chi tiêu có trách nhiệm...',
                          hintStyle: TextStyle(color: AdminColors.textSecondary, fontSize: 13),
                          filled: true,
                          fillColor: AdminColors.surfaceLight,
                          contentPadding: const EdgeInsets.all(14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AdminColors.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AdminColors.border)),
                          focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AdminColors.primary, width: 1.5)),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Target Screen
                      Text('Màn hình đích khi chạm vào thông báo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.textPrimary)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AdminColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AdminColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _targetScreen,
                            isExpanded: true,
                            dropdownColor: AdminColors.surface,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            onChanged: (val) {
                              if (val != null) setState(() => _targetScreen = val);
                            },
                            items: const [
                              DropdownMenuItem(value: 'wishlist_add', child: Text('Màn hình Thêm món cân nhắc (AddItemScreen)')),
                              DropdownMenuItem(value: 'wishlist', child: Text('Màn hình Danh sách cân nhắc (WishlistScreen)')),
                              DropdownMenuItem(value: 'patterns', child: Text('Màn hình Mô hình chi tiêu (PatternsScreen)')),
                              DropdownMenuItem(value: 'insights', child: Text('Màn hình Góc nhìn AI (InsightsScreen)')),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminColors.primary,
                            foregroundColor: AdminColors.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isSending || !hasValidAudience ? null : _handleSend,
                          icon: _isSending
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AdminColors.onPrimary))
                              : const Icon(Icons.campaign_rounded, size: 18),
                          label: Text(
                            _isSending ? 'Đang gửi thông điệp...' : 'Bắn Thông Báo Push Ngay Bây Giờ',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                );

              final previewWidget = Column(
                children: [
                  // Phone Notification Mockup Preview
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AdminColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AdminColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.phone_android_rounded, size: 18, color: AdminColors.primary),
                            const SizedBox(width: 8),
                            Text('XEM TRƯỚC TRÊN ĐIỆN THOẠI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AdminColors.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AdminColors.background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AdminColors.borderSubtle),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(color: AdminColors.primary, borderRadius: BorderRadius.circular(4)),
                                        alignment: Alignment.center,
                                        child: const Text('W', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AdminColors.onPrimary)),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('Why I Buy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AdminColors.textPrimary)),
                                    ],
                                  ),
                                  Text('Bây giờ', style: TextStyle(fontSize: 10, color: AdminColors.textSecondary)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _titleController.text.isNotEmpty ? _titleController.text : 'Tiêu đề thông báo...',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AdminColors.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _bodyController.text.isNotEmpty ? _bodyController.text : 'Nội dung thông điệp người dùng nhận được...',
                                style: TextStyle(fontSize: 11, color: AdminColors.textSecondary, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // History Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AdminColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AdminColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('LỊCH SỬ THÔNG BÁO ĐÃ GỬI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AdminColors.textSecondary)),
                            Icon(Icons.history_rounded, size: 18, color: AdminColors.textSecondary),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: admin.broadcasts.length,
                          separatorBuilder: (_, _) => Divider(color: AdminColors.border, height: 16),
                          itemBuilder: (context, index) {
                            final bc = admin.broadcasts[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        bc.title,
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.textPrimary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: AdminColors.emerald.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                                      child: Text('Mở: ${bc.openRate}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AdminColors.emerald)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(bc.body, style: TextStyle(fontSize: 11, color: AdminColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text('Đã phát: ${bc.deliveredCount} thiết bị • ${bc.sentAt}', style: TextStyle(fontSize: 10, color: AdminColors.textMuted)),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  children: [
                    formWidget,
                    const SizedBox(height: 24),
                    previewWidget,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: formWidget),
                  const SizedBox(width: 24),
                  Expanded(flex: 4, child: previewWidget),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateBtn(String title, String type, Color color) {
    return InkWell(
      onTap: () => _applyQuickTemplate(type),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          title,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
