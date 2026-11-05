import 'package:flutter/material.dart';

import '../../models/ui_state.dart';
import 'empty_view.dart';
import 'error_view.dart';
import 'loading_view.dart';

/// Renders a [UiState]: loading / empty / error (with "Thử lại") / [builder] for data.
/// UiInitial is shown as loading.
class UiStateBuilder<T> extends StatelessWidget {
  final UiState<T> state;
  final Widget Function(BuildContext context, T data) builder;
  final String? loadingMessage;
  final IconData emptyIcon;

  const UiStateBuilder({
    super.key,
    required this.state,
    required this.builder,
    this.loadingMessage,
    this.emptyIcon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      UiInitial<T>() || UiLoading<T>() => LoadingView(message: loadingMessage),
      UiEmpty<T>(:final message, :final actionTitle, :final onAction) =>
        EmptyView(
          title: message,
          icon: emptyIcon,
          actionTitle: actionTitle,
          onAction: onAction,
        ),
      UiError<T>(:final message, :final onRetry) => ErrorView(
        message: message,
        onRetry: onRetry,
      ),
      UiSuccess<T>(:final data) => builder(context, data),
    };
  }
}
