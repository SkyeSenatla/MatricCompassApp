import 'dart:async';

import 'package:matric_compass/app/database/app_database.dart';
import 'package:matric_compass/core/cache/snapshot.dart';
import 'package:matric_compass/core/cache/sync_state.dart';
import 'package:matric_compass/core/errors/result.dart';
import 'package:matric_compass/features/dashboard/data/dashboard_repository_provider.dart';
import 'package:matric_compass/features/dashboard/domain/learner_dashboard.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_cache.g.dart';

/// Week 11 Day 3: the dashboard as the phone has it. Both the Home and
/// Bursaries tabs watch this, never the network: they draw at once, with
/// or without signal, and again whenever a fetch saves newer rows.
///
/// Null until the first fetch on this phone has been saved.
@riverpod
Stream<Snapshot<LearnerDashboard>?> cachedDashboard(Ref ref) =>
    ref.watch(appDatabaseProvider).dashboardDao.watch();

/// Week 11 Day 3: stale-while-revalidate's second half. Every time a
/// dashboard screen opens, one fetch in the background; its answer goes
/// into the cache, never straight to a widget.
///
/// autoDispose (the codegen default): leave both tabs and it goes, so the
/// next visit asks again.
@riverpod
class DashboardSync extends _$DashboardSync {
  @override
  SyncState build() {
    // After build returns: build itself must not change the state.
    unawaited(Future.microtask(_fetch));
    return const Syncing();
  }

  /// Asks again: pull to refresh, or the banner's Try again.
  Future<void> refresh() async {
    state = const Syncing();
    await _fetch();
  }

  Future<void> _fetch() async {
    if (!ref.mounted) return;
    final result = await ref.read(dashboardRepositoryProvider).fetchDashboard();
    if (!ref.mounted) return;
    switch (result) {
      case Ok(:final value):
        await ref
            .read(appDatabaseProvider)
            .dashboardDao
            .save(value, fetchedAt: DateTime.now().toUtc());
        if (ref.mounted) state = const Synced();
      case Err(:final failure):
        // The cache is untouched: offline, the screen keeps what it had.
        state = SyncFailed(failure);
    }
  }
}
