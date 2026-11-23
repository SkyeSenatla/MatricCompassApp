import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/app/database/app_database.dart';
import 'package:matric_compass/core/errors/failure.dart';
import 'package:matric_compass/core/errors/result.dart';
import 'package:matric_compass/features/dashboard/data/dashboard_repository_provider.dart';
import 'package:matric_compass/features/dashboard/data/fake_dashboard_repository.dart';
import 'package:matric_compass/features/dashboard/domain/dashboard_repository.dart';
import 'package:matric_compass/features/dashboard/domain/learner_dashboard.dart';
import 'package:matric_compass/features/dashboard/presentation/dashboard_screen.dart';

import '../../support/test_database.dart';

/// Never answers: the screen stays in its first load.
class _NeverRepository implements DashboardRepository {
  @override
  Future<Result<LearnerDashboard>> fetchDashboard() =>
      Completer<Result<LearnerDashboard>>().future;
}

/// Slow, then fails once: the fake the demo swaps in through an override.
class _SlowFailingRepository implements DashboardRepository {
  bool _failedOnce = false;

  @override
  Future<Result<LearnerDashboard>> fetchDashboard() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!_failedOnce) {
      _failedOnce = true;
      // Week 11 Day 1: repositories return a Failure, they don't throw.
      return const Err(OfflineFailure());
    }
    return await FakeDashboardRepository(latency: Duration.zero)
        .fetchDashboard();
  }
}

/// Pumps the dashboard with [repository] behind the provider.
///
/// The ProviderScope sits directly inside pumpWidget: riverpod_lint treats
/// any other ProviderScope as a nested scope and asks for dependencies.
///
/// Week 11 Day 3: with a real database in memory, empty unless [database]
/// is given with something already cached.
Future<void> _pumpDashboard(
  WidgetTester tester,
  DashboardRepository repository, {
  AppDatabase? database,
}) => tester.pumpWidget(
  ProviderScope(
    overrides: [
      dashboardRepositoryProvider.overrideWithValue(repository),
      if (database == null)
        inMemoryDatabase
      else
        appDatabaseProvider.overrideWithValue(database),
    ],
    // Riverpod 3 retries a failed provider by itself, with backoff. A test
    // that wants to see the failure turns that off.
    retry: (retryCount, error) => null,
    child: const MaterialApp(home: DashboardScreen()),
  ),
);

// Typed as an escape: a no-break space looks exactly like a space.
const _nsfasAmount = 'R\u00A045\u00A0000,00';

void main() {
  testWidgets('loading shows a skeleton', (tester) async {
    await _pumpDashboard(tester, _NeverRepository());

    expect(find.byKey(const ValueKey('skeleton-0')), findsOneWidget);
  });

  testWidgets('a learner with no applications sees the empty state', (
    tester,
  ) async {
    await _pumpDashboard(
      tester,
      FakeDashboardRepository(applications: [], latency: Duration.zero),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('No bursary applications yet'), findsOneWidget);
  });

  testWidgets('data shows each application with its amount and status', (
    tester,
  ) async {
    await _pumpDashboard(
      tester,
      FakeDashboardRepository(latency: Duration.zero),
    );
    await tester.pumpAndSettle();

    expect(find.text('NSFAS'), findsOneWidget);
    expect(find.text(_nsfasAmount), findsOneWidget);
    expect(find.textContaining('Status not recognised'), findsOneWidget);
  });

  testWidgets('a slow failure shows loading, then failure, and retry works', (
    tester,
  ) async {
    await _pumpDashboard(tester, _SlowFailingRepository());
    expect(find.byKey(const ValueKey('skeleton-0')), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text("We couldn't load your dashboard."), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(find.byKey(const ValueKey('skeleton-0')), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('NSFAS'), findsOneWidget);
  });

  // Week 11 Day 3: what the phone had, with how old it is.
  testWidgets('offline with a cached dashboard: the dashboard, and a banner', (
    tester,
  ) async {
    final database = memoryDatabase();
    addTearDown(database.close);
    // Outside the test's fake clock: the fake's delay and Drift's writes
    // both need real time.
    await tester.runAsync(() async {
      final cached = await FakeDashboardRepository(latency: Duration.zero)
          .fetchDashboard();
      await database.dashboardDao.save(
        (cached as Ok<LearnerDashboard>).value,
        fetchedAt: DateTime.now().toUtc(),
      );
    });

    await _pumpDashboard(tester, _OfflineRepository(), database: database);
    await tester.pumpAndSettle();

    expect(find.text('NSFAS'), findsOneWidget);
    expect(find.textContaining("You're offline. Last updated"), findsOneWidget);
    expect(find.text("We couldn't load your dashboard."), findsNothing);
  });
}

/// No answer, ever.
class _OfflineRepository implements DashboardRepository {
  @override
  Future<Result<LearnerDashboard>> fetchDashboard() async =>
      const Err(OfflineFailure());
}
