import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/why_i_buy_logo.dart';

/// Screen 08: Góc nhìn from Figma "Why I Buy ver2"
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: const Row(
          children: [
            WhyIBuyLogo(size: 26, color: AppColors.onPrimary),
            SizedBox(width: 8),
            Text(
              'Góc nhìn',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.onPrimary,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner introducing mindfulness
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFCE6), Color(0xFFFEF3C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFFD97706), size: 28),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quan sát từ dữ liệu của bạn',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Không phán xét, không chấm điểm. Đây là những mô hình chi tiêu tự nhiên được ghi nhận tuần này.',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF47667B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Observation Card 1: Mua sắm nửa đêm
          _buildInsightCard(
            title: 'Khung giờ nhạy cảm: Nửa đêm',
            tag: 'Khuyến mãi • 23:40',
            tagColor: const Color(0xFFD97706),
            tagBg: const Color(0xFFFEF3C7),
            content:
                'Khoản chi lớn nhất tuần là Tai nghe Bluetooth (389.000 ₫) vào lúc 23:40. Nghiên cứu tâm lý hành vi cho thấy sau 22h, thùy trán giảm khả năng ức chế xung lực, dễ kích hoạt hành vi săn sale nhanh.',
            recommendation: 'Thử nghiệm: Đặt quy tắc "Thêm vào Wishlist và chờ đến 9h sáng hôm sau".',
            icon: Icons.nightlight_round,
            iconColor: const Color(0xFF6366F1),
          ),

          const SizedBox(height: 16),

          // Observation Card 2: 40% do Khuyến mãi
          _buildInsightCard(
            title: 'Động cơ chính: Khuyến mãi (40%)',
            tag: '2/5 khoản mua',
            tagColor: const Color(0xFF0284C7),
            tagBg: const Color(0xFFE0F2FE),
            content:
                'Bạn đã chi 589.000 ₫ tuần này xuất phát từ động cơ giảm giá hoặc ưu đãi tặng kèm. Hãy tự hỏi: "Nếu món này giữ nguyên giá gốc, mình có chủ động tìm mua không?".',
            recommendation: 'Mẹo: Bạn tiết kiệm được 100% nếu không mua món đồ giảm giá 50%.',
            icon: Icons.local_offer_outlined,
            iconColor: const Color(0xFFD97706),
          ),

          const SizedBox(height: 16),

          // Observation Card 3: Chi tiêu cảm xúc
          _buildInsightCard(
            title: 'Khoản chi xoa dịu cảm xúc',
            tag: 'Trà sữa nướng • 45.000 ₫',
            tagColor: const Color(0xFF7C3AED),
            tagBg: const Color(0xFFEDE9FE),
            content:
                'Ghi nhận: "Buồn vì công việc nên muốn uống gì ngọt". Mua sắm để tự thưởng hoặc giải tỏa là hoàn toàn bình thường khi bạn có chủ đích và nhận thức rõ động cơ.',
            recommendation: 'Tốt lắm! Bạn đã trung thực nhận diện cảm xúc thay vì tự lừa dối đó là "nhu cầu".',
            icon: Icons.sentiment_satisfied_alt_rounded,
            iconColor: const Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String tag,
    required Color tagColor,
    required Color tagBg,
    required String content,
    required String recommendation,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tagBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: tagColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF3F4F6)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_rounded, size: 16, color: Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recommendation,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF47667B),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
