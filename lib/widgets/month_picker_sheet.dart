import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Month Picker Bottom Sheet matching Figma "Month picker sheet"
class MonthPickerSheet extends StatefulWidget {
  final DateTime initialDate;

  const MonthPickerSheet({super.key, required this.initialDate});

  static Future<DateTime?> show(BuildContext context, DateTime initialDate) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MonthPickerSheet(initialDate: initialDate),
    );
  }

  @override
  State<MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<MonthPickerSheet> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
  }

  @override
  Widget build(BuildContext context) {
    const monthNames = [
      'Thg 1',
      'Thg 2',
      'Thg 3',
      'Thg 4',
      'Thg 5',
      'Thg 6',
      'Thg 7',
      'Thg 8',
      'Thg 9',
      'Thg 10',
      'Thg 11',
      'Thg 12',
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chọn kỳ tháng',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Year Selector Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    size: 22,
                    color: AppColors.onPrimary,
                  ),
                  onPressed: () {
                    setState(() => _selectedYear--);
                  },
                ),
                Text(
                  'Năm $_selectedYear',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: AppColors.onPrimary,
                  ),
                  onPressed: () {
                    setState(() => _selectedYear++);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 12 Months Grid (4 columns x 3 rows)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 12,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.6,
            ),
            itemBuilder: (context, index) {
              final month = index + 1;
              final isSelected =
                  month == _selectedMonth &&
                  _selectedYear == widget.initialDate.year;

              return InkWell(
                onTap: () {
                  final newDate = DateTime(_selectedYear, month, 1);
                  Navigator.pop(context, newDate);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.onPrimary
                          : AppColors.divider,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    monthNames[index],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isSelected
                          ? AppColors.onPrimary
                          : AppColors.accentNeutral,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
