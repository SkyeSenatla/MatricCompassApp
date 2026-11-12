import 'package:matric_compass/features/careers/data/careers_repository_provider.dart';
import 'package:matric_compass/features/careers/domain/aptitude_test.dart';
import 'package:matric_compass/features/careers/domain/tertiary_application.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'careers_overview_provider.g.dart';

/// Week 10 Day 4: everything the Careers tab shows.
final class CareersOverview {
  /// Creates the overview.
  const new({required this.aptitudeTests, required this.applications});

  /// Her aptitude tests, newest first.
  final List<AptitudeTest> aptitudeTests;

  /// Her university applications.
  final List<TertiaryApplication> applications;

  /// Nothing to show yet: a new learner.
  bool get isEmpty => aptitudeTests.isEmpty && applications.isEmpty;
}

/// Week 10 Day 4: both lists, fetched at the same time. A record of two
/// futures, awaited together with `.wait`: the tab waits for the slower
/// one, not for the two one after the other.
///
/// autoDispose, the codegen default: leave the tab's branch and come back
/// later, and it fetches fresh data.
@riverpod
Future<CareersOverview> careersOverview(Ref ref) async {
  final repository = ref.watch(careersRepositoryProvider);
  final (aptitudeTests, applications) = await (
    repository.fetchAptitudeTests(),
    repository.fetchTertiaryApplications(),
  ).wait;
  return CareersOverview(
    aptitudeTests: aptitudeTests,
    applications: applications,
  );
}
