import '../constants/app_constants.dart';
import '../formatters/money_format.dart';

/// Form validators: return null when valid, otherwise a Vietnamese message.
/// Signatures match `TextFormField.validator`.
class Validators {
  Validators._();

  static String? validateTitle(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Vui lòng nhập tên món';
    if (text.length > AppConstants.titleMaxLength) {
      return 'Tên món tối đa ${AppConstants.titleMaxLength} ký tự';
    }
    return null;
  }

  static String? validateAmount(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Vui lòng nhập số tiền';
    final amount = parseVnd(value!);
    if (amount == null) return 'Số tiền phải lớn hơn 0';
    if (amount > AppConstants.amountMax) {
      return 'Số tiền tối đa ${formatVnd(AppConstants.amountMax)}';
    }
    return null;
  }

  /// Empty is allowed (price not known yet); a filled value must be valid
  static String? validateOptionalAmount(String? value) {
    if ((value ?? '').trim().isEmpty) return null;
    return validateAmount(value);
  }

  static String? validateNote(String? value) {
    if ((value ?? '').trim().length > AppConstants.noteMaxLength) {
      return 'Ghi chú tối đa ${AppConstants.noteMaxLength} ký tự';
    }
    return null;
  }

  /// Shared by the form's ViewModel and the Firestore write boundary.
  static String? validatePurchase({
    required String title,
    required int amountVnd,
    required String budgetGroupId,
    String? note,
  }) {
    final titleError = validateTitle(title);
    if (titleError != null) return titleError;
    if (amountVnd <= 0) return 'Số tiền phải lớn hơn 0';
    if (amountVnd > AppConstants.amountMax) {
      return 'Số tiền tối đa ${formatVnd(AppConstants.amountMax)}';
    }
    if (budgetGroupId.trim().isEmpty) return 'Vui lòng chọn nhóm ngân sách';
    return validateNote(note);
  }
}
