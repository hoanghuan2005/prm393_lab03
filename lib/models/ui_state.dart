import 'package:flutter/foundation.dart';

/// Explicit UI State Model per Lab 3 Architecture specification (Section 5)
sealed class UiState<T> {
  const UiState();
}

class UiInitial<T> extends UiState<T> {
  const UiInitial();
}

class UiLoading<T> extends UiState<T> {
  const UiLoading();
}

class UiEmpty<T> extends UiState<T> {
  final String message;
  final String? actionTitle;
  final VoidCallback? onAction;

  const UiEmpty({required this.message, this.actionTitle, this.onAction});
}

class UiSuccess<T> extends UiState<T> {
  final T data;
  const UiSuccess(this.data);
}

class UiError<T> extends UiState<T> {
  final String message;
  final VoidCallback? onRetry;

  const UiError({required this.message, this.onRetry});
}
