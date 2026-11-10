import 'package:matric_compass/core/fakes/seed.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_application.dart';
import 'package:matric_compass/features/dashboard/domain/dashboard_repository.dart';
import 'package:matric_compass/features/dashboard/domain/learner_dashboard.dart';

/// Week 10 Day 2: the dashboard from memory, after a pretend network delay.
final class FakeDashboardRepository implements DashboardRepository {
  /// Creates the fake. Tests pass [applications] (an empty list for the
  /// empty state) and [latency] (zero, so nothing waits on a timer).
  new({
    List<BursaryApplication>? applications,
    this.latency = const Duration(milliseconds: 800),
    DateTime Function()? clock,
  }) : _applications = applications ?? Seed.applications,
       _clock = clock ?? DateTime.now;

  final List<BursaryApplication> _applications;
  final DateTime Function() _clock;

  /// How long each call pretends the network takes.
  final Duration latency;

  @override
  Future<LearnerDashboard> fetchDashboard() async {
    await Future<void>.delayed(latency);
    final today = _clock().toUtc();
    return LearnerDashboard(
      fullName: Seed.thandiweName,
      bursaryApplications: [
        for (final application in _applications)
          BursarySummary(
            id: application.id,
            funder: application.funder,
            status: application.status,
            deadline: application.deadline,
            // The fake plays the server here, so it may compute this.
            daysUntilDeadline: application.deadline.difference(today).inDays,
            amount: application.amount,
          ),
      ],
    );
  }
}
