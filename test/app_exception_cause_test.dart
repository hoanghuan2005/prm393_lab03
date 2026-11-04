import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/errors/app_exception.dart';
import 'package:prm393_lab03/core/errors/firebase_error_mapper.dart';
import 'package:prm393_lab03/services/crashlytics_service.dart';
import 'package:prm393_lab03/services/service_guard.dart';
import 'package:prm393_lab03/viewmodels/error_reporting.dart';

class _RecordingCrashlytics extends Fake implements CrashlyticsService {
  final List<({Object? error, StackTrace? stack, Map<String, Object>? keys})>
  records = [];

  @override
  Future<void> recordHandledError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, Object>? customKeys,
  }) async {
    records.add((error: error, stack: stackTrace, keys: customKeys));
  }
}

class _Reporter with ErrorReporting {
  @override
  final CrashlyticsService? crashlyticsService;

  _Reporter(this.crashlyticsService);
}

void main() {
  group('AppException', () {
    test('existing two-argument constructor still works without cause', () {
      const e = AppException('not-found', 'Không tìm thấy dữ liệu.');
      expect(e.cause, isNull);
      expect(e.toString(), 'AppException(not-found): Không tìm thấy dữ liệu.');
      expect(AppException.unknown.cause, isNull);
    });

    test('toString appends the cause when present', () {
      final e = AppException('unknown', 'Lỗi.', cause: StateError('boom'));
      expect(e.toString(), 'AppException(unknown): Lỗi. <- Bad state: boom');
    });
  });

  group('mapFirebaseError', () {
    test('unknown errors keep the original error as cause', () {
      final original = StateError('boom');
      final mapped = mapFirebaseError(original);
      expect(mapped.code, 'unknown');
      expect(mapped.messageVi, AppException.unknown.messageVi);
      expect(mapped.cause, same(original));
      expect(mapped, isNot(same(AppException.unknown)));
    });

    test('unmapped auth and Firestore codes keep the cause', () {
      final auth = FirebaseAuthException(code: 'operation-not-allowed');
      expect(mapFirebaseError(auth).cause, same(auth));

      final firestore = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'resource-exhausted',
      );
      final mapped = mapFirebaseError(firestore);
      expect(mapped.code, 'resource-exhausted');
      expect(mapped.cause, same(firestore));
    });

    test('codes with their own message have no cause', () {
      expect(
        mapFirebaseError(FirebaseAuthException(code: 'user-disabled')).cause,
        isNull,
      );
      expect(
        mapFirebaseError(
          FirebaseException(plugin: 'cloud_firestore', code: 'not-found'),
        ).cause,
        isNull,
      );
    });
  });

  group('guard', () {
    test('rethrows as AppException with the original stack trace', () async {
      final original = StateError('boom');
      final originalStack = StackTrace.fromString('original-frame');

      Object? caught;
      StackTrace? caughtStack;
      try {
        await guard<void>(
          () async => Error.throwWithStackTrace(original, originalStack),
        );
      } catch (e, st) {
        caught = e;
        caughtStack = st;
      }

      expect(caught, isA<AppException>());
      expect((caught as AppException).cause, same(original));
      expect(caughtStack.toString(), originalStack.toString());
    });
  });

  group('ErrorReporting', () {
    test('records the cause with error_code for AppException', () {
      final crashlytics = _RecordingCrashlytics();
      final original = StateError('boom');
      final stack = StackTrace.fromString('original-frame');

      final message = _Reporter(crashlytics)
          .messageFor(mapFirebaseError(original), stack, reason: 'test');

      expect(message, AppException.unknown.messageVi);
      expect(crashlytics.records, hasLength(1));
      expect(crashlytics.records.single.error, same(original));
      expect(crashlytics.records.single.stack, same(stack));
      expect(crashlytics.records.single.keys, {'error_code': 'unknown'});
    });

    test('mapped AppException without cause is not recorded', () {
      final crashlytics = _RecordingCrashlytics();
      const mapped = AppException('not-found', 'Không tìm thấy dữ liệu.');

      final message = _Reporter(crashlytics)
          .messageFor(mapped, StackTrace.empty, reason: 'test');

      expect(message, mapped.messageVi);
      expect(crashlytics.records, isEmpty);
    });

    test('custom keys are merged with error_code', () {
      final crashlytics = _RecordingCrashlytics();

      _Reporter(crashlytics).messageFor(
        mapFirebaseError(StateError('boom')),
        StackTrace.empty,
        reason: 'test',
        customKeys: {'auth_method': 'github'},
      );

      expect(crashlytics.records.single.keys, {
        'auth_method': 'github',
        'error_code': 'unknown',
      });
    });

    test(
      'debug log without Crashlytics has type and code, not the message',
      () {
        final logs = <String>[];
        final previous = debugPrint;
        debugPrint = (message, {wrapWidth}) => logs.add(message ?? '');
        addTearDown(() => debugPrint = previous);

        final message = _Reporter(null).messageFor(
          mapFirebaseError(
            FirebaseAuthException(
              code: 'internal-error',
              message: 'failed for someone@example.com',
            ),
          ),
          StackTrace.empty,
          reason: 'test',
        );

        expect(message, 'Không đăng nhập được. Bấm "Thử lại" sau ít phút.');
        expect(logs, [
          'test: AppException(internal-error) <- '
              'FirebaseAuthException(internal-error)',
        ]);
      },
    );

    test('describeError never includes messages', () {
      expect(describeError(StateError('someone@example.com')), 'StateError');
      expect(
        describeError(
          PlatformException(code: 'network_error', message: 'someone'),
        ),
        'PlatformException(network_error)',
      );
    });

    test('non-AppException errors are recorded as is', () {
      final crashlytics = _RecordingCrashlytics();
      final original = StateError('boom');

      final message = _Reporter(crashlytics)
          .messageFor(original, StackTrace.empty, reason: 'test');

      expect(message, ErrorReporting.genericMessage);
      expect(crashlytics.records.single.error, same(original));
      expect(crashlytics.records.single.keys, isNull);
    });
  });
}
