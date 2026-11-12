import 'package:freezed_annotation/freezed_annotation.dart';

part 'aptitude_test.freezed.dart';

/// Week 10 Day 4: one aptitude test result, shaped like the contract's
/// AptitudeTestResponse.
///
/// [recommendedCareers] comes from the server, which works it out from the
/// score. The app shows it as sent and never computes it: two copies of
/// one rule drift apart.
@freezed
abstract class AptitudeTest with _$AptitudeTest {
  /// Creates a result. [score] is out of 100; the API refuses anything else.
  const factory({
    required String id,
    required String studentId,
    required String testType,
    required DateTime dateTaken,
    required int score,
    required List<String> recommendedCareers,
  }) = _AptitudeTest;
}
