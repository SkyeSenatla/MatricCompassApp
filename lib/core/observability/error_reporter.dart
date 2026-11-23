import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matric_compass/core/errors/failure.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Week 12 Day 2: where errors go when they leave the phone. An interface,
/// so a test can see what would have been sent without a Sentry account.
abstract interface class ErrorReporter {
  /// Reports [error]. [correlationId] is the API's id for the request that
  /// failed, when there was one.
  Future<void> report(
    Object error,
    StackTrace stackTrace, {
    String? correlationId,
  });
}

/// The real reporter: Sentry, with the API's correlation id as a tag, so
/// one failure can be found on both ends: in Sentry, and in the API's
/// traces in Aspire.
final class SentryErrorReporter implements ErrorReporter {
  /// Creates the reporter.
  const new();

  @override
  Future<void> report(
    Object error,
    StackTrace stackTrace, {
    String? correlationId,
  }) async {
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) async {
        if (correlationId != null) {
          await scope.setTag('correlation_id', correlationId);
        }
      },
    );
  }
}

/// Week 12 Day 2: which failures are worth a report.
///
/// The ones that show the person a reference are the ones they'll ask
/// support about: a server failure, or an answer we couldn't read. No
/// signal, not found, a field error or a 409 is the app working as
/// designed, and reporting them would bury the real problems. Anything that
/// isn't a Failure at all is a bug, and always reported.
bool isWorthReporting(Object error) => switch (error) {
  final Failure failure => failure.showsReference,
  _ => true,
};

/// Week 12 Day 2: every provider that fails passes through here. One place
/// sees every failure in the app, so no screen has to remember to report.
final class ReportingObserver extends ProviderObserver {
  /// Creates the observer.
  new(this._reporter);

  final ErrorReporter _reporter;

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    if (!isWorthReporting(error)) return;
    unawaited(
      _reporter.report(
        error,
        stackTrace,
        correlationId: switch (error) {
          Failure(:final correlationId) => correlationId,
          _ => null,
        },
      ),
    );
  }
}
