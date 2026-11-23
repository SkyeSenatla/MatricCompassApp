import 'package:matric_compass/core/errors/result.dart';
import 'package:matric_compass/core/money/cents.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_application.dart';

/// Week 10 Day 2: one bursary application by id.
///
/// Week 11 Day 1: every method returns a Result. "Not found" is a
/// NotFoundFailure now, for "doesn't exist" and "isn't yours" alike, as the
/// API's 404 is. BursaryNotFoundException is gone.
abstract interface class BursaryRepository {
  /// The application, or Err(NotFoundFailure).
  Future<Result<BursaryApplication>> fetchById(String id);

  /// Week 10 Day 3: the staff Applications tab. Every application that is
  /// waiting for a counsellor: submitted or under review.
  Future<Result<List<BursaryApplication>>> fetchForReview();

  /// Week 11 Day 1: sends a Draft to the counsellor. The API decides:
  /// 422 (RuleFailure) for missing documents or a passed deadline, 409
  /// (ConflictFailure) if it isn't a Draft any more.
  Future<Result<BursaryApplication>> submit(String id);

  /// Week 11 Day 3: changes a Draft's amount and deadline. [version] is the
  /// one the edit was made against: if the application changed since, the
  /// API answers 409 (ConflictFailure), as it does when it isn't a Draft
  /// any more. The API answers 204 with no body, so fetch the application
  /// again for its new version.
  Future<Result<void>> update(
    String id, {
    required Cents amount,
    required DateTime deadline,
    required int version,
  });
}
