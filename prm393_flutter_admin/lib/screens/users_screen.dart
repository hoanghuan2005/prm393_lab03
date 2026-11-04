import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/admin_service.dart';
import '../models/admin_models.dart';
import '../theme/admin_colors.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _searchQuery = '';
  String _filter = 'all'; // all, new_today, active_today, dormant

  String _formatVnd(int amount) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminService>();
    final users = admin.users;

    final filteredUsers = users.where((u) {
      final matchesSearch = u.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.device.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.uid.toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      if (_filter == 'new_today') return u.isNewToday;
      if (_filter == 'active_today') return u.isActiveToday;
      if (_filter == 'dormant') return u.isDormant;

      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter & Search Toolbar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AdminColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AdminColors.border),
            ),
            child: Row(
              children: [
                // Search box
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(fontSize: 13, color: AdminColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Tìm theo tên, email, thiết bị...',
                      hintStyle: TextStyle(fontSize: 13, color: AdminColors.textSecondary),
                      prefixIcon: Icon(Icons.search_rounded, size: 20, color: AdminColors.textSecondary),
                      isDense: true,
                      filled: true,
                      fillColor: AdminColors.surfaceLight,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AdminColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AdminColors.border),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: AdminColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Filter Buttons in horizontally scrollable row to avoid crowding
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Tất cả (${users.length})', 'all', AdminColors.primary),
                      const SizedBox(width: 8),
                      _buildFilterChip('Mới hôm nay (${users.where((u) => u.isNewToday).length})', 'new_today', AdminColors.emerald),
                      const SizedBox(width: 8),
                      _buildFilterChip('Active hôm nay (${users.where((u) => u.isActiveToday).length})', 'active_today', AdminColors.blue),
                      const SizedBox(width: 8),
                      _buildFilterChip('Tải chưa dùng (${users.where((u) => u.isDormant).length})', 'dormant', AdminColors.purple),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Users Data Table - Balanced Full-Width Grid with Responsive Scroll
          Container(
            decoration: BoxDecoration(
              color: AdminColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AdminColors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final tableContent = Column(
                    children: [
                      // Table Header Row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        decoration: BoxDecoration(
                          color: AdminColors.surfaceLight,
                          border: Border(bottom: BorderSide(color: AdminColors.border)),
                        ),
                        child: Row(
                          children: [
                            _buildHeaderCell('NGƯỜI DÙNG', flex: 26),
                            _buildHeaderCell('TRẠNG THÁI', flex: 16),
                            _buildHeaderCell('ĐÃ CHI TIÊU', flex: 16),
                            _buildHeaderCell('MÓN CÂN NHẮC', flex: 14),
                            _buildHeaderCell('THIẾT BỊ', flex: 20),
                            _buildHeaderCell('HOẠT ĐỘNG CUỐI', flex: 16),
                            _buildHeaderCell('THAO TÁC', flex: 12, alignment: Alignment.centerRight),
                          ],
                        ),
                      ),

                  // Data Rows
                  if (filteredUsers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'Không tìm thấy người dùng nào phù hợp.',
                          style: TextStyle(color: AdminColors.textSecondary, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredUsers.length,
                      separatorBuilder: (_, _) => Divider(color: AdminColors.border, height: 1),
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          color: Colors.transparent,
                          child: Row(
                            children: [
                              // 1. NGƯỜI DÙNG
                              Expanded(
                                flex: 26,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: AdminColors.surfaceLight,
                                      child: Text(
                                        user.displayName.isNotEmpty ? user.displayName[0] : 'U',
                                        style: const TextStyle(fontWeight: FontWeight.w800, color: AdminColors.primary),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            user.displayName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: AdminColors.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            user.email,
                                            style: TextStyle(fontSize: 11, color: AdminColors.textSecondary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // 2. TRẠNG THÁI
                              Expanded(
                                flex: 16,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: _buildStatusBadge(user),
                                ),
                              ),

                              // 3. ĐÃ CHI TIÊU
                              Expanded(
                                flex: 16,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _formatVnd(user.totalSpending),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: AdminColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${user.purchaseCount} giao dịch',
                                      style: TextStyle(fontSize: 11, color: AdminColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),

                              // 4. MÓN CÂN NHẮC
                              Expanded(
                                flex: 14,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AdminColors.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${user.wishlistCount} món',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AdminColors.primary),
                                    ),
                                  ),
                                ),
                              ),

                              // 5. THIẾT BỊ
                              Expanded(
                                flex: 20,
                                child: Row(
                                  children: [
                                    Icon(Icons.phone_android_rounded, size: 15, color: AdminColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        user.device,
                                        style: TextStyle(fontSize: 12, color: AdminColors.textSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // 6. HOẠT ĐỘNG CUỐI
                              Expanded(
                                flex: 16,
                                child: Text(
                                  user.lastActiveAt,
                                  style: TextStyle(fontSize: 12, color: AdminColors.textSecondary),
                                ),
                              ),

                              // 7. THAO TÁC
                              Expanded(
                                flex: 12,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AdminColors.primary.withValues(alpha: 0.15),
                                      foregroundColor: AdminColors.primary,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: const BorderSide(color: AdminColors.primary, width: 0.8),
                                      ),
                                    ),
                                    onPressed: () => admin.selectUserForPush(user),
                                    icon: const Icon(Icons.campaign_rounded, size: 12),
                                    label: const Text('Gửi Push', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                );

                  if (constraints.maxWidth < 850) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 850,
                        child: tableContent,
                      ),
                    );
                  }

                  return tableContent;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label, {required int flex, Alignment alignment = Alignment.centerLeft}) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignment,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: AdminColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, Color color) {
    final isSelected = _filter == value;
    return InkWell(
      onTap: () => setState(() => _filter = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : AdminColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? color : AdminColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? (color == AdminColors.primary ? AdminColors.onPrimary : Colors.white) : AdminColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(UserAnalytics user) {
    if (user.isDormant) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AdminColors.purple.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AdminColors.purple.withValues(alpha: 0.3)),
        ),
        child: const Text('Tải chưa dùng', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AdminColors.purple)),
      );
    } else if (user.isNewToday) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AdminColors.emerald.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AdminColors.emerald.withValues(alpha: 0.3)),
        ),
        child: const Text('Mới hôm nay', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AdminColors.emerald)),
      );
    } else if (user.isActiveToday) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AdminColors.blue.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AdminColors.blue.withValues(alpha: 0.3)),
        ),
        child: const Text('Active hôm nay', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AdminColors.blue)),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AdminColors.surfaceLight,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text('Offline', style: TextStyle(fontSize: 11, color: AdminColors.textMuted)),
      );
    }
  }
}
