import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_semantic_colors.dart';
import '../viewmodels/auth_viewmodel.dart';
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

  static const int _pageCount = 1;

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
    final route = context.read<AuthViewModel>().isAuthenticated
        ? AppRoutes.shell
        : AppRoutes.login;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Logo & Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const WhyIBuyLogo(size: 36, color: AppColors.onPrimary),
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
                  ),
                ],
              ),
            ),

            // Main Carousel Slider
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const NeverScrollableScrollPhysics(),
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
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Bắt đầu trải nghiệm',
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

                  const SizedBox(height: 14),

                  // Privacy / Local Data note
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 14,
                        color: AppSemanticColors.of(context).subtleText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Dữ liệu an toàn • Không phán xét chi tiêu',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppSemanticColors.of(context).subtleText,
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

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // Visual illustration card
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppSemanticColors.of(context).onboardingGradientStart,
                  AppSemanticColors.of(context).onboardingGradientEnd,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.55),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppSemanticColors.of(context).illustrationShadow,
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 136,
                      height: 136,
                      decoration: BoxDecoration(
                        color: AppSemanticColors.of(context)
                            .illustrationSurface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppSemanticColors.of(context)
                                .illustrationBadgeShadow,
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: AppSemanticColors.of(context)
                                .illustrationInset,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.spa_rounded,
                            size: 52,
                            color: AppSemanticColors.of(context).emphasis,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -8,
                      bottom: -2,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppSemanticColors.of(context)
                              .illustrationBadge,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppSemanticColors.of(context)
                                .illustrationBadgeBorder,
                            width: 3,
                          ),
                        ),
                        child: Icon(
                          Icons.self_improvement_rounded,
                          size: 20,
                          color: AppSemanticColors.of(context).onSelectedChip,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Overline Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppSemanticColors.of(context).primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'DÀNH RIÊNG CHO BẠN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: AppSemanticColors.of(context).emphasis,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Slide Title
          Text(
            'Why I Buy?',
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
            'Tiền bạc không chỉ là những con số. Quan sát động cơ tiêu dùng của chính mình để thay đổi nhẹ nhàng hơn.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          _buildOnboardingBenefit(
            context,
            icon: Icons.schedule_rounded,
            title: 'Ghi lại lý do mua',
            description: 'Ghi lại món đồ và lý do khiến bạn mua.',
          ),
          const SizedBox(height: 8),
          _buildOnboardingBenefit(
            context,
            icon: Icons.insights_outlined,
            title: 'Nhận ra mô hình chi tiêu',
            description: 'Nhìn lại động cơ và thời điểm ghi khoản mua.',
          ),
          const SizedBox(height: 8),
          _buildOnboardingBenefit(
            context,
            icon: Icons.psychology_alt_outlined,
            title: 'Hiểu mình, không phán xét',
            description: 'Nhận diện cảm xúc, hiểu trước khi thay đổi.',
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingBenefit(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: AppSemanticColors.of(context).cardSurface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: AppSemanticColors.of(context).onboardingBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: AppSemanticColors.of(context).budgetCardShadow5,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppSemanticColors.of(context).primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 19,
              color: AppSemanticColors.of(context).emphasis,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.3,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SLIDE 2: COOLING-OFF ====================
  Widget _buildSecondSlide(BuildContext context) {
    final theme = Theme.of(context);

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
              color: AppSemanticColors.of(context).cardSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.dividerColor),
              boxShadow: [
                BoxShadow(
                  color: AppSemanticColors.of(context).previewShadow,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppSemanticColors.of(context).mutedSurface,
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
                                color: AppSemanticColors.of(context).infoText,
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
                          color: AppSemanticColors.of(context).infoContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '1.200.000 đ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppSemanticColors.of(context)
                                .onInfoContainer,
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
                      context: context,
                      icon: Icons.check_circle_outline,
                      label: 'Mua khi cần',
                      color: AppSemanticColors.of(context).success,
                    ),
                    const SizedBox(width: 12),
                    _buildDecisionBadge(
                      context: context,
                      icon: Icons.remove_circle_outline,
                      label: 'Bỏ qua khi hết hứng',
                      color: AppSemanticColors.of(context).accent,
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
              color: AppSemanticColors.of(context).infoContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'LÀM NGUỘI CẢM XÚC (72 GIỜ)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: AppSemanticColors.of(context).onInfoContainer,
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
              color: AppSemanticColors.of(context).cardSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.dividerColor),
              boxShadow: [
                BoxShadow(
                  color: AppSemanticColors.of(context).previewShadow,
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
                          color: AppSemanticColors.of(context).accent,
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
                        color: AppSemanticColors.of(context).successContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Trong hạn mức',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppSemanticColors.of(context)
                              .onSuccessContainer,
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
                    backgroundColor: AppSemanticColors.of(context).mutedSurface,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 16),

                // AI Insight card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppSemanticColors.of(context).aiContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: AppSemanticColors.of(context).aiAccent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tuần này bạn tiết kiệm được 35% nhờ trì hoãn mua sắm bốc đồng lúc đêm muộn.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                            color: AppSemanticColors.of(context).onAiContainer,
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
              color: AppSemanticColors.of(context).successContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'LÀM CHỦ DÒNG TIỀN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: AppSemanticColors.of(context).onSuccessContainer,
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

  // Helper widget for decision badge
  Widget _buildDecisionBadge({
    required IconData icon,
    required String label,
    required Color color,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: AppSemanticColors.of(context).statusOverlay.a,
        ),
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
