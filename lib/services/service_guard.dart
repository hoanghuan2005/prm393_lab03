import 'dart:async';

import '../core/errors/firebase_error_mapper.dart';
import 'pending_writes.dart';

/// Runs a Firebase call and rethrows any failure as an AppException
Future<T> guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } catch (e) {
    throw mapFirebaseError(e);
  }
}

/// Firestore applies a write to the local cache at once, but its Future only completes
/// when the server confirms it, which never happens offline. After [timeout] the write
/// counts as saved on this device and keeps syncing in the background (spec E04:
/// "Đã lưu trên máy; sẽ đồng bộ khi có mạng"). Errors that arrive in time still throw.
Future<void> awaitWrite(
  Future<void> write, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  try {
    await write.timeout(timeout);
  } on TimeoutException {
    PendingWrites.instance.track(write);
  }
}

/// Same as [guard] for streams: errors reach listeners as AppException
Stream<T> guardStream<T>(Stream<T> stream) => stream.transform(
  StreamTransformer<T, T>.fromHandlers(
    handleError: (error, stackTrace, sink) =>
        sink.addError(mapFirebaseError(error), stackTrace),
  ),
);
