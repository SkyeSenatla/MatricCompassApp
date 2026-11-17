import 'package:matric_compass/core/errors/failure.dart';
import 'package:matric_compass/core/errors/result.dart';
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
  }) : _applications = List.of(applications ?? Seed.applications);

  final List<BursaryApplication> _applications;

  /// How long each call pretends the network takes.
  final Duration latency;

  /// Only this student's applications are visible, when set.
  final String? ownerId;

  /// How many times [fetchById] ran. Lets a test prove a fetch was shared.
  int fetchCount = 0;

  @override
  Future<Result<BursaryApplication>> fetchById(String id) async {
    fetchCount++;
    await Future<void>.delayed(latency);
    // The same Failure whether it doesn't exist or isn't yours.
    return switch (_find(id)) {
      final application? => Ok(application),
      null => const Err(NotFoundFailure()),
    };
  }

  @override
  Future<Result<List<BursaryApplication>>> fetchForReview() async {
    await Future<void>.delayed(latency);
    return Ok([
      for (final application in _applications)
        if (_visible(application) && application.status.isWaitingForReview)
          application,
    ]);
  }

  /// Week 11 Day 1: plays the API's rules that a fake can know. It has no
  /// documents, so it never answers 422; the API test covers that.
  @override
  Future<Result<BursaryApplication>> submit(String id) async {
    await Future<void>.delayed(latency);
    final application = _find(id);
    if (application == null) return const Err(NotFoundFailure());
    if (application.status != BursaryStatus.draft) {
      return const Err(
        ConflictFailure(detail: 'This application is already submitted.'),
      );
    }
    final submitted = application.copyWith(
      status: BursaryStatus.submitted,
      submittedAt: DateTime.now().toUtc(),
      version: application.version + 1,
    );
    _applications[_applications.indexOf(application)] = submitted;
    return Ok(submitted);
  }

  BursaryApplication? _find(String id) {
    for (final application in _applications) {
      if (application.id == id && _visible(application)) return application;
    }
    return null;
  }

  bool _visible(BursaryApplication application) =>
      ownerId == null || application.studentId == ownerId;
}
