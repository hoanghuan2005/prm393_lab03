/// Shared limits used by validators and input fields
class AppConstants {
  AppConstants._();

  static const int titleMaxLength = 60;
  static const int noteMaxLength = 200;

  /// Largest amount (VND) accepted for a price, purchase or budget
  static const int amountMax = 999999999;
}
