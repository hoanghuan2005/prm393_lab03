import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/admin_service.dart';
import '../models/admin_models.dart';
import '../theme/admin_colors.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _promptController = TextEditingController();
  bool _isGenerating = false;
  AiSuggestion? _customResult;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _generateCustom() async {
    final query = _promptController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isGenerating = true);
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
    setState(() {
      _isGenerating = false;
      _customResult = AiSuggestion(
        id: 'ai_custom',
        category: 'custom',
        categoryLabel: 'Tạo riêng cho: "$query"',
        question: 'Sau khi sở hữu món đồ "$query", cuộc sống của bạn sẽ thay đổi tích cực ở điểm nào cụ thể nhất?',
        psychologyInsight: 'Kích thích tư duy hình dung tương lai (Future Visualization). Nếu người dùng không thể nêu ra 1 điểm cụ thể, khả năng cao đây là ham muốn bốc đồng.',
        suggestedTitle: '💡 Tự hỏi bản thân trước khi chốt đơn "$query"',
        suggestedBody: 'Món đồ này mang lại giá trị sử dụng lâu dài hay chỉ là cảm xúc thỏa mãn nhất thời? Hãy dành 24 giờ để kiểm chứng nhé!',
        targetScreen: 'wishlist_add',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminService>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner (Flat, No Gradient, Fully Responsive)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AdminColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AdminColors.border),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 700;

                final textSection = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AdminColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.psychology_rounded, size: 14, color: AdminColors.primary),
                          SizedBox(width: 4),
                          Text('GEMINI AI BEHAVIORAL FINANCE ENGINE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AdminColors.primary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'AI Gợi Ý Câu Hỏi Tự Vấn (Next Question) & Thông Điệp Đồng Cảm',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AdminColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Dựa trên triết lý Why I Buy: Không phán xét hay ngăn cản, mà đồng hành cùng người dùng bằng những câu hỏi gợi mở để kích hoạt tư duy phản biện trước khi mua sắm.',
                      style: TextStyle(fontSize: 12, color: AdminColors.textSecondary, height: 1.4),
                    ),
                  ],
                );

                final badgeSection = Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AdminColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: Column(
                    children: [
                      Text('Mô hình tích hợp', style: TextStyle(fontSize: 11, color: AdminColors.textSecondary)),
                      const SizedBox(height: 4),
                      const Text('Gemini 1.5 Flash', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AdminColors.primary)),
                      const SizedBox(height: 2),
                      const Text('Tương tác: +42%', style: TextStyle(fontSize: 10, color: AdminColors.emerald, fontWeight: FontWeight.w700)),
                    ],
                  ),
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      textSection,
                      const SizedBox(height: 16),
                      badgeSection,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: textSection),
                    const SizedBox(width: 20),
                    badgeSection,
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Custom Prompt Input (Responsive)
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
                    const Icon(Icons.auto_awesome_rounded, size: 18, color: AdminColors.primary),
                    const SizedBox(width: 8),
                    Text('TẠO CÂU HỎI & THÔNG ĐIỆP THEO NGỮ CẢNH TÙY CHỌN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AdminColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;

                    final textField = TextField(
                      controller: _promptController,
                      style: TextStyle(fontSize: 13, color: AdminColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Ví dụ: Giày thể thao hàng hiệu, Trà sữa mỗi ngày, Đồ công nghệ mùa sale...',
                        hintStyle: TextStyle(fontSize: 13, color: AdminColors.textSecondary),
                        filled: true,
                        fillColor: AdminColors.surfaceLight,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AdminColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AdminColors.border)),
                        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AdminColors.primary, width: 1.5)),
                      ),
                    );

                    final submitButton = ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminColors.primary,
                        foregroundColor: AdminColors.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isGenerating ? null : _generateCustom,
                      icon: _isGenerating
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AdminColors.onPrimary))
                          : const Icon(Icons.flash_on_rounded, size: 16),
                      label: Text(
                        _isGenerating ? 'AI đang suy nghĩ...' : 'Tạo Gợi Ý Thông Minh',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                    );

                    if (isNarrow) {
                      return Column(
                        children: [
                          textField,
                          const SizedBox(height: 10),
                          SizedBox(width: double.infinity, child: submitButton),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: textField),
                        const SizedBox(width: 12),
                        submitButton,
                      ],
                    );
                  },
                ),

                if (_customResult != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AdminColors.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AdminColors.primary.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: AdminColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                              child: const Text('KẾT QUẢ VỪA TẠO BỞI AI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AdminColors.primary)),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AdminColors.primary,
                                foregroundColor: AdminColors.onPrimary,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => admin.applyAiSuggestionToPush(_customResult!),
                              icon: const Icon(Icons.campaign_rounded, size: 12),
                              label: const Text('Áp dụng vào Push Notification', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text('"${_customResult!.question}"', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AdminColors.textPrimary)),
                        const SizedBox(height: 8),
                        Text('Tâm lý học hành vi: ${_customResult!.psychologyInsight}', style: TextStyle(fontSize: 11, color: AdminColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Default AI Questions Grid (Responsive)
          Text('DANH SÁCH CÂU HỎI TỰ VẤN GỢI Ý', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AdminColors.textSecondary)),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 800 ? 2 : 1;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 220,
                ),
                itemCount: admin.aiSuggestions.length,
                itemBuilder: (context, index) {
                  final item = admin.aiSuggestions[index];
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AdminColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AdminColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AdminColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.categoryLabel,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AdminColors.primary),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '"${item.question}"',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AdminColors.textPrimary, height: 1.3),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.psychologyInsight,
                              style: TextStyle(fontSize: 11, color: AdminColors.textSecondary, height: 1.3),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminColors.surfaceLight,
                            foregroundColor: AdminColors.textPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => admin.applyAiSuggestionToPush(item),
                          icon: const Icon(Icons.campaign_rounded, size: 12, color: AdminColors.primary),
                          label: const Text('Gửi thông điệp này cho user', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
