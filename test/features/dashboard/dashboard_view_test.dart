import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/core/money/cents.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_status.dart';
import 'package:matric_compass/features/dashboard/domain/learner_dashboard.dart';
import 'package:matric_compass/features/dashboard/presentation/dashboard_view.dart';

void main() {
  final withOne = LearnerDashboard(
    fullName: 'Thandiwe Nkosi',
    bursaryApplications: [
      BursarySummary(
        id: 'a',
        funder: 'NSFAS',
        status: BursaryStatus.draft,
        deadline: DateTime.utc(2027, 3, 31),
        daysUntilDeadline: 142,
        amount: const Cents(4500000),
      ),
    ],
  );

  test('loading', () {
    expect(
      DashboardView.from(const AsyncLoading<LearnerDashboard>()),
      isA<DashboardLoading>(),
    );
  });

  test('no applications is empty, not data', () {
    expect(
      DashboardView.from(
        const AsyncData(
          LearnerDashboard(fullName: 'Thandiwe Nkosi', bursaryApplications: []),
        ),
      ),
      isA<DashboardEmpty>(),
    );
  });

  test('applications are data', () {
    expect(
      DashboardView.from(AsyncData(withOne)),
      isA<DashboardData>().having((d) => d.refreshing, 'refreshing', false),
    );
  });

  test('an error is a failure', () {
    expect(
      DashboardView.from(
        AsyncError<LearnerDashboard>(Exception('down'), StackTrace.empty),
      ),
      isA<DashboardFailure>(),
    );
  });
}
