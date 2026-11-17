import 'package:matric_compass/core/errors/result.dart';
import 'package:matric_compass/features/dashboard/data/dashboard_repository_provider.dart';
import 'package:matric_compass/features/dashboard/domain/learner_dashboard.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_controller.g.dart';

/// Week 10 Day 2: owns the learner's dashboard.
///
/// autoDispose (the codegen default): when no screen watches it, it's gone,
/// and the next visit fetches fresh data.
@riverpod
class DashboardController extends _$DashboardController {
  // Week 11 Day 1: the repository returns a Result. An Err is thrown here
  // as its Failure, so the screen gets an AsyncError holding a Failure.
  @override
  Future<LearnerDashboard> build() async =>
      (await ref.watch(dashboardRepositoryProvider).fetchDashboard())
          .valueOrThrow;

  /// Fetches again. The old data stays on screen while it loads, and a
  /// failure lands in the state for the screen to show.
  Future<void> reload() async {
    ref.invalidateSelf();
    try {
      await future;
    } on Object {
      // Nothing to do here: the error is already in `state`.
    }
  }
}
