import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/app/retry_policy.dart';
import 'package:matric_compass/core/errors/failure.dart';

void main() {
  // Week 11 Day 1: the rule is over the sealed Failure now.
  test('an answer from the API is final, never retried', () {
    for (final answer in const <Failure>[
      NotFoundFailure(),
      ForbiddenFailure(),
      ConflictFailure(),
      RuleFailure(),
      ValidationFailure(fieldErrors: {}),
      UnauthorizedFailure(),
      RateLimitedFailure(),
      // The API already retried before it sent a 500: don't multiply it.
      ServerFailure(),
    ]) {
      expect(appRetryPolicy(0, answer), isNull, reason: '$answer');
    }
  });

  test('no answer at all is retried three times, backing off', () {
    const failure = OfflineFailure();
    expect(appRetryPolicy(0, failure), const Duration(milliseconds: 200));
    expect(appRetryPolicy(1, failure), const Duration(milliseconds: 400));
    expect(appRetryPolicy(2, failure), const Duration(milliseconds: 800));
    expect(appRetryPolicy(3, failure), isNull);
  });

  test('anything that is not a Failure is a bug, not retried', () {
    expect(appRetryPolicy(0, StateError('bug')), isNull);
  });
}
