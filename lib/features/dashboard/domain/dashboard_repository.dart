import 'package:matric_compass/features/dashboard/domain/learner_dashboard.dart';

/// Week 10 Day 2: what the dashboard needs from somewhere. A fake this week,
/// the API from Week 11. Widgets and notifiers only ever see this interface.
abstract interface class DashboardRepository {
  /// The signed-in learner's dashboard.
  Future<LearnerDashboard> fetchDashboard();
}
