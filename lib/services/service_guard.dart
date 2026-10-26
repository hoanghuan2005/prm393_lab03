import 'dart:async';

import '../core/errors/firebase_error_mapper.dart';

/// Runs a Firebase call and rethrows any failure as an AppException
Future<T> guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } catch (e) {
    throw mapFirebaseError(e);
  }
}

/// Same as [guard] for streams: errors reach listeners as AppException
Stream<T> guardStream<T>(Stream<T> stream) => stream.transform(
  StreamTransformer<T, T>.fromHandlers(
    handleError: (error, stackTrace, sink) =>
        sink.addError(mapFirebaseError(error), stackTrace),
  ),
);
