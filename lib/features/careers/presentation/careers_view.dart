import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matric_compass/features/careers/presentation/careers_overview_provider.dart';

/// Week 10 Day 4: the four things the Careers tab can show, decided once.
/// The same shape as Day 2's DashboardView: AsyncValue has no "empty".
sealed class CareersView {
  const new();

  /// Turns the provider's state into what the screen shows.
  static CareersView from(AsyncValue<CareersOverview> state) => switch (state) {
    // A retry after a failure: show loading, not the old error.
    AsyncError(isLoading: true) => const CareersLoading(),
    AsyncError() => const CareersFailure(),
    AsyncData(:final value) when value.isEmpty => const CareersEmpty(),
    AsyncData(:final value) => CareersData(value),
    AsyncLoading() => const CareersLoading(),
  };
}

/// The first load.
final class CareersLoading extends CareersView {
  /// Creates the loading state.
  const new();
}

/// No tests and no applications yet.
final class CareersEmpty extends CareersView {
  /// Creates the empty state.
  const new();
}

/// Something to show.
final class CareersData extends CareersView {
  /// Creates the data state.
  const new(this.overview);

  /// What to show.
  final CareersOverview overview;
}

/// The load failed.
final class CareersFailure extends CareersView {
  /// Creates the failure state.
  const new();
}
