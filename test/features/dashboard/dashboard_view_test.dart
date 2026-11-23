import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/core/cache/snapshot.dart';
import 'package:matric_compass/core/cache/sync_state.dart';
import 'package:matric_compass/core/errors/failure.dart';
import 'package:matric_compass/core/money/cents.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_status.dart';
import 'package:matric_compass/features/dashboard/domain/learner_dashboard.dart';
import 'package:matric_compass/features/dashboard/presentation/dashboard_view.dart';

/// Week 11 Day 3: the view is decided by the cache and the sync together.
void main() {
  final fetchedAt = DateTime.utc(2026, 11, 18, 6, 12);
  final withOne = Snapshot(
    LearnerDashboard(
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
    ),
    fetchedAt: fetchedAt,
  );
  const nothing = AsyncData<Snapshot<LearnerDashboard>?>(null);

  test('nothing cached, fetching: loading', () {
    expect(
      DashboardView.from(nothing, const Syncing()),
      isA<DashboardLoading>(),
    );
  });

  test('nothing cached, and the fetch failed: the failure', () {
    expect(
      DashboardView.from(nothing, const SyncFailed(OfflineFailure())),
      isA<DashboardFailure>(),
    );
  });

  test('no applications is empty, not data', () {
    expect(
      DashboardView.from(
        AsyncData(
          Snapshot(
            const LearnerDashboard(
              fullName: 'Thandiwe Nkosi',
              bursaryApplications: [],
            ),
            fetchedAt: fetchedAt,
          ),
        ),
        const Synced(),
      ),
      isA<DashboardEmpty>(),
    );
  });

  test('cached and fetching: the cache, marked as refreshing', () {
    expect(
      DashboardView.from(AsyncData(withOne), const Syncing()),
      isA<DashboardData>()
          .having((d) => d.refreshing, 'refreshing', true)
          .having((d) => d.staleBecause, 'staleBecause', isNull),
    );
  });

  test('cached, and the fetch failed: still the cache, with the reason', () {
    expect(
      DashboardView.from(
        AsyncData(withOne),
        const SyncFailed(OfflineFailure()),
      ),
      isA<DashboardData>()
          .having((d) => d.staleBecause, 'staleBecause', isA<OfflineFailure>())
          .having((d) => d.fetchedAt, 'fetchedAt', fetchedAt),
    );
  });
}
