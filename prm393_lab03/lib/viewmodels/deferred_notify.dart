import 'package:flutter/foundation.dart';

/// For ViewModels updated from a ProxyProvider: `update` runs during build, so changes made
/// there must notify on the next microtask instead of synchronously.
mixin DeferredNotify on ChangeNotifier {
  bool _disposed = false;

  bool get isDisposed => _disposed;

  void notifyLater() => Future.microtask(() {
    if (!_disposed) notifyListeners();
  });

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
