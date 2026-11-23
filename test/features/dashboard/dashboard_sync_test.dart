import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/app/database/app_database.dart';
import 'package:matric_compass/core/cache/sync_state.dart';
import 'package:matric_compass/core/errors/failure.dart';
import 'package:matric_compass/core/errors/result.dart';
import 'package:matric_compass/core/money/cents.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_status.dart';
import 'package:matric_compass/features/dashboard/data/dashboard_repository_provider.dart';
import 'package:matric_compass/features/dashboard/domain/dashboard_repository.dart';
import 'package:matric_compass/features/dashboard/domain/learner_dashboard.dart';
import 'package:matric_compass/features/dashboard/presentation/dashboard_cache.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/test_database.dart';

/// Week 12 Day 1: a mock, not a fake. One line says what it answers, and
/// verify() can prove how often it was asked.
class MockDashboardRepository extends Mock implements DashboardRepository;

final _dashboard = LearnerDashboard(
  fullName: 'Thandiwe Nkosi',
  bursaryApplications: [
    BursarySummary(
      id: 'b-1',
      funder: 'Funza Lushaka',
      status: BursaryStatus.submitted,
      deadline: DateTime.utc(2026, 12, 3),
      daysUntilDeadline: 10,
      amount: const Cents(4500000),
    ),
  ],
);

void main() {
  late MockDashboardRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockDashboardRepository();
    container = ProviderContainer.test(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(repository),
        inMemoryDatabase,
      ],
    );
  });

  // DashboardSync is autoDispose: read once with nobody listening, it would
  // be thrown away and built again on the next read. Listening keeps it.
  Future<List<SyncState>> syncStates() async {
    final states = <SyncState>[];
    container.listen(
      dashboardSyncProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
    // build() starts the fetch in a microtask; let it finish.
    await pumpEventQueue();
    return states;
  }

  test('a fetch saves the dashboard, then says Synced', () async {
    when(() => repository.fetchDashboard())
        .thenAnswer((_) async => Ok(_dashboard));

    expect(await syncStates(), [isA<Syncing>(), isA<Synced>()]);

    final cached = await container
        .read(appDatabaseProvider)
        .dashboardDao
        .read();
    expect(cached?.value, _dashboard);
    verify(() => repository.fetchDashboard()).called(1);
  });

  test('no signal: SyncFailed, and the cache is left as it was', () async {
    when(() => repository.fetchDashboard())
        .thenAnswer((_) async => const Err(OfflineFailure()));

    final states = await syncStates();
    expect(states.last, isA<SyncFailed>());
    expect((states.last as SyncFailed).failure, isA<OfflineFailure>());
    expect(
      await container.read(appDatabaseProvider).dashboardDao.read(),
      isNull,
    );
  });

  test('refresh asks again, once more', () async {
    when(() => repository.fetchDashboard())
        .thenAnswer((_) async => Ok(_dashboard));
    await syncStates();

    await container.read(dashboardSyncProvider.notifier).refresh();

    verify(() => repository.fetchDashboard()).called(2);
    expect(container.read(dashboardSyncProvider), isA<Synced>());
  });
}
