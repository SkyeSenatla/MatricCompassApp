import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matric_compass/features/dashboard/domain/learner_dashboard.dart';

/// Week 10 Day 2: the four things the dashboard screen can show.
///
/// Riverpod's AsyncValue has loading, data and error, but no "empty", so
/// the screen gets its own sealed type, decided once, here. A switch over it
/// in the widget must handle all four, or it doesn't compile.
sealed class DashboardView {
  const new();

  /// Turns the controller's state into what the screen shows.
  static DashboardView from(AsyncValue<LearnerDashboard> state) =>
      switch (state) {
        // A retry after a failure: show loading, not the old error.
        AsyncError(isLoading: true) => const DashboardLoading(),
        AsyncError(:final error) => DashboardFailure(error),
        AsyncData(:final value) when value.bursaryApplications.isEmpty =>
          DashboardEmpty(value.fullName),
        // A reload keeps the old data on screen, marked as refreshing.
        AsyncData(:final value, :final isLoading) => DashboardData(
          value,
          refreshing: isLoading,
        ),
        AsyncLoading() => const DashboardLoading(),
      };
}

/// The first load.
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

/// The dashboard, possibly being refreshed.
final class DashboardData extends DashboardView {
  /// Creates the data state.
  const new(this.dashboard, {this.refreshing = false});

  /// What to show.
  final LearnerDashboard dashboard;

  /// True while a reload runs behind the old data.
  final bool refreshing;
}

/// The load failed.
final class DashboardFailure extends DashboardView {
  /// Creates the failure state.
  const new(this.error);

  /// What went wrong. Week 11 turns this into a Failure with a reference.
  final Object error;
}
