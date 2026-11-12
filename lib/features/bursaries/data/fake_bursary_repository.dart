import 'package:matric_compass/core/fakes/seed.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_application.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_repository.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_status.dart';

/// Week 10 Day 2: applications from memory. An unknown id is "not found",
/// as the API's 404 is for someone else's application.
final class FakeBursaryRepository implements BursaryRepository {
  /// Creates the fake; tests pass a zero [latency].
  ///
  /// Week 10 Day 3: [ownerId] is the signed-in learner's student id. When it
  /// is set, the fake behaves like the API for a learner: another learner's
  /// application is "not found", exactly like an id that never existed.
  /// Staff pass null and see every application.
  new({
    List<BursaryApplication>? applications,
    this.latency = const Duration(milliseconds: 600),
    this.ownerId,
  }) : _applications = applications ?? Seed.applications;

  final List<BursaryApplication> _applications;

  /// How long each call pretends the network takes.
  final Duration latency;

  /// Only this student's applications are visible, when set.
  final String? ownerId;

  /// How many times [fetchById] ran. Lets a test prove a fetch was shared.
  int fetchCount = 0;

  @override
  Future<BursaryApplication> fetchById(String id) async {
    fetchCount++;
    await Future<void>.delayed(latency);
    for (final application in _applications) {
      if (application.id == id && _visible(application)) return application;
    }
    // The same exception whether it doesn't exist or isn't yours.
    throw BursaryNotFoundException(id);
  }

  @override
  Future<List<BursaryApplication>> fetchForReview() async {
    await Future<void>.delayed(latency);
    return [
      for (final application in _applications)
        if (_visible(application) &&
            (application.status == BursaryStatus.submitted ||
                application.status == BursaryStatus.underReview))
          application,
    ];
  }

  bool _visible(BursaryApplication application) =>
      ownerId == null || application.studentId == ownerId;
}
