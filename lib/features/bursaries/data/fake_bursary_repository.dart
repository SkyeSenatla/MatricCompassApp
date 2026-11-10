import 'package:matric_compass/core/fakes/seed.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_application.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_repository.dart';

/// Week 10 Day 2: applications from memory. An unknown id is "not found",
/// as the API's 404 is for someone else's application.
final class FakeBursaryRepository implements BursaryRepository {
  /// Creates the fake; tests pass a zero [latency].
  new({
    List<BursaryApplication>? applications,
    this.latency = const Duration(milliseconds: 600),
  }) : _applications = applications ?? Seed.applications;

  final List<BursaryApplication> _applications;

  /// How long each call pretends the network takes.
  final Duration latency;

  /// How many times [fetchById] ran. Lets a test prove a fetch was shared.
  int fetchCount = 0;

  @override
  Future<BursaryApplication> fetchById(String id) async {
    fetchCount++;
    await Future<void>.delayed(latency);
    for (final application in _applications) {
      if (application.id == id) return application;
    }
    throw BursaryNotFoundException(id);
  }
}
