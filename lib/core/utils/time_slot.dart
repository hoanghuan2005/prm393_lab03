/// Part of the day a purchase happened in
enum TimeSlot {
  morning('Sáng', '05:00 - 11:00'),
  noon('Trưa', '11:00 - 14:00'),
  afternoon('Chiều', '14:00 - 18:00'),
  evening('Tối', '18:00 - 05:00');

  final String label;

  /// Hour range shown next to the label
  final String rangeLabel;

  const TimeSlot(this.label, this.rangeLabel);

  static TimeSlot fromHour(int hour) {
    if (hour >= 5 && hour < 11) return TimeSlot.morning;
    if (hour >= 11 && hour < 14) return TimeSlot.noon;
    if (hour >= 14 && hour < 18) return TimeSlot.afternoon;
    return TimeSlot.evening;
  }

  static TimeSlot fromDateTime(DateTime dt) => fromHour(dt.hour);
}
