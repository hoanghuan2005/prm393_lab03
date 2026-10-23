import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/why_i_buy_logo.dart';
import 'main_navigation_screen.dart';

/// Screen 01: Onboarding from Figma "Why I Buy ver2"
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Logo container
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFCE6), // Soft yellow container
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: WhyIBuyLogo(size: 48, color: AppColors.onPrimary),
                ),
              ),

              const SizedBox(height: 28),

              // Subtitle overline
              const Text(
                'NHẬT KÝ ĐỘNG CƠ MUA SẮM',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Color(0xFF47667B),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Main Title
              const Text(
                'Why I Buy?',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onPrimary,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Description
              const Text(
                'Ghi lại lý do của mỗi khoản mua để hiểu thói quen chi tiêu của chính bạn. Không chấm điểm, không phán xét.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Color(0xFF6D6E73),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // 3 Features Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildFeatureRow(
                      icon: Icons.add_circle_outline,
                      text: 'Ghi số tiền, tên món và động cơ của mỗi khoản mua.',
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(color: Color(0xFFF3F4F6), height: 1),
                    ),
                    _buildFeatureRow(
                      icon: Icons.bar_chart_rounded,
                      text: 'Xem động cơ và khung giờ mua theo tuần, theo tháng.',
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(color: Color(0xFFF3F4F6), height: 1),
                    ),
                    _buildFeatureRow(
                      icon: Icons.lightbulb_outline_rounded,
                      text: 'Đọc các quan sát rút ra từ chính dữ liệu bạn ghi.',
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Yellow Action Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const MainNavigationScreen(),
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Bắt đầu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Footer Note
              const Text(
                'Dữ liệu được lưu trên máy của bạn.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFF47667B),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AppColors.onPrimary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
