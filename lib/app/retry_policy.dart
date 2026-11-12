import 'package:matric_compass/features/bursaries/domain/bursary_repository.dart';
import 'package:matric_compass/features/students/domain/students_repository.dart';

/// Week 10 Day 3: when Riverpod may retry a failed provider.
///
/// Riverpod 3 retries every failure by default. That's right for a network
/// blip, and wrong for an answer: "not found" won't change if we ask again.
/// Retrying it kept a deep link to someone else's application on a spinner
/// for most of a minute, instead of showing "Application not found." at
/// once. Week 11 extends this to the sealed Failure: 4xx answers are final.
Duration? appRetryPolicy(int retryCount, Object error) {
  if (error is BursaryNotFoundException || error is StudentNotFoundException) {
    return null;
  }
  // Anything else: three tries, 200 ms, 400 ms, 800 ms apart.
  if (retryCount >= 3) return null;
  return Duration(milliseconds: 200 * (1 << retryCount));
}
