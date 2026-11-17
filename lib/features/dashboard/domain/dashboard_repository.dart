import 'package:matric_compass/core/errors/result.dart';
import 'package:matric_compass/features/dashboard/domain/learner_dashboard.dart';

/// Week 10 Day 2: what the dashboard needs from somewhere. Widgets and
/// notifiers only ever see this interface.
///
/// Week 11 Day 1: it returns a Result, so failure is in the signature.
abstract interface class DashboardRepository {
  /// The signed-in learner's dashboard.
  Future<Result<LearnerDashboard>> fetchDashboard();
}
