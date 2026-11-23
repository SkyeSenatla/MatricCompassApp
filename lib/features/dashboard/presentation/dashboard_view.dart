import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matric_compass/core/cache/snapshot.dart';
import 'package:matric_compass/core/cache/sync_state.dart';
import 'package:matric_compass/core/errors/failure.dart';
import 'package:matric_compass/features/dashboard/domain/learner_dashboard.dart';

/// Week 10 Day 2: the four things the dashboard screen can show.
///
/// Riverpod's AsyncValue has loading, data and error, but no "empty", so
/// the screen gets its own sealed type, decided once, here. A switch over it
/// in the widget must handle all four, or it doesn't compile.
///
/// Week 11 Day 3: decided from two things: what the phone has cached, and
/// how the last fetch went. Anything cached wins: a failed fetch only puts
/// a banner above it.
sealed class DashboardView {
  const new();

  /// Turns the cache and the sync state into what the screen shows.
  static DashboardView from(
    AsyncValue<Snapshot<LearnerDashboard>?> cache,
    SyncState sync,
  ) => switch ((cache, sync)) {
    // The database failed: nothing to show, so say so.
    (AsyncError(:final error), _) => DashboardFailure(error),
    // Nothing on this phone yet, and the first fetch failed.
    (AsyncData(value: null), SyncFailed(:final failure)) => DashboardFailure(
      failure,
    ),
    // Nothing on this phone yet: the first launch, or the stream hasn't
    // answered.
    (AsyncData(value: null), _) ||
    (AsyncLoading(), _) => const DashboardLoading(),
    (AsyncData(value: final snapshot?), _)
        when snapshot.value.bursaryApplications.isEmpty =>
      DashboardEmpty(snapshot.value.fullName),
    (AsyncData(value: final snapshot?), _) => DashboardData(
      snapshot.value,
      fetchedAt: snapshot.fetchedAt,
      refreshing: sync is Syncing,
      staleBecause: switch (sync) {
        SyncFailed(:final failure) => failure,
        Syncing() || Synced() => null,
      },
    ),
  };
}

/// The first load, with nothing cached.
final class DashboardLoading extends DashboardView {
  /// Creates the loading state.
  const new();
}

/// A learner with no bursary applications yet.
final class DashboardEmpty extends DashboardView {
  /// Creates the empty state.
  const new(this.fullName);

  /// Used for the greeting.
  final String fullName;
}

/// The dashboard, from the cache, possibly being refreshed.
final class DashboardData extends DashboardView {
  /// Creates the data state.
  const new(
    this.dashboard, {
    required this.fetchedAt,
    this.refreshing = false,
    this.staleBecause,
  });

  /// What to show.
  final LearnerDashboard dashboard;

  /// When the server sent it. Always shown when the last fetch failed.
  final DateTime fetchedAt;

  /// True while a fetch runs behind the cached data.
  final bool refreshing;

  /// Why the last fetch failed, if it did: the banner's reason.
  final Failure? staleBecause;
}

/// Nothing to show: nothing cached, and the fetch failed.
final class DashboardFailure extends DashboardView {
  /// Creates the failure state.
  const new(this.error);

  /// What went wrong: a Failure, usually.
  final Object error;
}
