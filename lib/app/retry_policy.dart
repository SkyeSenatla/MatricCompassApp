import 'package:matric_compass/core/errors/failure.dart';

/// Week 10 Day 3: when Riverpod may retry a failed provider.
///
/// Riverpod 3 retries every failure by default. That's right for a network
/// blip, and wrong for an answer: "not found" won't change if we ask again.
/// Retrying it kept a deep link to someone else's application on a spinner
/// for most of a minute.
///
/// Week 11 Day 1: the rule is now over the sealed Failure, and only "no
/// answer at all" is retried: the signal may come back.
///
/// Not a 500. The API has already retried its own database before it gave
/// up (about 16 seconds, measured with the database stopped), so three
/// more tries here kept the person on a spinner for about a minute. A 500
/// is shown at once, with its reference and a Try again button. Every 4xx
/// is final, and so is anything that isn't a Failure (a bug). Providers
/// only read, so this never repeats a write.
Duration? appRetryPolicy(int retryCount, Object error) {
  if (error is! OfflineFailure || retryCount >= 3) return null;
  // Three tries, 200 ms, 400 ms, 800 ms apart.
  return Duration(milliseconds: 200 * (1 << retryCount));
}
