import 'package:flutter/widgets.dart';

import '../../models/ui_state.dart';
import 'error_view.dart';
import 'loading_view.dart';

/// Loading or error view while the data behind a screen is not ready; null once every
/// state has data. Empty data returns null too: each screen shows its own empty message.
///
/// Usage: `body: stateView([vm.state]) ?? content`
Widget? stateView(
  Iterable<UiState<Object?>> states, {
  String loadingMessage = 'Đang tải dữ liệu...',
}) {
  // An error wins over loading so the user always gets a way to retry
  for (final state in states) {
    if (state case UiError(:final message, :final onRetry)) {
      return ErrorView(message: message, onRetry: onRetry);
    }
  }
  for (final state in states) {
    if (state is UiInitial || state is UiLoading) {
      return LoadingView(message: loadingMessage);
    }
  }
  return null;
}
