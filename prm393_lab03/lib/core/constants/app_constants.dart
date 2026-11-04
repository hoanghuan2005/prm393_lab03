/// Shared limits used by validators and input fields
class AppConstants {
  AppConstants._();

  static const int titleMaxLength = 60;
  static const int noteMaxLength = 200;

  /// Largest amount (VND) accepted for a price, purchase or budget
  static const int amountMax = 999999999;

  /// Shown as "Phiên bản 1.0.0" in Cá nhân; keep in step with `version` in pubspec.yaml
  static const String appVersion = '1.0.0';
}
