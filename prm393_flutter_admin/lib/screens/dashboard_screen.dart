import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/admin_service.dart';
import '../theme/admin_colors.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _formatVnd(int amount) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminService>();
    final metrics = admin.metrics;
    final activeCrashes = admin.crashes.where((c) => !c.isResolved).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Crash Alert Banner (Flat, No Gradient, Fully Responsive)
          if (activeCrashes.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AdminColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AdminColors.rose.withValues(alpha: 0.35)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 700;

                  final alertContent = Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AdminColors.rose.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.error_outline_rounded, color: AdminColors.rose, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'Cảnh báo: Có ${activeCrashes.length} tính năng bị crash trong phiên bản gần nhất!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AdminColors.textPrimary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AdminColors.rose,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'ƯU TIÊN CAO',
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Chức năng: ${activeCrashes.map((c) => c.feature).join(' • ')} (Gây ảnh hưởng ${activeCrashes.fold(0, (acc, c) => acc + c.affectedUsers)} thiết bị).',
                              style: TextStyle(fontSize: 12, color: AdminColors.rose.withValues(alpha: 0.9)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  final actionButton = ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminColors.rose,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => admin.selectTab(4), // Jump to Crashes Tab
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: const Text('Xem & Sửa ngay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  );

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        alertContent,
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: actionButton,
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: alertContent),
                      const SizedBox(width: 16),
                      actionButton,
                    ],
                  );
                },
              ),
            ),
          ],

          // 2. Core 4 Metrics Cards (Guaranteed mainAxisExtent, never overflows bottom)
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 4;
              double mainAxisExtent = 140;

              if (constraints.maxWidth > 1050) {
                crossAxisCount = 4;
                mainAxisExtent = 140;
              } else if (constraints.maxWidth > 520) {
                crossAxisCount = 2;
                mainAxisExtent = 145;
              } else {
                crossAxisCount = 1;
                mainAxisExtent = 135;
              }

              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: mainAxisExtent,
                ),
                itemCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return StatCard(
                      title: 'User Mới Hôm Nay',
                      value: '+${metrics.newUsersToday}',
                      subtitle: 'Tài khoản đăng ký mới',
                      icon: Icons.person_add_rounded,
                      accentColor: AdminColors.emerald,
                      trendText: '+24.5%',
                      isTrendPositive: true,
                      onTap: () => admin.selectTab(1),
                    );
                  } else if (index == 1) {
                    return StatCard(
                      title: 'Active Users (DAU)',
                      value: '${metrics.activeUsersToday}',
                      subtitle: '${((metrics.activeUsersToday / metrics.totalUsers) * 100).toStringAsFixed(1)}% trên tổng ${metrics.totalUsers} users',
                      icon: Icons.bolt_rounded,
                      accentColor: AdminColors.amber,
                      trendText: '+12.8%',
                      isTrendPositive: true,
                      onTap: () => admin.selectTab(1),
                    );
                  } else if (index == 2) {
                    return StatCard(
                      title: 'Tải App Nhưng Chưa Dùng',
                      value: '${metrics.dormantUsers}',
                      subtitle: '0 món cân nhắc, 0 chi tiêu',
                      icon: Icons.person_off_rounded,
                      accentColor: AdminColors.purple,
                      trendText: 'Cần kích hoạt',
                      isTrendPositive: false,
                      onTap: () => admin.selectTab(1),
                    );
                  } else {
                    return StatCard(
                      title: 'Tổng Chi Tiêu Đã Ghi',
                      value: _formatVnd(metrics.totalSpendingVnd),
                      subtitle: '${metrics.totalWishlistItems} món đang cân nhắc',
                      icon: Icons.attach_money_rounded,
                      accentColor: AdminColors.blue,
                      trendText: '+18.2%',
                      isTrendPositive: true,
                    );
                  }
                },
              );
            },
          ),

          const SizedBox(height: 24),

          // 3. Growth Callout for Dormant Users (Flat, No Gradient, Responsive)
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AdminColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AdminColors.purple.withValues(alpha: 0.35)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 750;

                final textSection = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AdminColors.purple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AdminColors.purple.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 14, color: AdminColors.purple),
                          SizedBox(width: 4),
                          Text(
                            'CƠ HỘI TĂNG TRƯỞNG (GROWTH OPPORTUNITY)',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AdminColors.purple),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Có ${metrics.dormantUsers} người dùng tải app nhưng chưa thêm món đồ nào',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Họ có thể thấy ngại việc nhập liệu thủ công. Hãy gửi thông báo Push giới thiệu tính năng "Chia sẻ link từ Shopee / Lazada" chỉ với 1 chạm để kích hoạt họ trải nghiệm ngay!',
                      style: TextStyle(fontSize: 12, color: AdminColors.textSecondary, height: 1.4),
                    ),
                  ],
                );

                final actionButtons = Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: isNarrow ? WrapAlignment.start : WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminColors.primary,
                        foregroundColor: AdminColors.onPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        admin.draftTarget = 'dormant';
                        admin.draftTitle = '👋 Bạn đã thử chia sẻ link mua sắm vào Why I Buy chưa?';
                        admin.draftBody = 'Bấm Chia sẻ từ Shopee hoặc Lazada -> chọn Why I Buy, bạn sẽ có ngay 48 giờ để cân nhắc trước khi chốt đơn!';
                        admin.selectTab(2); // Jump to Push Tab
                      },
                      icon: const Icon(Icons.campaign_rounded, size: 16),
                      label: const Text('Gửi Push Kích Hoạt Ngay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AdminColors.textSecondary,
                      ),
                      onPressed: () => admin.selectTab(3), // Jump to AI Tab
                      icon: const Icon(Icons.psychology_rounded, size: 16, color: AdminColors.primary),
                      label: const Text('Nhờ AI Soạn Lời Nhắn', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      textSection,
                      const SizedBox(height: 16),
                      actionButtons,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: textSection),
                    const SizedBox(width: 20),
                    actionButtons,
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // 4. Motives Breakdown & Trends Summary (Responsive Layout)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 900;

              final motivesCard = Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AdminColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AdminColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PHÂN BỔ ĐỘNG CƠ MUA SẮM',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AdminColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Top lý do thêm món cân nhắc',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AdminColors.textPrimary),
                    ),
                    const SizedBox(height: 18),
                    _buildMotiveRow('Cảm xúc (Emotion)', 38, AdminColors.purple),
                    _buildMotiveRow('Nhu cầu thật (Need)', 32, AdminColors.blue),
                    _buildMotiveRow('Khuyến mãi / Sale (Promotion)', 16, const Color(0xFFEC4899)),
                    _buildMotiveRow('Thói quen (Habit)', 9, AdminColors.amber),
                    _buildMotiveRow('Đầu tư (Investment)', 5, AdminColors.emerald),
                  ],
                ),
              );

              final stabilityCard = Container(
                padding: const EdgeInsets.all(22),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SỨC KHỎE HỆ THỐNG & ĐỘ ỔN ĐỊNH',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AdminColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tỷ lệ phiên không lỗi (Crash-Free)',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AdminColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AdminColors.emerald.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${metrics.crashFreeUsersRate}%',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AdminColors.emerald),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AdminColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AdminColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _MiniSummaryItem(label: 'Android Users', value: '78.4%'),
                          _MiniSummaryItem(label: 'iOS Users', value: '21.6%'),
                          _MiniSummaryItem(label: 'Tỷ lệ Mở Push', value: '41.2%'),
                          _MiniSummaryItem(label: 'Thời gian nghĩ TB', value: '38 Giờ'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '💡 Lưu ý: Hệ thống tự động theo dõi các sự kiện mở app và bóc tách link chia sẻ. Khi có bản cập nhật mới, các báo cáo crash sẽ tự động phân loại theo tên tính năng trong Crash Monitor.',
                      style: TextStyle(fontSize: 11, color: AdminColors.textMuted, height: 1.4),
                    ),
                  ],
                ),
              );

              if (isNarrow) {
                return Column(
                  children: [
                    motivesCard,
                    const SizedBox(height: 16),
                    stabilityCard,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: motivesCard),
                  const SizedBox(width: 16),
                  Expanded(flex: 6, child: stabilityCard),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMotiveRow(String label, int percent, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.textPrimary)),
              Text('$percent%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 6,
              backgroundColor: AdminColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _MiniSummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    context.watch<AdminService>();
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AdminColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AdminColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
