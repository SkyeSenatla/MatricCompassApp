import 'package:matric_compass/core/api/generated/matric_compass_api.dart';
import 'package:matric_compass/core/api/generated/models/dashboard_bursary_application.dart';
import 'package:matric_compass/core/api/generated/models/learner_dashboard_response.dart';
import 'package:matric_compass/core/errors/failure_mapping.dart';
import 'package:matric_compass/core/errors/result.dart';
import 'package:matric_compass/core/money/cents.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_status.dart';
import 'package:matric_compass/features/dashboard/domain/dashboard_repository.dart';
import 'package:matric_compass/features/dashboard/domain/learner_dashboard.dart';

/// Week 11 Day 1: the dashboard from GET /api/v1/me/dashboard.
///
/// The generated types stop here: the mapper below turns them into the
/// domain types Week 10 built, and nothing above this folder sees them.
final class ApiDashboardRepository implements DashboardRepository {
  /// Creates the repository over the generated API client.
  const new(this._api);

  final MatricCompassApi _api;

  @override
  Future<Result<LearnerDashboard>> fetchDashboard() =>
      guard(() async => (await _api.me.getApiV1MeDashboard()).toDomain());
}

extension on LearnerDashboardResponse {
  // The API also sends `subjects`. No screen shows them yet, so they aren't
  // mapped: a field nobody reads is a field nobody tests.
  LearnerDashboard toDomain() => LearnerDashboard(
    fullName: fullName,
    bursaryApplications: [
      for (final application in bursaryApplications) application.toDomain(),
    ],
  );
}

extension on DashboardBursaryApplication {
  BursarySummary toDomain() => BursarySummary(
    id: id,
    funder: funder,
    // A status string becomes our enum, with unknown for anything new.
    status: BursaryStatus.fromApi(status),
    deadline: deadline.toUtc(),
    // The server computes it; the app shows it.
    daysUntilDeadline: daysUntilDeadline,
    amount: Cents(amountInCents),
  );
}
