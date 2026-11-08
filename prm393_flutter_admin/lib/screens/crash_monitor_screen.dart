import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/admin_service.dart';
import '../models/admin_models.dart';
import '../theme/admin_colors.dart';

class CrashMonitorScreen extends StatefulWidget {
  const CrashMonitorScreen({super.key});

  @override
  State<CrashMonitorScreen> createState() => _CrashMonitorScreenState();
}

class _CrashMonitorScreenState extends State<CrashMonitorScreen> {
  String _filter = 'all'; // all, active, resolved
  String? _expandedCrashId;

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminService>();
    final crashes = admin.crashes;

    final filteredCrashes = crashes.where((c) {
      if (_filter == 'active') return !c.isResolved;
      if (_filter == 'resolved') return c.isResolved;
      return true;
    }).toList();

    final activeCount = crashes.where((c) => !c.isResolved).length;
    final totalAffected = crashes.where((c) => !c.isResolved).fold(0, (acc, c) => acc + c.affectedUsers);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Stats (Responsive Layout)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 800;
              final card1 = _buildHealthCard('Sự cố đang diễn ra', '$activeCount lỗi', 'Cần can thiệp fix bug', AdminColors.rose, Icons.warning_amber_rounded);
              final card2 = _buildHealthCard('Thiết bị bị ảnh hưởng', '$totalAffected thiết bị', 'Trong 48 giờ qua', AdminColors.amber, Icons.phone_android_rounded);
              final card3 = _buildHealthCard('Tỷ lệ phiên ổn định', '${admin.metrics.crashFreeUsersRate}%', 'Mục tiêu hệ thống > 99.0%', AdminColors.emerald, Icons.shield_rounded);

              if (isNarrow) {
                return Column(
                  children: [
                    card1,
                    const SizedBox(height: 12),
                    card2,
                    const SizedBox(height: 12),
                    card3,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: card1),
                  const SizedBox(width: 16),
                  Expanded(child: card2),
                  const SizedBox(width: 16),
                  Expanded(child: card3),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Filter bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AdminColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AdminColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildFilterBtn('Tất cả (${crashes.length})', 'all', AdminColors.primary),
                    const SizedBox(width: 8),
                    _buildFilterBtn('Chưa giải quyết ($activeCount)', 'active', AdminColors.rose),
                    const SizedBox(width: 8),
                    _buildFilterBtn('Đã xử lý (${crashes.length - activeCount})', 'resolved', AdminColors.emerald),
                  ],
                ),
                Text('Đồng bộ tự động từ Crashlytics & Firestore', style: TextStyle(fontSize: 11, color: AdminColors.textSecondary)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Crash items list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredCrashes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final crash = filteredCrashes[index];
              final isExpanded = _expandedCrashId == crash.id;

              return Container(
                decoration: BoxDecoration(
                  color: crash.isResolved ? AdminColors.surface.withValues(alpha: 0.6) : AdminColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: crash.isResolved ? AdminColors.border : AdminColors.rose.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(22),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _buildSeverityTag(crash.severity),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AdminColors.surfaceLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Chức năng: ${crash.feature}',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AdminColors.textPrimary),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(crash.errorCode, style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: AdminColors.textSecondary)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  crash.errorMessage,
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AdminColors.textPrimary),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Ảnh hưởng: ${crash.affectedUsers} user (${crash.occurrences} lần) • App: ${crash.appVersion} • Hệ điều hành: ${crash.platform} • Gần nhất: ${crash.lastOccurred}',
                                  style: TextStyle(fontSize: 11, color: AdminColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Row(
                            children: [
                              if (!crash.isResolved)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AdminColors.emerald,
                                    foregroundColor: AdminColors.onPrimary,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => admin.resolveCrash(crash.id),
                                  icon: const Icon(Icons.check_circle_rounded, size: 14),
                                  label: const Text('Đánh dấu Đã Sửa', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(color: AdminColors.surfaceLight, borderRadius: BorderRadius.circular(8)),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.check_circle_rounded, size: 14, color: AdminColors.emerald),
                                      SizedBox(width: 4),
                                      Text('Đã giải quyết', style: TextStyle(fontSize: 11, color: AdminColors.emerald, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AdminColors.textSecondary),
                                onPressed: () {
                                  setState(() {
                                    _expandedCrashId = isExpanded ? null : crash.id;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (isExpanded)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AdminColors.background,
                          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                          border: Border(top: BorderSide(color: AdminColors.border)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.terminal_rounded, size: 16, color: AdminColors.primary),
                                SizedBox(width: 6),
                                Text('CRASH STACK TRACE CHI TIẾT (FLUTTER CRASHLYTICS SDK)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AdminColors.primary)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              crash.stackTrace,
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFFFCA5A5), height: 1.4),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCard(String title, String value, String desc, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AdminColors.textSecondary)),
              const SizedBox(height: 6),
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
              const SizedBox(height: 2),
              Text(desc, style: TextStyle(fontSize: 11, color: AdminColors.textSecondary)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 24, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBtn(String label, String value, Color color) {
    final isSelected = _filter == value;
    return InkWell(
      onTap: () => setState(() => _filter = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : AdminColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : AdminColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? (color == AdminColors.primary ? AdminColors.onPrimary : Colors.white) : AdminColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityTag(CrashSeverity severity) {
    String text = 'CẢNH BÁO';
    Color color = AdminColors.amber;
    if (severity == CrashSeverity.fatal) {
      text = 'FATAL CRASH';
      color = AdminColors.rose;
    } else if (severity == CrashSeverity.high) {
      text = 'MỨC CAO';
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: color)),
      child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color)),
    );
  }
}
