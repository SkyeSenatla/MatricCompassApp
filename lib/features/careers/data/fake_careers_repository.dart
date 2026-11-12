import 'package:matric_compass/core/fakes/careers_seed.dart';
import 'package:matric_compass/features/careers/domain/aptitude_test.dart';
import 'package:matric_compass/features/careers/domain/careers_repository.dart';
import 'package:matric_compass/features/careers/domain/tertiary_application.dart';

/// Week 10 Day 4: the Careers data from memory, owner-scoped like the API:
/// a learner only ever gets her own tests and applications.
final class FakeCareersRepository implements CareersRepository {
  /// Creates the fake. [ownerId] is the signed-in learner's student id;
  /// tests pass lists of their own (empty ones for the empty state) and a
  /// zero [latency].
  new({
    required this.ownerId,
    List<AptitudeTest>? aptitudeTests,
    List<TertiaryApplication>? tertiaryApplications,
    this.latency = const Duration(milliseconds: 600),
  }) : _aptitudeTests = aptitudeTests ?? CareersSeed.aptitudeTests,
       _tertiaryApplications =
           tertiaryApplications ?? CareersSeed.tertiaryApplications;

  /// Only this student's records are returned.
  final String ownerId;

  final List<AptitudeTest> _aptitudeTests;
  final List<TertiaryApplication> _tertiaryApplications;

  /// How long each call pretends the network takes.
  final Duration latency;

  @override
  Future<List<AptitudeTest>> fetchAptitudeTests() async {
    await Future<void>.delayed(latency);
    return [
      for (final test in _aptitudeTests)
        if (test.studentId == ownerId) test,
    ]..sort((a, b) => b.dateTaken.compareTo(a.dateTaken));
  }

  @override
  Future<List<TertiaryApplication>> fetchTertiaryApplications() async {
    await Future<void>.delayed(latency);
    return [
      for (final application in _tertiaryApplications)
        if (application.studentId == ownerId) application,
    ];
  }
}
