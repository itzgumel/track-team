import 'package:flutter/foundation.dart';

/// Drops notifications after dispose.
///
/// View models kick off async loads; if the user navigates away before a
/// load finishes, the completion would otherwise call [notifyListeners] on
/// a disposed notifier and crash in debug mode.
mixin SafeNotifier on ChangeNotifier {
  bool _disposed = false;

  @protected
  bool get isDisposed => _disposed;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
