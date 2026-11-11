import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_text_styles.dart';

/// Month Picker Bottom Sheet matching Figma "Month picker sheet"
class MonthPickerSheet extends StatefulWidget {
  final DateTime initialDate;

  /// Months after this one cannot be picked (screens that only show the past)
  final DateTime? lastMonth;

  const MonthPickerSheet({
    super.key,
    required this.initialDate,
    this.lastMonth,
  });

  static Future<DateTime?> show(
    BuildContext context,
    DateTime initialDate, {
    DateTime? lastMonth,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          MonthPickerSheet(initialDate: initialDate, lastMonth: lastMonth),
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
      // Last row of months above the navigation bar (edge-to-edge)
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        32 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: AppSemanticColors.of(context).cardSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppSemanticColors.of(context).inputBorder,
              borderRadius: AppDimens.borderSmall,
            ),
          ),
          const SizedBox(height: AppDimens.space16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Chọn kỳ tháng',
                  style: AppTextStyles.titleLarge.withInheritedColor.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppSemanticColors.of(context).textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: AppSemanticColors.of(context).textSecondary,
                ),
                tooltip: 'Đóng',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: AppDimens.space12),

          // Year Selector Row
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.space12,
              vertical: AppDimens.space4,
            ),
            decoration: BoxDecoration(
              color: AppSemanticColors.of(context).mutedSurface,
              borderRadius: AppDimens.borderMedium,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.chevron_left_rounded,
                    size: 22,
                    color: AppSemanticColors.of(context).textPrimary,
                  ),
                  tooltip: 'Năm trước',
                  onPressed: () {
                    setState(() => _selectedYear--);
                  },
                ),
                Flexible(
                  child: Text(
                    'Năm $_selectedYear',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyLarge.withInheritedColor.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppSemanticColors.of(context).textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: AppSemanticColors.of(context).textPrimary,
                  ),
                  tooltip: 'Năm sau',
                  onPressed:
                      widget.lastMonth != null &&
                          _selectedYear >= widget.lastMonth!.year
                      ? null
                      : () {
                          setState(() => _selectedYear++);
                        },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimens.space16),

          // Fewer columns leave room for larger system text.
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 12,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.textScalerOf(context).scale(14) > 16
                  ? 3
                  : 4,
              mainAxisSpacing: AppDimens.space8,
              crossAxisSpacing: AppDimens.space8,
              mainAxisExtent: MediaQuery.textScalerOf(context)
                  .scale(AppDimens.minTouchTarget),
            ),
            itemBuilder: (context, index) {
              final month = index + 1;
              final isSelected =
                  month == _selectedMonth &&
                  _selectedYear == widget.initialDate.year;
              final last = widget.lastMonth;
              final isFuture =
                  last != null &&
                  DateTime(
                    _selectedYear,
                    month,
                  ).isAfter(DateTime(last.year, last.month));

              return Opacity(
                opacity: isFuture ? 0.35 : 1,
                child: InkWell(
                  onTap: isFuture
                      ? null
                      : () {
                          final newDate = DateTime(_selectedYear, month, 1);
                          Navigator.pop(context, newDate);
                        },
                  borderRadius: AppDimens.borderMedium,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppSemanticColors.of(context).background,
                      borderRadius: AppDimens.borderMedium,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.onPrimary
                            : AppSemanticColors.of(context).divider,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      monthNames[index],
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.withInheritedColor
                          .copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: isSelected
                                ? AppColors.onPrimary
                                : AppSemanticColors.of(context).accent,
                          ),
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
