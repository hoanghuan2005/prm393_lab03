import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../models/buying_motive.dart';
import '../theme/app_colors.dart';
import '../widgets/why_i_buy_logo.dart';

/// Screen 01: Onboarding / Landing Redesign for "Why I Buy"
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const int _pageCount = 3;

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _nextPage() {
    if (_currentPage < _pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    Navigator.pushReplacementNamed(context, AppRoutes.shell);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Logo & Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2C2706)
                              : AppColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: WhyIBuyLogo(
                          size: 20,
                          color: isDark ? AppColors.primary : AppColors.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Why I Buy?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  if (_currentPage < _pageCount - 1)
                    TextButton(
                      onPressed: _finishOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurfaceVariant,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                      ),
                      child: const Text(
                        'Bỏ qua',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 36),
                ],
              ),
            ),

            // Main Carousel Slider
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: [
                  _buildFirstSlide(context),
                  _buildSecondSlide(context),
                  _buildThirdSlide(context),
                ],
              ),
            ),

            // Bottom Navigation & Actions Area
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                children: [
                  // Smooth Indicator Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pageCount, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 7,
                        width: isActive ? 24 : 7,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary
                              : (isDark
                                  ? const Color(0xFF333B49)
                                  : AppColors.outline),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 24),

                  // Action Button
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
                      onPressed: _nextPage,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == _pageCount - 1
                                ? 'Bắt đầu trải nghiệm'
                                : 'Tiếp tục',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Privacy / Local Data note
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Dữ liệu an toàn • Không phán xét chi tiêu',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== SLIDE 1: MOTIVES ====================
  Widget _buildFirstSlide(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Visual illustration card
          Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B202A) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.dividerColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Soft glow circle in the center
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.2),
                  ),
                ),
                // Center Icon Logo
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: WhyIBuyLogo(size: 40, color: AppColors.onPrimary),
                  ),
                ),

                // Motive Badge 1: Nhu cầu (Top Left)
                Positioned(
                  top: 24,
                  left: 20,
                  child: _buildFloatingBadge(
                    icon: BuyingMotive.need.icon,
                    label: BuyingMotive.need.label,
                    bgColor: isDark ? const Color(0xFF1E1E38) : AppColors.motiveNeedBg,
                    fgColor: isDark ? const Color(0xFF818CF8) : AppColors.motiveNeed,
                  ),
                ),

                // Motive Badge 2: Cảm xúc (Top Right)
                Positioned(
                  top: 24,
                  right: 20,
                  child: _buildFloatingBadge(
                    icon: BuyingMotive.emotion.icon,
                    label: BuyingMotive.emotion.label,
                    bgColor: isDark ? const Color(0xFF2E1E38) : AppColors.motiveEmotionBg,
                    fgColor: isDark ? const Color(0xFFA78BFA) : AppColors.motiveEmotion,
                  ),
                ),

                // Motive Badge 3: Khuyến mãi (Bottom Left)
                Positioned(
                  bottom: 24,
                  left: 20,
                  child: _buildFloatingBadge(
                    icon: BuyingMotive.sale.icon,
                    label: BuyingMotive.sale.label,
                    bgColor: isDark ? const Color(0xFF382D1E) : AppColors.motiveSaleBg,
                    fgColor: isDark ? const Color(0xFFFBBF24) : AppColors.motiveSale,
                  ),
                ),

                // Motive Badge 4: Tiện lợi (Bottom Right)
                Positioned(
                  bottom: 24,
                  right: 20,
                  child: _buildFloatingBadge(
                    icon: BuyingMotive.convenience.icon,
                    label: BuyingMotive.convenience.label,
                    bgColor: isDark ? const Color(0xFF1E3834) : AppColors.motiveConvenienceBg,
                    fgColor: isDark ? const Color(0xFF2DD4BF) : AppColors.motiveConvenience,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Overline Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2706) : AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'THẤU HIỂU ĐỘNG CƠ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: isDark ? AppColors.primary : AppColors.onPrimary,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Slide Title
          Text(
            'Hiểu rõ lý do chi tiêu',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10),

          // Description
          Text(
            'Mỗi khoản mua đều xuất phát từ một lý do: Nhu cầu thiết yếu, Cảm xúc nhất thời hay Đợt sale hấp dẫn. Ghi nhận để hiểu chính mình, không hề phán xét.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==================== SLIDE 2: COOLING-OFF ====================
  Widget _buildSecondSlide(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Visual illustration card
          Container(
            height: 240,
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B202A) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.dividerColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Wishlist sample item
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF252D3C) : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.hourglass_top_rounded,
                          size: 20,
                          color: AppColors.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tai nghe chống ồn',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Đang làm nguội · 3 ngày',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFF60A5FA)
                                    : const Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E2838)
                              : const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '1.200.000 đ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFF93C5FD)
                                : const Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Decision pills
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDecisionBadge(
                      icon: Icons.check_circle_outline,
                      label: 'Mua khi cần',
                      color: AppColors.success,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 12),
                    _buildDecisionBadge(
                      icon: Icons.remove_circle_outline,
                      label: 'Bỏ qua khi hết hứng',
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : AppColors.accentNeutral,
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Overline Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2838) : const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'LÀM NGUỘI CẢM XÚC (72 GIỜ)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Slide Title
          Text(
            'Hoãn mua để suy ngẫm',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10),

          // Description
          Text(
            'Khi muốn mua một món đồ, hãy đưa vào danh sách chờ. Sau vài ngày hạ nhiệt, bạn sẽ bất ngờ nhận ra mình thực sự cần hay chỉ là cảm xúc nhất thời.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==================== SLIDE 3: INSIGHTS & BUDGET ====================
  Widget _buildThirdSlide(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Visual illustration card
          Container(
            height: 240,
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B202A) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.dividerColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Monthly Budget Preview Card
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 18,
                          color: isDark ? AppColors.primary : AppColors.accentNeutral,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ngân sách tháng',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF064E3B)
                            : AppColors.successContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Trong hạn mức',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFF6EE7B7)
                              : AppColors.onSuccessContainer,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.38,
                    minHeight: 6,
                    backgroundColor: isDark
                        ? const Color(0xFF262D3B)
                        : AppColors.surfaceVariant,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 16),

                // AI Insight card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2C2706)
                        : AppColors.aiContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: isDark ? AppColors.primary : AppColors.aiAccent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tuần này bạn tiết kiệm được 35% nhờ trì hoãn mua sắm bốc đồng lúc đêm muộn.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                            color: isDark
                                ? const Color(0xFFFEF3C7)
                                : AppColors.onAiContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Overline Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF064E3B) : AppColors.successContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'LÀM CHỦ DÒNG TIỀN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: isDark ? const Color(0xFF6EE7B7) : AppColors.onSuccessContainer,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Slide Title
          Text(
            'Chiêm nghiệm & Tự do',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10),

          // Description
          Text(
            'Theo dõi mô hình chi tiêu theo thời gian và động cơ. Rút ra quy luật từ chính số liệu của bạn để kiểm soát chi tiêu mà vẫn tận hưởng trọn vẹn cuộc sống.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper widget for decorative badge
  Widget _buildFloatingBadge({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color fgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fgColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for decision badge
  Widget _buildDecisionBadge({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
