import 'package:flutter/material.dart';

import '../core/formatters/date_format.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import 'app_bottom_sheet.dart';

/// "Chờ – chọn thời điểm xem lại" (screen 21): a few days later or a date the user picks.
/// Returns the review moment, or null when the sheet is dismissed.
class ReviewDateSheet {
  ReviewDateSheet._();

  /// Reviews land at 09:00, outside the 22:00–08:00 quiet hours of spec 4.3
  static const int reviewHour = 9;

  /// [defaultDays] is the user's cooling-off setting; 7 days is offered too
  static Future<DateTime?> show(
    BuildContext context, {
    required int defaultDays,
    DateTime? current,
  }) {
    final options = {defaultDays, 7}.toList()..sort();
    return AppBottomSheet.show<DateTime>(
      context,
      title: 'Xem lại món này khi nào?',
      child: _ReviewDateOptions(dayOptions: options, current: current),
    );
  }

  static DateTime atReviewHour(DateTime day) =>
      DateTime(day.year, day.month, day.day, reviewHour);

  static DateTime daysFromToday(int days, {DateTime? now}) {
    final today = now ?? DateTime.now();
    return atReviewHour(DateTime(today.year, today.month, today.day + days));
  }
}

class _ReviewDateOptions extends StatelessWidget {
  final List<int> dayOptions;
  final DateTime? current;

  const _ReviewDateOptions({required this.dayOptions, this.current});

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final initial = current != null && current!.isAfter(tomorrow)
        ? current!
        : tomorrow;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: tomorrow,
      lastDate: DateTime(now.year + 1, now.month, now.day),
      helpText: 'Chọn ngày xem lại',
    );
    if (picked == null || !context.mounted) return;
    Navigator.pop(context, ReviewDateSheet.atReviewHour(picked));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Món vẫn ở "Đang cân nhắc". Bạn vẫn có thể Mua hoặc Bỏ qua bất cứ lúc nào.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppDimens.space8),
        for (final days in dayOptions)
          ListTile(
            contentPadding: EdgeInsets.zero,
            minTileHeight: AppDimens.minTouchTarget,
            leading: const Icon(Icons.schedule),
            title: Text('Sau $days ngày'),
            subtitle: Text(
              formatWeekdayDate(ReviewDateSheet.daysFromToday(days)),
            ),
            onTap: () =>
                Navigator.pop(context, ReviewDateSheet.daysFromToday(days)),
          ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          minTileHeight: AppDimens.minTouchTarget,
          leading: const Icon(Icons.calendar_month_outlined),
          title: const Text('Chọn ngày khác'),
          onTap: () => _pickDate(context),
        ),
      ],
    );
  }
}
