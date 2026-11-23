import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/core/errors/failure.dart';
import 'package:matric_compass/core/observability/error_reporter.dart';
import 'package:matric_compass/core/observability/scrubber.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// A reporter that remembers what it was asked to send.
final class _Remembering implements ErrorReporter {
  final reports = <(Object, String?)>[];

  @override
  Future<void> report(
    Object error,
    StackTrace stackTrace, {
    String? correlationId,
  }) async => reports.add((error, correlationId));
}

/// Sentry's transport, replaced: it keeps each event instead of sending it.
/// The last stop before the network, so what it holds is what would leave
/// the phone.
final class _CapturingTransport implements Transport {
  final events = <SentryEvent>[];

  @override
  Future<SentryId?> send(SentryEnvelope envelope) async {
    for (final item in envelope.items) {
      if (item.originalObject case final SentryEvent event) events.add(event);
    }
    return SentryId.newId();
  }
}

void main() {
  group('which failures are reported', () {
    Future<List<(Object, String?)>> failWith(Object error) async {
      final reporter = _Remembering();
      final container = ProviderContainer.test(
        observers: [ReportingObserver(reporter)],
        retry: (_, _) => null,
      );
      final failing = FutureProvider<int>((ref) => Future<int>.error(error));
      await expectLater(container.read(failing.future), throwsA(anything));
      return reporter.reports;
    }

    test('a server failure, with its correlation id', () async {
      final reports = await failWith(
        const ServerFailure(correlationId: '00-abc-01'),
      );
      expect(reports.single.$2, '00-abc-01');
    });

    test('a bug: anything that isn’t a Failure', () async {
      expect(await failWith(StateError('a bug')), hasLength(1));
    });

    test('not the app working as designed', () async {
      for (final expected in [
        const OfflineFailure(),
        const NotFoundFailure(),
        const ValidationFailure(fieldErrors: {}),
        const ConflictFailure(),
        const UnauthorizedFailure(),
      ]) {
        expect(await failWith(expected), isEmpty, reason: '$expected');
      }
    });
  });

  test('end to end: what reaches Sentry has the tag, the environment and '
      'no person', () async {
    final transport = _CapturingTransport();
    await Sentry.init((options) {
      options
        ..dsn = 'https://public@o0.ingest.sentry.io/0'
        ..environment = 'dev'
        ..sendDefaultPii = false
        ..beforeSend = Scrubber(
          () => (name: 'Thandiwe Nkosi', email: 'thandiwe@matric-compass.test'),
        ).call
        ..transport = transport;
    });
    addTearDown(Sentry.close);

    await const SentryErrorReporter().report(
      StateError('No dashboard for thandiwe@matric-compass.test'),
      StackTrace.current,
      correlationId: '00-4bf92f-01',
    );

    final event = transport.events.single;
    expect(event.tags?['correlation_id'], '00-4bf92f-01');
    expect(event.environment, 'dev');
    expect(
      event.exceptions!.single.value,
      'Bad state: No dashboard for [email]',
    );
  });
}
