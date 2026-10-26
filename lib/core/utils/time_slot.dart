/// Part of the day a purchase happened in
enum TimeSlot {
  morning('Sáng'), // 05:00 – 10:59
  noon('Trưa'), // 11:00 – 13:59
  afternoon('Chiều'), // 14:00 – 17:59
  evening('Tối'); // 18:00 – 04:59

  final String label;

  const TimeSlot(this.label);

  static TimeSlot fromHour(int hour) {
    if (hour >= 5 && hour < 11) return TimeSlot.morning;
    if (hour >= 11 && hour < 14) return TimeSlot.noon;
    if (hour >= 14 && hour < 18) return TimeSlot.afternoon;
    return TimeSlot.evening;
  }

  static TimeSlot fromDateTime(DateTime dt) => fromHour(dt.hour);
}
