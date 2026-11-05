import 'package:flutter/foundation.dart';

/// Async work may finish after the screen is gone: never notify a disposed model.
mixin SafeNotifier on ChangeNotifier {
  bool _disposed = false;

  bool get isDisposed => _disposed;

  void notifySafely() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
