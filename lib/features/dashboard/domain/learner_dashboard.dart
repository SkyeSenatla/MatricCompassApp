import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:matric_compass/core/money/cents.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_status.dart';

part 'learner_dashboard.freezed.dart';

/// Week 10 Day 2: what the learner's home screen shows, shaped like
/// `GET /api/v1/me/dashboard` (subjects come later: no endpoint records
/// marks yet).
@freezed
abstract class LearnerDashboard with _$LearnerDashboard {
  /// Creates a dashboard.
  const factory({
    required String fullName,
    required List<BursarySummary> bursaryApplications,
  }) = _LearnerDashboard;
}

/// One line of the dashboard's bursary list.
@freezed
abstract class BursarySummary with _$BursarySummary {
  /// Creates a summary. [daysUntilDeadline] comes from the server: the app
  /// shows it, it doesn't compute it.
  const factory({
    required String id,
    required String funder,
    required BursaryStatus status,
    required DateTime deadline,
    required int daysUntilDeadline,
    required Cents amount,
  }) = _BursarySummary;
}
